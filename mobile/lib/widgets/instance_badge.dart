import 'package:flutter/material.dart';

enum InstanceBadgeType { solo, online, creator }

class InstanceBadge extends StatelessWidget {
  final InstanceBadgeType type;
  const InstanceBadge(this.type, {super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (icon, label, bg, fg) = switch (type) {
      InstanceBadgeType.solo => (
        Icons.person_outline_rounded,
        'Local',
        isDark ? const Color(0xFF2A241D) : const Color(0xFFEBE3D2),
        isDark ? const Color(0xFF9C8E7C) : const Color(0xFF6C6354),
      ),
      InstanceBadgeType.online => (
        Icons.cloud_outlined,
        'En ligne',
        isDark ? const Color(0xFF172B1E) : const Color(0xFFD0EBDA),
        isDark ? const Color(0xFF5FA874) : const Color(0xFF2A6B42),
      ),
      InstanceBadgeType.creator => (
        Icons.star_rounded,
        'Créateur',
        isDark ? const Color(0xFF2E2210) : const Color(0xFFF3E4C0),
        isDark ? const Color(0xFFC98A2E) : const Color(0xFF8A5700),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10, color: fg,
              fontWeight: FontWeight.w600, letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// Builds the list of badges relevant to a saved instance.
List<InstanceBadge> instanceBadges({
  required bool isSolo,
  required bool isOnline,
  required bool isCreator,
}) {
  return [
    if (isSolo)    const InstanceBadge(InstanceBadgeType.solo),
    if (isOnline)  const InstanceBadge(InstanceBadgeType.online),
    if (isCreator) const InstanceBadge(InstanceBadgeType.creator),
  ];
}
