// mosaic.dart — rendu de l'œuvre v2 (port du composant Mosaic de mosaic.jsx).
// Vue plate (pigments) ↔ vitrail (photos brutes recadrées), pulse du jour,
// reveal en cascade. CustomPainter pour tenir 192 cellules sans peiner.
// L'œuvre rendue est [artwork] (par défaut le moteur local kArtwork) — ce qui
// permet d'afficher une œuvre créée dans l'admin et servie par l'API.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../engine/mosaic_engine.dart';
import '../theme/palette.dart';

class MosaicWidget extends StatefulWidget {
  final Set<String> filled; // familles contribuées
  final String? todayFamily;
  final double vitrail; // 0 = plat, 1 = vitrail
  final bool revealAll;
  final double gap;
  final double radius;
  final bool pulse;
  final bool stagger;
  final ArtworkData? artwork; // null → moteur local (Semeur)
  final void Function(ArtCell cell, bool filled)? onTapCell;

  const MosaicWidget({
    super.key,
    required this.filled,
    this.todayFamily,
    this.vitrail = 0,
    this.revealAll = false,
    this.gap = 1.5,
    this.radius = 2,
    this.pulse = true,
    this.stagger = false,
    this.artwork,
    this.onTapCell,
  });

  @override
  State<MosaicWidget> createState() => _MosaicWidgetState();
}

class _MosaicWidgetState extends State<MosaicWidget> with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _stagger;

  ArtworkData get _art => widget.artwork ?? kArtwork;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900))..repeat(reverse: true);
    _stagger = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    if (widget.stagger) {
      _stagger.forward();
    } else {
      _stagger.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant MosaicWidget old) {
    super.didUpdateWidget(old);
    if (widget.stagger && !old.stagger) {
      _stagger
        ..reset()
        ..forward();
    } else if (!widget.stagger && old.stagger) {
      _stagger.value = 1;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _stagger.dispose();
    super.dispose();
  }

  void _handleTap(Offset local, Size size) {
    if (widget.onTapCell == null) return;
    final art = _art;
    final col = (local.dx / size.width * art.cols).floor().clamp(0, art.cols - 1);
    final row = (local.dy / size.height * art.rows).floor().clamp(0, art.rows - 1);
    final cell = art.cells[row * art.cols + col];
    final isFilled = widget.revealAll || widget.filled.contains(cell.family);
    widget.onTapCell!(cell, isFilled);
  }

  @override
  Widget build(BuildContext context) {
    final art = _art;
    return AspectRatio(
      aspectRatio: art.cols / art.rows,
      child: LayoutBuilder(builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        Widget out = AnimatedBuilder(
          animation: Listenable.merge([_pulse, _stagger]),
          builder: (_, __) => CustomPaint(
            size: size,
            painter: _MosaicPainter(
              art: art,
              filled: widget.filled,
              todayFamily: widget.todayFamily,
              vitrail: widget.vitrail,
              revealAll: widget.revealAll,
              gap: widget.gap,
              radius: widget.radius,
              pulse: widget.pulse,
              pulseT: _pulse.value,
              staggerT: widget.stagger ? _stagger.value : 1,
              emptyColor: context.mosaicEmpty,
              lineColor: context.line,
            ),
          ),
        );
        if (widget.onTapCell != null) {
          out = GestureDetector(onTapUp: (d) => _handleTap(d.localPosition, size), child: out);
        }
        return out;
      }),
    );
  }
}

double _easeOut(double t) => 1 - math.pow(1 - t, 3).toDouble();

class _MosaicPainter extends CustomPainter {
  final ArtworkData art;
  final Set<String> filled;
  final String? todayFamily;
  final double vitrail;
  final bool revealAll;
  final double gap;
  final double radius;
  final bool pulse;
  final double pulseT;
  final double staggerT;
  final Color emptyColor;
  final Color lineColor;

  _MosaicPainter({
    required this.art,
    required this.filled,
    required this.todayFamily,
    required this.vitrail,
    required this.revealAll,
    required this.gap,
    required this.radius,
    required this.pulse,
    required this.pulseT,
    required this.staggerT,
    required this.emptyColor,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = (size.width - gap * (art.cols - 1)) / art.cols;
    final cellH = (size.height - gap * (art.rows - 1)) / art.rows;
    final total = art.cells.length;

    Rect cellRect(ArtCell c) => Rect.fromLTWH(c.col * (cellW + gap), c.row * (cellH + gap), cellW, cellH);

    final emptyPaint = Paint()..color = emptyColor;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = lineColor;

    // ── couche plate + vides + jour ──
    for (final c in art.cells) {
      final r = cellRect(c);
      final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
      final isFilled = revealAll || filled.contains(c.family);
      final isToday = !isFilled && c.family == todayFamily;

      canvas.drawRRect(rr, emptyPaint);
      canvas.drawRRect(rr, borderPaint);

      if (isFilled) {
        var cellT = 1.0;
        if (staggerT < 1) {
          final start = (c.i / total) * 0.55;
          cellT = _easeOut(((staggerT - start) / 0.45).clamp(0, 1));
        }
        if (cellT <= 0) continue;
        final fr = Rect.fromCenter(center: r.center, width: r.width * cellT, height: r.height * cellT);
        final frr = RRect.fromRectAndRadius(fr, Radius.circular(radius * cellT));
        final paint = Paint()..shader = fillGradient(c.pig, c.i).createShader(fr);
        canvas.drawRRect(frr, paint);
      } else if (isToday) {
        final a = pulse ? (0.55 + 0.45 * pulseT) : 1.0;
        canvas.drawRRect(rr, Paint()..color = c.pig.withValues(alpha: 0.18 * a));
        canvas.drawRRect(
          rr,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.25
            ..color = c.pig.withValues(alpha: a),
        );
      }
    }

    // ── couche vitrail (photos) ──
    if (vitrail > 0.01) {
      final full = Offset.zero & size;
      canvas.saveLayer(full, Paint()..color = Colors.white.withValues(alpha: vitrail.clamp(0, 1)));
      final shaders = <String, List<Shader>>{};
      for (final c in art.cells) {
        final isFilled = revealAll || filled.contains(c.family);
        if (!isFilled) continue;
        final layers = shaders.putIfAbsent(
          c.family,
          () => photoLayers(c.family).map((g) => g.createShader(full)).toList(),
        );
        final r = cellRect(c);
        final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
        for (final sh in layers) {
          canvas.drawRRect(rr, Paint()..shader = sh);
        }
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_MosaicPainter old) =>
      !identical(old.art, art) ||
      old.vitrail != vitrail ||
      old.pulseT != pulseT ||
      old.staggerT != staggerT ||
      old.todayFamily != todayFamily ||
      !_setEq(old.filled, filled) ||
      old.revealAll != revealAll;
}

bool _setEq(Set<String> a, Set<String> b) {
  if (a.length != b.length) return false;
  for (final e in a) {
    if (!b.contains(e)) return false;
  }
  return true;
}
