import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class MdaOverline extends StatelessWidget {
  final String text;
  final Color? color;

  const MdaOverline(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? MdaDark.fg2 : MdaLight.fg2;
    return Text(
      text.toUpperCase(),
      style: MdaType.overline(color: color ?? defaultColor),
    );
  }
}
