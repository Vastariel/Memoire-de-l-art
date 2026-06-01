import 'dart:io';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/artwork.dart';
import '../models/zone.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';

// Deterministic per-cell jitter — matches the JS hash() in mosaic.jsx.
double _hash(int i) {
  final x = math.sin(i * 127.1) * 43758.5453;
  return x - x.floor();
}

// Build a filled-cell gradient that mimics a photo texture.
LinearGradient _fillGradient(Color base, int cellIndex) {
  final j = (_hash(cellIndex) - 0.5) * 0.22;
  final hi  = base.lighten(j.abs() + 0.16);
  final lo  = base.darken(0.14 - j.clamp(-0.14, 0.0));
  final angle = (135 + (_hash(cellIndex + 9) * 90).round()) * math.pi / 180;
  return LinearGradient(
    begin: Alignment(math.cos(angle), math.sin(angle)),
    end:   Alignment(-math.cos(angle), -math.sin(angle)),
    colors: [hi, base, lo],
    stops: const [0, 0.55, 1],
  );
}

class MosaicWidget extends StatefulWidget {
  final Artwork artwork;
  final String? revealZoneId;   // triggers staggered cell-reveal animation
  final bool revealAll;         // end-of-month: reveal with full stagger
  final bool showPulse;             // pulse today's zone
  final double photoRevealFactor;   // 0.0 = gradient only, 1.0 = full photos
  final double gap;
  final double radius;
  final void Function(Zone zone)? onTapZone;

  const MosaicWidget({
    super.key,
    required this.artwork,
    this.revealZoneId,
    this.revealAll = false,
    this.showPulse = true,
    this.photoRevealFactor = 0.0,
    this.gap = 3,
    this.radius = 4,
    this.onTapZone,
  });

  @override
  State<MosaicWidget> createState() => _MosaicWidgetState();
}

class _MosaicWidgetState extends State<MosaicWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  // track which cells have been "played in" for stagger
  late Set<int> _played;

  @override
  void initState() {
    super.initState();
    _played = {};
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    if (widget.revealZoneId != null || widget.revealAll) {
      _scheduleReveal();
    }
  }

  @override
  void didUpdateWidget(covariant MosaicWidget old) {
    super.didUpdateWidget(old);
    if (widget.revealZoneId != old.revealZoneId ||
        widget.revealAll != old.revealAll) {
      _played.clear();
      _scheduleReveal();
    }
  }

  void _scheduleReveal() {
    // tiny delay so the widget has been laid out before animating
    Future.delayed(const Duration(milliseconds: 60), () {
      if (mounted) setState(() => _played = _indexesToReveal());
    });
  }

  Set<int> _indexesToReveal() {
    if (widget.revealAll) {
      return widget.artwork.cells.map((c) => c.index).toSet();
    }
    if (widget.revealZoneId != null) {
      return widget.artwork.cells
          .where((c) => c.zoneId == widget.revealZoneId)
          .map((c) => c.index)
          .toSet();
    }
    return {};
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emptyColor = isDark ? MdaDark.mosaicEmpty : MdaLight.mosaicEmpty;

    final a = widget.artwork;
    return AspectRatio(
      aspectRatio: a.cols / a.rows,
      child: LayoutBuilder(builder: (_, constraints) {
        final cellW = (constraints.maxWidth - widget.gap * (a.cols - 1)) / a.cols;
        return Wrap(
          spacing: widget.gap,
          runSpacing: widget.gap,
          children: a.cells.map((cell) {
            final zone = a.zoneForCell(cell);
            return _MosaicCell(
              key: ValueKey(cell.index),
              cell: cell,
              zone: zone,
              size: cellW,
              radius: widget.radius,
              emptyColor: emptyColor,
              played: _played.contains(cell.index),
              staggerDelay: _staggerDelay(cell, a),
              pulseAnim: _pulseCtrl,
              showPulse: widget.showPulse,
              photoRevealFactor: widget.photoRevealFactor,
              onTap: widget.onTapZone != null && zone != null
                  ? () => widget.onTapZone!(zone)
                  : null,
            );
          }).toList(),
        );
      }),
    );
  }

  Duration _staggerDelay(MosaicCell cell, Artwork a) {
    if (widget.revealAll) {
      return Duration(milliseconds: (cell.index * 14).clamp(0, 1200));
    }
    if (widget.revealZoneId != null && cell.zoneId == widget.revealZoneId) {
      // count position within zone
      int zoneIdx = 0;
      for (final c in a.cells) {
        if (c.zoneId == widget.revealZoneId) {
          if (c.index == cell.index) break;
          zoneIdx++;
        }
      }
      return Duration(milliseconds: (zoneIdx * 45).clamp(0, 1500));
    }
    return Duration.zero;
  }
}

