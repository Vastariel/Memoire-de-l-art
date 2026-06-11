// primitives.dart — composants UI de base (port de ui.jsx).

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../theme/palette.dart';
import '../theme/theme.dart';
import '../theme/typography.dart';
import 'mda_icon.dart';

enum MdaBtnVariant { primary, secondary, ghost, ink, dark }

class MdaButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final MdaBtnVariant variant;
  final String? icon;
  final String? iconRight;
  final bool full;
  final bool disabled;
  final EdgeInsetsGeometry? padding;
  final double fontSize;
  final Color? textColor;

  const MdaButton(
    this.label, {
    super.key,
    this.onTap,
    this.variant = MdaBtnVariant.primary,
    this.icon,
    this.iconRight,
    this.full = false,
    this.disabled = false,
    this.padding,
    this.fontSize = 16,
    this.textColor,
  });

  @override
  State<MdaButton> createState() => _MdaButtonState();
}

class _MdaButtonState extends State<MdaButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.disabled && widget.onTap != null;
    late Color bg;
    late Color fg;
    Border? border;
    List<BoxShadow>? shadow;
    switch (widget.variant) {
      case MdaBtnVariant.primary:
        bg = context.accent;
        fg = context.onAccent;
        shadow = MdaShadows.sm;
        break;
      case MdaBtnVariant.secondary:
        bg = context.surface;
        fg = context.fg1;
        border = Border.all(color: context.lineStrong);
        break;
      case MdaBtnVariant.ghost:
        bg = Colors.transparent;
        fg = context.accent;
        break;
      case MdaBtnVariant.ink:
        bg = context.fg1;
        fg = context.paper;
        break;
      case MdaBtnVariant.dark:
        bg = Colors.white.withValues(alpha: 0.16);
        fg = Colors.white;
        break;
    }
    fg = widget.textColor ?? fg;
    final child = Container(
      width: widget.full ? double.infinity : null,
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: MdaRadius.bPill,
        border: border,
        boxShadow: enabled ? shadow : null,
      ),
      child: Row(
        mainAxisSize: widget.full ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            MdaIcon(widget.icon!, size: 19, color: fg),
            const SizedBox(width: 9),
          ],
          Flexible(
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              style: MdaType.sans(size: widget.fontSize, weight: FontWeight.w600, color: fg),
            ),
          ),
          if (widget.iconRight != null) ...[
            const SizedBox(width: 9),
            MdaIcon(widget.iconRight!, size: 19, color: fg),
          ],
        ],
      ),
    );
    return Opacity(
      opacity: enabled ? 1 : 0.42,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTap: enabled ? widget.onTap : null,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          child: child,
        ),
      ),
    );
  }
}

class Overline extends StatelessWidget {
  final String text;
  final Color? color;
  final double fontSize;
  const Overline(this.text, {super.key, this.color, this.fontSize = 12});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: MdaType.overline(color: color ?? context.fg2).copyWith(fontSize: fontSize),
      );
}

class MdaDivider extends StatelessWidget {
  final String? label;
  const MdaDivider({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    final line = Expanded(child: Container(height: 1, color: context.line));
    if (label == null) return line;
    return Row(children: [
      line,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Overline(label!, color: context.fg3, fontSize: 11),
      ),
      line,
    ]);
  }
}

class MdaChip extends StatelessWidget {
  final String label;
  final Color? swatch;
  final bool active;
  final VoidCallback? onTap;
  final double opacity;
  const MdaChip(this.label, {super.key, this.swatch, this.active = false, this.onTap, this.opacity = 1});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? context.fg1 : MdaColors.cream200,
            borderRadius: MdaRadius.bPill,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (swatch != null) ...[
              Container(width: 13, height: 13, decoration: BoxDecoration(color: swatch, borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 8),
            ],
            Text(label, style: MdaType.sans(size: 13, weight: FontWeight.w600, color: active ? context.paper : context.fg1)),
          ]),
        ),
      ),
    );
  }
}

class MdaProgressBar extends StatelessWidget {
  final int value;
  final int total;
  final String label;
  final String unit;
  const MdaProgressBar({super.key, required this.value, this.total = 7, required this.label, required this.unit});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : (value / total).clamp(0, 1).toDouble();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Overline(label),
        Text('$unit $value / $total', style: MdaType.serif(size: 17, color: context.fg1)),
      ]),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 8,
          color: MdaColors.cream200,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: pct,
            child: Container(color: context.accent),
          ),
        ),
      ),
    ]);
  }
}

