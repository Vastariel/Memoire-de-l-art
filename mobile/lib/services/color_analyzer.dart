import 'dart:math' as math;
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ── Perceptual colour delta (CIEDE2000 approximation via LAB) ───────────────
// For live-feed feedback, RGB Euclidean is fast enough.
// For the final capture verdict, we use a weighted RGB distance.

double colorDelta(Color a, Color b) {
  final dr = (a.red   - b.red)   / 255.0;
  final dg = (a.green - b.green) / 255.0;
  final db = (a.blue  - b.blue)  / 255.0;
  // Weighted to match human perception (luminance-weighted)
  return math.sqrt(0.30 * dr * dr + 0.59 * dg * dg + 0.11 * db * db) * 100;
}

// 0–100 scale — stricter thresholds to push users toward the real colour.
// perfect < 10 : very close match, photo replaces the zone directly
// correct < 22 : acceptable match, photo is slightly blended
// weak   ≥ 22 : too far, verdict "on réessaie ?"
enum ColorVerdict { perfect, correct, weak }

ColorVerdict verdictFromDelta(double delta) {
  if (delta < 10) return ColorVerdict.perfect;
  if (delta < 22) return ColorVerdict.correct;
  return ColorVerdict.weak;
}

String verdictLabel(ColorVerdict v, Color detected, Color target) {
  switch (v) {
    case ColorVerdict.perfect:
      return 'Parfait !';
    case ColorVerdict.correct:
      // Give a directional hint based on hue/brightness
      final dBright = detected.computeLuminance() - target.computeLuminance();
      if (dBright >  0.15) return 'Encore un peu plus sombre';
      if (dBright < -0.15) return 'Encore un peu plus clair';
      // Hue hint
      final dR = detected.red - target.red;
      final dB = detected.blue - target.blue;
      if (dR > 40)  return 'Trop chaud';
      if (dR < -40) return 'Manque de rouge';
      if (dB > 40)  return 'Trop froid';
      return 'Presque !';
    case ColorVerdict.weak:
      return 'On réessaie ?';
  }
}

String verdictHint(ColorVerdict v, Color detected, Color target) {
  switch (v) {
    case ColorVerdict.perfect:
      return 'La teinte correspond bien à la zone.';
    case ColorVerdict.correct:
      return 'La photo sera légèrement fondue avec la couleur cible.';
    case ColorVerdict.weak:
      return 'Cherche un objet ou une surface plus proche de la couleur.';
  }
}

// ── Camera frame → dominant colour ──────────────────────────────────────────

// Entry point for background isolate — receives raw YUV bytes + dimensions.
Color _computeDominantFromYuv(_YuvPayload p) {
  final yBytes  = p.yBytes;
  final uBytes  = p.uBytes;
  final vBytes  = p.vBytes;
  final width   = p.width;
  final height  = p.height;
  final yStride = p.yStride;
  final uvStride = p.uvStride;
  final uvPixelStride = p.uvPixelStride;

  int rSum = 0, gSum = 0, bSum = 0, count = 0;
  // Sample a 20×20 grid across the frame for speed
  const gridSize = 20;
  final stepX = (width  / gridSize).round().clamp(1, width);
  final stepY = (height / gridSize).round().clamp(1, height);

  for (int row = 0; row < height; row += stepY) {
    for (int col = 0; col < width; col += stepX) {
      final yIdx  = row * yStride + col;
      final uvRow = row ~/ 2;
      final uvCol = col ~/ 2;
      final uvIdx = uvRow * uvStride + uvCol * uvPixelStride;

      if (yIdx >= yBytes.length || uvIdx >= uBytes.length || uvIdx >= vBytes.length) {
        continue;
      }

      final y = yBytes[yIdx].toDouble();
      final u = (uBytes[uvIdx] - 128).toDouble();
      final v = (vBytes[uvIdx] - 128).toDouble();

      final r = (y + 1.402  * v).clamp(0, 255).toInt();
      final g = (y - 0.344  * u - 0.714 * v).clamp(0, 255).toInt();
      final b = (y + 1.772  * u).clamp(0, 255).toInt();

      rSum += r; gSum += g; bSum += b; count++;
    }
  }

  if (count == 0) return Colors.grey;
  return Color.fromARGB(255, rSum ~/ count, gSum ~/ count, bSum ~/ count);
}

Color _computeDominantFromBgra(_BgraPayload p) {
  final bytes  = p.bytes;
  final width  = p.width;
  final height = p.height;
  final stride = p.stride;

  int rSum = 0, gSum = 0, bSum = 0, count = 0;
  const gridSize = 20;
  final stepX = (width  / gridSize).round().clamp(1, width);
  final stepY = (height / gridSize).round().clamp(1, height);

  for (int row = 0; row < height; row += stepY) {
    for (int col = 0; col < width; col += stepX) {
      final i = row * stride + col * 4;
      if (i + 3 >= bytes.length) continue;
      bSum += bytes[i];
      gSum += bytes[i + 1];
      rSum += bytes[i + 2];
      count++;
    }
  }

  if (count == 0) return Colors.grey;
  return Color.fromARGB(255, rSum ~/ count, gSum ~/ count, bSum ~/ count);
}

Future<Color> dominantColorFromFrame(CameraImage image) async {
  if (image.format.group == ImageFormatGroup.yuv420) {
    final p = _YuvPayload(
      yBytes:       image.planes[0].bytes,
      uBytes:       image.planes[1].bytes,
      vBytes:       image.planes[2].bytes,
      width:        image.width,
      height:       image.height,
      yStride:      image.planes[0].bytesPerRow,
      uvStride:     image.planes[1].bytesPerRow,
      uvPixelStride: image.planes[1].bytesPerPixel ?? 1,
    );
    return compute(_computeDominantFromYuv, p);
  } else if (image.format.group == ImageFormatGroup.bgra8888) {
    final p = _BgraPayload(
      bytes:  image.planes[0].bytes,
      width:  image.width,
      height: image.height,
      stride: image.planes[0].bytesPerRow,
    );
    return compute(_computeDominantFromBgra, p);
  }
  // Fallback: return grey
  return Colors.grey;
}

// ── Data transfer objects for compute() ─────────────────────────────────────

class _YuvPayload {
  final Uint8List yBytes, uBytes, vBytes;
  final int width, height, yStride, uvStride, uvPixelStride;
  const _YuvPayload({
    required this.yBytes, required this.uBytes, required this.vBytes,
    required this.width,  required this.height,
    required this.yStride, required this.uvStride, required this.uvPixelStride,
  });
}

class _BgraPayload {
  final Uint8List bytes;
  final int width, height, stride;
  const _BgraPayload({required this.bytes, required this.width,
                      required this.height, required this.stride});
}
