import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

enum MdaTab { today, artwork, group, profile }

class MdaTabBar extends StatelessWidget {
  final MdaTab active;
  final ValueChanged<MdaTab> onTap;

  const MdaTabBar({super.key, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper  = isDark ? MdaDark.paper  : MdaLight.paper;
    final accent = isDark ? MdaDark.accent : MdaLight.accent;
    final fg3    = isDark ? MdaDark.fg3    : MdaLight.fg3;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [paper, paper.withAlpha(0xF5), paper.withAlpha(0)],
          stops: const [0, 0.62, 1],
        ),
      ),
      padding: const EdgeInsets.only(bottom: 30, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: MdaTab.values.map((tab) {
          final on = active == tab;
          return _TabItem(
            tab: tab,
            on: on,
            activeColor: accent,
            inactiveColor: fg3,
            onTap: () => onTap(tab),
          );
        }).toList(),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final MdaTab tab;
  final bool on;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _TabItem({
    required this.tab,
    required this.on,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  IconData get _icon => switch (tab) {
    MdaTab.today   => Icons.wb_sunny_outlined,
    MdaTab.artwork => Icons.grid_view_rounded,
    MdaTab.group   => Icons.group_outlined,
    MdaTab.profile => Icons.person_outline_rounded,
  };

  String get _label => switch (tab) {
    MdaTab.today   => "Aujourd'hui",
    MdaTab.artwork => "L'œuvre",
    MdaTab.group   => 'Groupe',
    MdaTab.profile => 'Profil',
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icon,
              size: 23,
              color: on ? activeColor : inactiveColor,
              weight: on ? 700 : 400,
            ),
            const SizedBox(height: 4),
            Text(
              _label,
              style: MdaType.caption(color: on ? activeColor : inactiveColor)
                  .copyWith(fontSize: 11, decoration: TextDecoration.none),
            ),
          ],
        ),
      ),
    );
  }
}
