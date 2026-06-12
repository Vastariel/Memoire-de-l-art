// confirm_screen.dart — Confirmation : aperçu plat→vitrail + score + points.

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
import '../../widgets/game_widgets.dart';
import '../../widgets/mda_icon.dart';
import '../../widgets/primitives.dart';

class ConfirmScreen extends ConsumerStatefulWidget {
  const ConfirmScreen({super.key});
  @override
  ConsumerState<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends ConsumerState<ConfirmScreen> {
  bool _vit = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 420), () {
      if (mounted) setState(() => _vit = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final lang = ref.watch(langProvider);
    final g = ref.watch(gameProvider);
    final task = g.currentTask;
    final v = kVariants[task?.variant ?? g.myVariant]!;
    final cells = kArtwork.ofVariant(v.key).take(24).toList();

    return Scaffold(
      backgroundColor: context.paper,
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              children: [
                const Center(child: MdaIcon('checkCircle', size: 30, color: MdaColors.ok)),
                const SizedBox(height: 10),
                Text(t.colourAdded, textAlign: TextAlign.center, style: MdaType.serif(size: 25, weight: FontWeight.w500, color: context.fg1)),
                const SizedBox(height: 2),
                Text(t.meltedInto(v.name(lang)),
                    textAlign: TextAlign.center, style: MdaType.serif(size: 15.5, italic: true, height: 1.3, color: context.fg2)),
                const SizedBox(height: 18),
                // aperçu plat→vitrail
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(color: context.surfaceSunk, borderRadius: MdaRadius.bLg, border: Border.all(color: context.line)),
                      child: Column(children: [
                        GridView.count(
                          crossAxisCount: 6,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 5,
                          crossAxisSpacing: 5,
                          children: [
                            for (final c in cells)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Stack(children: [
                                  Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: fillGradient(c.pig, c.i)))),
                                  Positioned.fill(
                                    child: AnimatedOpacity(
                                      opacity: _vit ? 1 : 0,
                                      duration: const Duration(milliseconds: 600),
                                      child: VitrailFragment(c),
                                    ),
                                  ),
                                ]),
                              ),
                          ],
                        ),
                        const SizedBox(height: 13),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Overline(t.flat, fontSize: 10),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _vit = !_vit),
                            child: Container(
                              width: 42,
                              height: 24,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: _vit ? context.accent : MdaColors.cream300,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Align(
                                alignment: _vit ? Alignment.centerRight : Alignment.centerLeft,
                                child: const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Overline(t.glass, fontSize: 10),
                        ]),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                // score + points
                Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                  MatchScore(value: g.lastScore, size: 84, label: t.matchLabel),
                  const SizedBox(width: 24),
                  Container(width: 1, height: 62, color: context.line),
                  const SizedBox(width: 24),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    PointsTag(g.lastPoints),
                    const SizedBox(height: 8),
                    StreakChip(g.streak + 1),
                    const SizedBox(height: 6),
                    Text(t.streakBonus(20), style: MdaType.sans(size: 12, color: context.fg3)),
                  ]),
                ]),
                if (task != null && !task.isSeparate) ...[
                  const SizedBox(height: 18),
                  MdaBanner(icon: 'layers', tone: BannerTone.shared, text: t.alsoFed('Mes essais')),
                ],
                if (g.lastError != null) ...[
                  const SizedBox(height: 14),
                  MdaBanner(icon: 'info', tone: BannerTone.clay, text: g.lastError!),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(children: [
              MdaButton(t.seeTheArtwork, full: true, onTap: () async {
                await ref.read(gameProvider.notifier).confirmDone();
                if (context.mounted) context.go('/artwork');
              }),
              const SizedBox(height: 10),
              MdaButton(t.actionShare, full: true, variant: MdaBtnVariant.ghost, icon: 'share', onTap: () async {
                await ref.read(gameProvider.notifier).confirmDone();
                if (context.mounted) context.go('/reveal');
              }),
            ]),
          ),
        ]),
      ),
    );
  }
}