class MdaAvatar extends StatelessWidget {
  final String pig;
  final String initial;
  final double size;
  final int ring; // 0 none, 1 gold, 2 accent
  const MdaAvatar({super.key, required this.pig, required this.initial, this.size = 44, this.ring = 0});

  @override
  Widget build(BuildContext context) {
    final hex = MdaColors.pig(pig);
    final hsl = HSLColor.fromColor(hex);
    final light = hsl.withLightness((hsl.lightness + 0.12).clamp(0, 1)).toColor();
    final dark = hsl.withLightness((hsl.lightness - 0.12).clamp(0, 1)).toColor();
    Widget avatar = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [light, hex, dark]),
      ),
      child: Text(initial, style: MdaType.serif(size: size * 0.42, color: Colors.white)),
    );
    if (ring > 0) {
      final ringColor = ring == 1 ? MdaColors.gold : context.accent;
      avatar = Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ringColor, width: 2),
          color: context.surface,
        ),
        child: avatar,
      );
    }
    return avatar;
  }
}

enum BannerTone { clay, gold, shared }

class MdaBanner extends StatelessWidget {
  final String icon;
  final BannerTone tone;
  final String text;
  final VoidCallback? onTap;
  const MdaBanner({super.key, this.icon = 'bell', this.tone = BannerTone.clay, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    switch (tone) {
      case BannerTone.clay:
        bg = MdaColors.clay100;
        fg = MdaColors.clay600;
        break;
      case BannerTone.gold:
        bg = MdaColors.gold.withValues(alpha: 0.14);
        fg = MdaColors.gold;
        break;
      case BannerTone.shared:
        bg = MdaColors.shared.withValues(alpha: 0.12);
        fg = MdaColors.shared;
        break;
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(color: bg, borderRadius: MdaRadius.bMd),
        child: Row(children: [
          MdaIcon(icon, size: 20, color: fg, strokeWidth: 1.9),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: MdaType.sans(size: 14, weight: FontWeight.w600, color: fg))),
          if (onTap != null) MdaIcon('right', size: 18, color: fg),
        ]),
      ),
    );
  }
}

class PointsTag extends StatelessWidget {
  final int value;
  final String icon;
  const PointsTag(this.value, {super.key, this.icon = 'star'});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: MdaColors.gold.withValues(alpha: 0.16), borderRadius: MdaRadius.bPill),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        MdaIcon(icon, size: 13, color: MdaColors.gold, strokeWidth: 2),
        const SizedBox(width: 5),
        Text('${value >= 0 ? '+' : ''}$value ${l.unitPts}',
            style: MdaType.sans(size: 13, weight: FontWeight.w700, color: MdaColors.gold)),
      ]),
    );
  }
}

class StreakChip extends StatelessWidget {
  final int days;
  final bool small;
  const StreakChip(this.days, {super.key, this.small = false});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 9 : 11, vertical: small ? 3 : 5),
      decoration: BoxDecoration(color: MdaColors.gold.withValues(alpha: 0.14), borderRadius: MdaRadius.bPill),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        MdaIcon('flame', size: small ? 13 : 15, color: MdaColors.gold, strokeWidth: 2),
        const SizedBox(width: 6),
        Text(l.streakDays(days),
            style: MdaType.sans(size: small ? 12 : 13, weight: FontWeight.w700, color: MdaColors.gold)),
      ]),
    );
  }
}

class TopBar extends StatelessWidget {
  final String? overline;
  final String? title;
  final Widget? leading;
  final Widget? trailing;
  const TopBar({super.key, this.overline, this.title, this.leading, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Row(children: [
        if (leading != null) ...[leading!, const SizedBox(width: 12)],
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            if (overline != null) Overline(overline!),
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(title!, style: MdaType.serif(size: 26, height: 1.05, color: context.fg1)),
              ),
          ]),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ]),
    );
  }
}

/// Bouton-icône discret (header).
class IconTapButton extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;
  final Color? color;
  final double size;
  const IconTapButton(this.icon, {super.key, required this.onTap, this.color, this.size = 22});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(padding: const EdgeInsets.all(6), child: MdaIcon(icon, size: size, color: color ?? context.fg2)),
      );
}

/// Bottom sheet façon design (poignée + coins arrondis).
Future<T?> showMdaSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.surface,
    barrierColor: const Color(0x6B1C1813),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 36 + MediaQuery.of(ctx).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40, height: 5,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: MdaColors.cream300, borderRadius: BorderRadius.circular(999)),
        ),
        builder(ctx),
      ]),
    ),
  );
}
