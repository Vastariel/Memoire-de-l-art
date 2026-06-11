import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ── Perceptual colour delta (luminance-weighted RGB) ────────────────────────
// Fast enough for live-feed feedback and the capture verdict.

double colorDelta(Color a, Color b) {
  final dr = a.r - b.r; // .r/.g/.b are 0..1 doubles (Flutter 3.27+)
  final dg = a.g - b.g;
  final db = a.b - b.b;
  return math.sqrt(0.30 * dr * dr + 0.59 * dg * dg + 0.11 * db * db) * 100;
}

// 0–100 scale.
// perfect < 10 : very close, photo replaces the zone directly
// correct < 22 : acceptable, photo is slightly blended
// weak   ≥ 22 : far — gentle feedback, never refused (matching laxiste)
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
      final dBright = detected.computeLuminance() - target.computeLuminance();
      if (dBright > 0.15) return 'Encore un peu plus sombre';
      if (dBright < -0.15) return 'Encore un peu plus clair';
      final dR = (detected.r - target.r) * 255;
      final dB = (detected.b - target.b) * 255;
      if (dR > 40) return 'Trop chaud';
      if (dR < -40) return 'Manque de rouge';
      if (dB > 40) return 'Trop froid';
      return 'Presque !';
    case ColorVerdict.weak:
      return 'Trop sage ? Cherche une scène';
  }
}

String verdictHint(ColorVerdict v, Color detected, Color target) {
  switch (v) {
    case ColorVerdict.perfect:
      return 'La teinte correspond bien à la couleur du jour.';
    case ColorVerdict.correct:
      return 'La photo se fondra légèrement dans la couleur cible.';
    case ColorVerdict.weak:
      return 'Aucun refus : tente une scène plus riche pour un meilleur bonus.';
  }
}

// ── Camera frame → dominant colour ──────────────────────────────────────────

Color _computeDominantFromYuv(_YuvPayload p) {
  final yBytes = p.yBytes, uBytes = p.uBytes, vBytes = p.vBytes;
  final width = p.width, height = p.height;
  final yStride = p.yStride, uvStride = p.uvStride, uvPixelStride = p.uvPixelStride;

  int rSum = 0, gSum = 0, bSum = 0, count = 0;
  const gridSize = 20;
  final stepX = (width / gridSize).round().clamp(1, width);
  final stepY = (height / gridSize).round().clamp(1, height);

  for (int row = 0; row < height; row += stepY) {
    for (int col = 0; col < width; col += stepX) {
      final yIdx = row * yStride + col;
      final uvIdx = (row ~/ 2) * uvStride + (col ~/ 2) * uvPixelStride;
      if (yIdx >= yBytes.length || uvIdx >= uBytes.length || uvIdx >= vBytes.length) continue;

      final y = yBytes[yIdx].toDouble();
      final u = (uBytes[uvIdx] - 128).toDouble();
      final v = (vBytes[uvIdx] - 128).toDouble();
      final r = (y + 1.402 * v).clamp(0, 255).toInt();
      final g = (y - 0.344 * u - 0.714 * v).clamp(0, 255).toInt();
      final b = (y + 1.772 * u).clamp(0, 255).toInt();
      rSum += r; gSum += g; bSum += b; count++;
    }
  }
  if (count == 0) return Colors.grey;
  return Color.fromARGB(255, rSum ~/ count, gSum ~/ count, bSum ~/ count);
}

Color _computeDominantFromBgra(_BgraPayload p) {
  final bytes = p.bytes;
  final width = p.width, height = p.height, stride = p.stride;
  int rSum = 0, gSum = 0, bSum = 0, count = 0;
  const gridSize = 20;
  final stepX = (width / gridSize).round().clamp(1, width);
  final stepY = (height / gridSize).round().clamp(1, height);

  for (int row = 0; row < height; row += stepY) {
    for (int col = 0; col < width; col += stepX) {
      final i = row * stride + col * 4;
      if (i + 3 >= bytes.length) continue;
      bSum += bytes[i]; gSum += bytes[i + 1]; rSum += bytes[i + 2]; count++;
    }
  }
  if (count == 0) return Colors.grey;
  return Color.fromARGB(255, rSum ~/ count, gSum ~/ count, bSum ~/ count);
}

Future<Color> dominantColorFromFrame(CameraImage image) async {
  if (image.format.group == ImageFormatGroup.yuv420) {
    return compute(_computeDominantFromYuv, _YuvPayload(
      yBytes: image.planes[0].bytes,
      uBytes: image.planes[1].bytes,
      vBytes: image.planes[2].bytes,
      width: image.width,
      height: image.height,
      yStride: image.planes[0].bytesPerRow,
      uvStride: image.planes[1].bytesPerRow,
      uvPixelStride: image.planes[1].bytesPerPixel ?? 1,
    ));
  } else if (image.format.group == ImageFormatGroup.bgra8888) {
    return compute(_computeDominantFromBgra, _BgraPayload(
      bytes: image.planes[0].bytes,
      width: image.width,
      height: image.height,
      stride: image.planes[0].bytesPerRow,
    ));
  }
  return Colors.grey;
}

class _YuvPayload {
  final Uint8List yBytes, uBytes, vBytes;
  final int width, height, yStride, uvStride, uvPixelStride;
  const _YuvPayload({
    required this.yBytes, required this.uBytes, required this.vBytes,
    required this.width, required this.height,
    required this.yStride, required this.uvStride, required this.uvPixelStride,
  });
}

class _BgraPayload {
  final Uint8List bytes;
  final int width, height, stride;
  const _BgraPayload({required this.bytes, required this.width, required this.height, required this.stride});
}
