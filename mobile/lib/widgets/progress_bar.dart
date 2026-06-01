import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import '../theme/typography.dart';
import 'overline.dart';

class MdaProgressBar extends StatelessWidget {
  final int day;
  final int total;
  final String? label;

  const MdaProgressBar({
    super.key,
    required this.day,
    required this.total,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent  = isDark ? MdaDark.accent  : MdaLight.accent;
    final track   = isDark ? MdaDark.mosaicEmpty : MdaColors.cream200;
    final fg1     = isDark ? MdaDark.fg1 : MdaLight.fg1;
    final pct     = total == 0 ? 0.0 : (day / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            MdaOverline(label ?? 'Progression du mois'),
            const Spacer(),
            Text(
              'jour $day / $total',
              style: MdaType.num(color: fg1).copyWith(fontSize: 17),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: MdaRadius.bPill,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
            duration: MdaDuration.slow,
            curve: MdaCurve.easeOut,
            builder: (_, value, __) => LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: track,
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
        ),
      ],
    );
  }
}
