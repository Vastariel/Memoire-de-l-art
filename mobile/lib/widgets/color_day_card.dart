import 'package:flutter/material.dart';
import '../models/zone.dart';
import '../theme/theme.dart';
import '../theme/typography.dart';

// ── ColorDayCard ──────────────────────────────────────────────────────────────
// Immersive full-width card showing today's zone colour with a painterly wash.

class ColorDayCard extends StatelessWidget {
  final ZoneColor zoneColor;

  const ColorDayCard({super.key, required this.zoneColor});

  @override
  Widget build(BuildContext context) {
    final base       = zoneColor.color;
    final luminance  = base.computeLuminance();
    final onColor    = luminance > 0.45 ? const Color(0xCC1C1813) : const Color(0xCCFFFEFB);
    final onColorSub = luminance > 0.45 ? const Color(0x991C1813) : const Color(0x99FFFEFB);

    return Container(
      width: double.infinity,
      height: 156,
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      decoration: BoxDecoration(
        borderRadius: MdaRadius.bLg,
        boxShadow: MdaShadows.md,
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Base colour
          ColoredBox(color: base),

          // Painterly wash — soft overlapping blobs
          CustomPaint(painter: _WashPainter(base)),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'COULEUR DU JOUR',
                  style: TextStyle(
                    fontFamily: MdaFonts.sans,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                    color: onColorSub,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  zoneColor.label,
                  style: _spectralItalic(color: onColor, size: 30),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static TextStyle _spectralItalic({required Color color, required double size}) =>
      MdaType.serifItalic(color: color).copyWith(fontSize: size, height: 1.15);
}

// ── Wash painter ──────────────────────────────────────────────────────────────
// Draws soft colour blobs that create a painterly wash effect.

class _WashPainter extends CustomPainter {
  final Color base;
  _WashPainter(this.base);

  @override
  void paint(Canvas canvas, Size size) {
    final hsl = HSLColor.fromColor(base);

    // Define blob positions as fractions of size (deterministic)
    final blobs = [
      _Blob(0.15, 0.25, 0.55, 0.12,  0.18),  // top-left, lighter
      _Blob(0.78, 0.18, 0.62, -0.08, 0.14),  // top-right, darker
      _Blob(0.50, 0.60, 0.48, 0.10,  0.20),  // centre, lighter
      _Blob(0.20, 0.80, 0.42, -0.06, 0.16),  // bottom-left, darker
      _Blob(0.85, 0.75, 0.58, 0.08,  0.12),  // bottom-right, lighter
      _Blob(0.40, 0.15, 0.52, 0.14,  0.22),  // top-centre, lighter
    ];

    for (final b in blobs) {
      final blobColor = hsl
          .withLightness((hsl.lightness + b.lightnessDelta).clamp(0.0, 1.0))
          .withSaturation((hsl.saturation * 0.9).clamp(0.0, 1.0))
          .toColor()
          .withAlpha((b.alpha * 255).round());

      final paint = Paint()
        ..color    = blobColor
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * b.blurFraction);

      canvas.drawCircle(
        Offset(size.width * b.cx, size.height * b.cy),
        size.width * b.radiusFraction,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WashPainter old) => old.base != base;
}

class _Blob {
  final double cx, cy, alpha, lightnessDelta, radiusFraction;
  double get blurFraction => radiusFraction * 0.7;
  const _Blob(this.cx, this.cy, this.alpha, this.lightnessDelta, this.radiusFraction);
}

