import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
// ignore: unused_import
import 'overline.dart';

class MdaTopBar extends StatelessWidget {
  final String? overline;
  final String? title;
  final Widget? leading;
  final Widget? trailing;
  final bool dark;

  const MdaTopBar({
    super.key,
    this.overline,
    this.title,
    this.leading,
    this.trailing,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = dark || Theme.of(context).brightness == Brightness.dark;
    final fg1 = isDark ? MdaDark.fg1 : MdaLight.fg1;
    final fg2 = isDark ? MdaDark.fg2 : MdaLight.fg2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (overline != null)
                  MdaOverline(overline!, color: dark ? const Color(0xB3FFFFFF) : fg2),
                if (title != null) ...[
                  if (overline != null) const SizedBox(height: 2),
                  Text(
                    title!,
                    style: TextStyle(
                      fontFamily: MdaFonts.serif,
                      fontSize: 26,
                      height: 1.05,
                      color: dark ? Colors.white : fg1,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}
