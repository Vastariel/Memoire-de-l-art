// variant_screen.dart — Choix de variante (claim, premier arrivé).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/mock_data.dart';
import '../../engine/mosaic_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/data_providers.dart';
import '../../providers/game_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/palette.dart';
import '../../theme/theme.dart';
import '../../theme/typography.dart';
import '../../widgets/mda_icon.dart';
import '../../widgets/primitives.dart';

class VariantScreen extends ConsumerWidget {
  const VariantScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context);
    final lang = ref.watch(langProvider);
    final g = ref.watch(gameProvider);
    final fam = kFamilies[g.todayFamily]!;
    final claims = ref.watch(claimsProvider(g.activeInstanceId)).valueOrNull;
    final taken = claims ?? MockData.takenVariants;

    return Scaffold(
      backgroundColor: context.paper,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TopBar(title: t.claimYourPortion, leading: IconTapButton('back', color: context.fg1, onTap: () => context.pop())),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                Text(t.familyFirstCome(fam.name(lang)), style: MdaType.serif(size: 16, italic: true, height: 1.3, color: context.fg2)),
                const SizedBox(height: 4),
                Text(t.variantExplain, style: MdaType.sans(size: 13.5, height: 1.5, color: context.fg3)),
                const SizedBox(height: 20),
                for (final vk in fam.variants) ...[
                  _VariantRow(
                    variantKey: vk,
                    lang: lang,
                    takenBy: taken[vk],
                    mine: vk == g.myVariant,
                    blocks: kArtwork.countForVariant(vk),
                    onTap: (taken.containsKey(vk) && vk != g.myVariant)
                        ? null
                        : () {
                            ref.read(gameProvider.notifier).claimVariant(vk);
                            ref.invalidate(claimsProvider(g.activeInstanceId));
                            context.pop();
                          },
                  ),
                  const SizedBox(height: 11),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: MdaButton(t.shootMyVariant, full: true, icon: 'camera', onTap: () {
              ref.read(gameProvider.notifier).setCaptureTask(g.tasks.first);
              context.push('/camera');
            }),
          ),
        ]),
      ),
    );
  }
}

class _VariantRow extends StatelessWidget {
  final String variantKey;
  final String lang;
  final String? takenBy;
  final bool mine;
  final int blocks;
  final VoidCallback? onTap;
  const _VariantRow({
    required this.variantKey,
    required this.lang,
    required this.takenBy,
    required this.mine,
    required this.blocks,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final v = kVariants[variantKey]!;
    final taken = takenBy != null && !mine;
    return Opacity(
      opacity: taken ? 0.55 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: MdaRadius.bMd,
            border: Border.all(color: mine ? context.accent : context.line, width: 1.5),
          ),
          child: Row(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), gradient: fillGradient(v.color, 5)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(v.name(lang), style: MdaType.serif(size: 19, color: context.fg1)),
                const SizedBox(height: 3),
                Text(takenBy != null ? t.takenBy(takenBy!) : t.blocksOpen(blocks),
                    style: MdaType.sans(size: 12.5, color: context.fg2)),
              ]),
            ),
            const SizedBox(width: 8),
            if (mine)
              MdaChip(t.mine, active: true)
            else if (taken)
              MdaIcon('lock', size: 17, color: context.fg3)
            else
              MdaIcon('plus', size: 20, color: context.accent),
          ]),
        ),
      ),
    );
  }
}
