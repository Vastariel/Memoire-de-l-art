// mda_tab_bar.dart — barre d'onglets v2 (5 onglets).

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/palette.dart';
import '../theme/typography.dart';
import 'mda_icon.dart';

class MdaTabBar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTap;
  const MdaTabBar({super.key, required this.activeIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final tabs = [
      ('sun', l.tabToday),
      ('frame', l.tabArtwork),
      ('users', l.tabInstances),
      ('layers', l.tabCollection),
      ('user', l.tabProfile),
    ];
    return Container(
      padding: const EdgeInsets.only(top: 9, bottom: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [context.paper, context.paper.withValues(alpha: 0)],
          stops: const [0.64, 1],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < tabs.length; i++)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  MdaIcon(tabs[i].$1,
                      size: 22,
                      color: i == activeIndex ? context.accent : context.fg3,
                      strokeWidth: i == activeIndex ? 2 : 1.7),
                  const SizedBox(height: 4),
                  Text(tabs[i].$2,
                      style: MdaType.sans(
                          size: 10.5,
                          weight: FontWeight.w600,
                          letterSpacing: -0.1,
                          color: i == activeIndex ? context.accent : context.fg3)),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}
