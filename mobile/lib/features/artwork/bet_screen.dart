// bet_screen.dart — Pari mystère : deviner le titre, plus tôt = plus de points.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/mock_data.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/data_providers.dart';
import '../../providers/game_provider.dart';
import '../../theme/palette.dart';
import '../../theme/theme.dart';
import '../../theme/typography.dart';
import '../../widgets/mda_icon.dart';
import '../../widgets/mosaic.dart';
import '../../widgets/primitives.dart';

class BetScreen extends ConsumerStatefulWidget {
  const BetScreen({super.key});
  @override
  ConsumerState<BetScreen> createState() => _BetScreenState();
}

class _BetScreenState extends ConsumerState<BetScreen> {
  String? _pick;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final g = ref.watch(gameProvider);
    final options = ref.watch(betOptionsProvider).valueOrNull ?? MockData.betOptions;

    return Scaffold(
      backgroundColor: context.paper,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TopBar(
            overline: t.betDayOverline(g.weekDay),
            title: t.mysteryBet,
            leading: IconTapButton('back', color: context.fg1, onTap: () => context.pop()),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                ClipRRect(
                  borderRadius: MdaRadius.bLg,
                  child: Stack(children: [
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: MosaicWidget(filled: g.filled, pulse: false),
                    ),
                    Positioned.fill(child: Container(color: context.paper.withValues(alpha: 0.34))),
                  ]),
                ),
                const SizedBox(height: 18),
                Row(children: [
                  const PointsTag(150, icon: 'sparkles'),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t.betPointsHint, style: MdaType.sans(size: 12.5, color: context.fg2))),
                ]),
                const SizedBox(height: 14),
                for (final o in options) ...[
                  _OptionRow(
                    title: o.title,
                    subtitle: '${o.artist} · ${o.year}',
                    selected: _pick == o.id,
                    onTap: () => setState(() => _pick = o.id),
                  ),
                  const SizedBox(height: 9),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(children: [
              MdaButton(
                t.placeMyBet,
                full: true,
                disabled: _pick == null,
                onTap: _pick == null
                    ? null
                    : () {
                        final title = options.firstWhere((o) => o.id == _pick).title;
                        ref.read(gameProvider.notifier).placeBet(title);
                        context.pop();
                      },
              ),
              const SizedBox(height: 12),
              Text(t.betRule, textAlign: TextAlign.center, style: MdaType.sans(size: 12, color: context.fg3)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _OptionRow({required this.title, required this.subtitle, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: MdaRadius.bMd,
          border: Border.all(color: selected ? context.accent : context.line, width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? context.accent : Colors.transparent,
              border: Border.all(color: selected ? context.accent : context.lineStrong, width: 2),
            ),
            child: selected ? const Center(child: MdaIcon('check', size: 13, color: Colors.white, strokeWidth: 3)) : null,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(title, style: MdaType.serif(size: 16, italic: true, color: context.fg1)),
              Text(subtitle, style: MdaType.sans(size: 12, color: context.fg2)),
            ]),
          ),
        ]),
      ),
    );
  }
}
