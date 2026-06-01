import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import '../theme/typography.dart';

enum MdaButtonVariant { primary, secondary, ghost, dark }

class MdaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final MdaButtonVariant variant;
  final IconData? icon;
  final bool expand;

  const MdaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = MdaButtonVariant.primary,
    this.icon,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabled = onPressed == null;

    ButtonStyle style;
    switch (variant) {
      case MdaButtonVariant.primary:
        style = FilledButton.styleFrom(
          backgroundColor: isDark ? MdaDark.accent : MdaLight.accent,
          foregroundColor: isDark ? MdaDark.onAccent : MdaLight.onAccent,
          disabledBackgroundColor: (isDark ? MdaDark.accent : MdaLight.accent).withAlpha(0x73),
        );
      case MdaButtonVariant.secondary:
        style = OutlinedButton.styleFrom(
          foregroundColor: isDark ? MdaDark.fg1 : MdaLight.fg1,
          side: BorderSide(color: isDark ? MdaDark.lineStrong : MdaLight.lineStrong),
        );
      case MdaButtonVariant.ghost:
        style = TextButton.styleFrom(
          foregroundColor: isDark ? MdaDark.accent : MdaLight.accent,
        );
      case MdaButtonVariant.dark:
        style = FilledButton.styleFrom(
          backgroundColor: Colors.white.withAlpha(0x28),
          foregroundColor: Colors.white,
        );
    }

    style = style.copyWith(
      textStyle: WidgetStatePropertyAll(MdaType.title()),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      ),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      animationDuration: const Duration(milliseconds: 120),
    );

    Widget child = icon != null
        ? Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 19),
            const SizedBox(width: 9),
            Text(label),
          ])
        : Text(label);

    Widget btn;
    switch (variant) {
      case MdaButtonVariant.secondary:
        btn = OutlinedButton(onPressed: onPressed, style: style, child: child);
      case MdaButtonVariant.ghost:
        btn = TextButton(onPressed: onPressed, style: style, child: child);
      default:
        btn = FilledButton(onPressed: onPressed, style: style, child: child);
    }

    return expand ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
