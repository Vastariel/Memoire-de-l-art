import 'package:flutter/material.dart';
import '../models/zone.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import '../theme/typography.dart';
import 'overline.dart';

// Legacy badge — kept for compatibility; prefer ColorDayCard for new UI.
class PigBadge extends StatelessWidget {
  final ZoneColor pigment;
  final double swatchSize;

  const PigBadge({super.key, required this.pigment, this.swatchSize = 56});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? MdaDark.surface : MdaLight.surface;
    final fg1     = isDark ? MdaDark.fg1     : MdaLight.fg1;
    final line    = isDark ? MdaDark.line    : MdaLight.line;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 18, 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: MdaRadius.bLg,
        border: Border.all(color: line),
        boxShadow: MdaShadows.md,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: swatchSize,
            height: swatchSize,
            decoration: BoxDecoration(
              color: pigment.color,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 0, spreadRadius: 1),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const MdaOverline('Couleur du jour'),
              const SizedBox(height: 3),
              Text(
                pigment.label,
                style: MdaType.pigName(color: fg1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
