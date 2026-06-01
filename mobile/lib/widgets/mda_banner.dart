import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class MdaBanner extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onTap;

  const MdaBanner({
    super.key,
    required this.text,
    this.icon = Icons.notifications_outlined,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: MdaColors.clay100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: MdaColors.clay600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: MdaType.bodySm(color: MdaColors.clay600).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, size: 18, color: MdaColors.clay600),
          ],
        ),
      ),
    );
  }
}
