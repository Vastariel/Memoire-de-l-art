// catchup_screen.dart — Rattrapage : 1 photo par couleur manquée.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../engine/mosaic_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/game_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/colors.dart';
import '../../theme/palette.dart';
import '../../theme/theme.dart';
import '../../theme/typography.dart';
import '../../widgets/mda_icon.dart';
import '../../widgets/primitives.dart';
import 'today_screen.dart' show weekdayName;

class CatchupScreen extends ConsumerWidget {
  const CatchupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context);
    final lang = ref.watch(langProvider);
    final g = ref.watch(gameProvider);
    final missed = g.missedFamilies;

    return Scaffold(
      backgroundColor: context.paper,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TopBar(title: t.catchupTitle, leading: IconTapButton('back', color: context.fg1, onTap: () => context.pop())),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                Text(t.catchupLead, style: MdaType.serif(size: 16, italic: true, height: 1.3, color: context.fg2)),
                const SizedBox(height: 4),
                Text(t.catchupSub, style: MdaType.sans(size: 13.5, height: 1.5, color: context.fg3)),
                const SizedBox(height: 20),
                if (missed.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Column(children: [
                      const MdaIcon('checkCircle', size: 34, color: MdaColors.ok),
                      const SizedBox(height: 10),
                      Text(t.allCaughtUp, style: MdaType.serif(size: 19, color: context.fg1)),
                    ]),
                  )
                else
                  for (final f in missed) ...[
                    _MissedRow(family: f, lang: lang, onTap: () {
                      ref.read(gameProvider.notifier).setCaptureTask(g.tasks.first);
                      context.push('/camera');
                    }),
                    const SizedBox(height: 11),
                  ],
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _MissedRow extends StatelessWidget {
  final String family;
  final String lang;
  final VoidCallback onTap;
  const _MissedRow({required this.family, required this.lang, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final fam = kFamilies[family]!;
    final v = kVariants[fam.variants[1]]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(color: context.surface, borderRadius: MdaRadius.bMd, border: Border.all(color: context.line)),
      child: Row(children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), gradient: fillGradient(v.color, fam.day)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Overline(weekdayName(t, fam.day)),
            const SizedBox(height: 3),
            Text(fam.name(lang), style: MdaType.serif(size: 19, color: context.fg1)),
          ]),
        ),
        MdaButton(t.actionTake, variant: MdaBtnVariant.secondary, icon: 'camera', fontSize: 14,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), onTap: onTap),
      ]),
    );
  }
}