class _MosaicCell extends StatefulWidget {
  final MosaicCell cell;
  final Zone? zone;
  final double size;
  final double radius;
  final Color emptyColor;
  final bool played;
  final Duration staggerDelay;
  final AnimationController pulseAnim;
  final bool showPulse;
  final double photoRevealFactor;
  final VoidCallback? onTap;

  const _MosaicCell({
    super.key,
    required this.cell,
    required this.zone,
    required this.size,
    required this.radius,
    required this.emptyColor,
    required this.played,
    required this.staggerDelay,
    required this.pulseAnim,
    required this.showPulse,
    required this.photoRevealFactor,
    this.onTap,
  });

  @override
  State<_MosaicCell> createState() => _MosaicCellState();
}

class _MosaicCellState extends State<_MosaicCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _revealCtrl;

  @override
  void initState() {
    super.initState();
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    if (widget.played) {
      // Triggered reveal — animate in with stagger
      Future.delayed(widget.staggerDelay, () {
        if (mounted) _revealCtrl.forward();
      });
    } else {
      // Already filled and not being animated — show immediately at full opacity
      _revealCtrl.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _MosaicCell old) {
    super.didUpdateWidget(old);
    if (widget.played && !old.played) {
      _revealCtrl.reset();
      Future.delayed(widget.staggerDelay, () {
        if (mounted) _revealCtrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _revealCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zone = widget.zone;
    final isFilled = zone?.isFilled ?? false;
    final isToday  = zone?.isToday ?? false;
    final pigColor = zone?.pigment.color ?? widget.emptyColor;

    Widget child;

    if (isFilled) {
      final photoUrl = zone?.contribution?.photoUrl;
      final hasPhoto = photoUrl != null && photoUrl.isNotEmpty
          && widget.photoRevealFactor > 0;

      child = AnimatedBuilder(
        animation: _revealCtrl,
        builder: (_, __) {
          final t = CurvedAnimation(parent: _revealCtrl, curve: MdaCurve.easeOut).value;
          final gradientCell = Container(
            width: widget.size, height: widget.size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              gradient: _fillGradient(pigColor, widget.cell.index),
              boxShadow: const [
                BoxShadow(color: Color(0x19000000), blurRadius: 0, spreadRadius: 0.5),
              ],
            ),
          );

          // Gradient fades out as photos reveal (stays visible as fallback behind photo)
          final gradientOpacity = t * (1.0 - widget.photoRevealFactor * 0.6);
          Widget base = Opacity(
            opacity: gradientOpacity,
            child: Transform.scale(scale: 0.55 + 0.45 * t, child: gradientCell),
          );

          if (!hasPhoto) return base;

          // Photo fades in continuously as zoom increases (driven by parent setState)
          return Stack(
            children: [
              base,
              Opacity(
                opacity: widget.photoRevealFactor.clamp(0.0, 1.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.radius),
                  child: _PhotoImage(
                    url: photoUrl, size: widget.size,
                    radius: widget.radius, fallback: gradientCell),
                ),
              ),
            ],
          );
        },
      );
    } else if (isToday) {
      child = AnimatedBuilder(
        animation: widget.pulseAnim,
        builder: (_, __) {
          final opacity = widget.showPulse
              ? 0.55 + 0.45 * widget.pulseAnim.value
              : 1.0;
          return Opacity(
            opacity: opacity,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.radius),
                color: pigColor.withAlpha(0x33),
                border: Border.all(color: pigColor, width: 1.5),
              ),
            ),
          );
        },
      );
    } else {
      child = Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          color: widget.emptyColor,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      );
    }

    if (widget.onTap != null) {
      return GestureDetector(onTap: widget.onTap, child: child);
    }
    return child;
  }
}

// ── Photo image (network or local file) ───────────────────────────────────────

class _PhotoImage extends StatelessWidget {
  final String url;
  final double size;
  final double radius;
  final Widget fallback;

  const _PhotoImage({
    required this.url,
    required this.size,
    required this.radius,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    // Local file path
    if (!url.startsWith('http')) {
      return Image.file(
        File(url),
        width: size, height: size, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    // Remote URL
    return CachedNetworkImage(
      imageUrl: url,
      width: size, height: size, fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 300),
      placeholder: (_, __) => fallback,
      errorWidget: (_, __, ___) => fallback,
    );
  }
}
