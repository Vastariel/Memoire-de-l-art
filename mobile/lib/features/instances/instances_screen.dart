// instances_screen.dart — liste des instances (badge mode, membres, rang).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/game_models.dart';
import '../../providers/game_provider.dart';
import '../../theme/colors.dart';
import '../../theme/palette.dart';
import '../../theme/theme.dart';
import '../../theme/typography.dart';
import '../../widgets/game_widgets.dart';
import '../../widgets/mda_icon.dart';
import '../../widgets/mosaic.dart';
import '../../widgets/primitives.dart';

class InstancesScreen extends ConsumerWidget {
  const InstancesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context);
    final g = ref.watch(gameProvider);

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        TopBar(
          title: t.myInstances,
          trailing: GestureDetector(
            onTap: () => context.push('/onboarding'),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(shape: BoxShape.circle, color: context.accent),
              child: Center(child: MdaIcon('plus', size: 20, color: context.onAccent)),
            ),
          ),
        ),
        for (final inst in g.instances)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _InstanceCard(inst: inst, onTap: () => context.push('/instances/instance/${inst.id}')),
          ),
      ],
    );
  }
}

class _InstanceCard extends StatelessWidget {
  final InstanceSummary inst;
  final VoidCallback onTap;
  const _InstanceCard({required this.inst, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final preview = inst.solo ? const {'bleus'} : const {'bleus', 'ors', 'verts'};
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: context.surface, borderRadius: MdaRadius.bLg, border: Border.all(color: context.line), boxShadow: MdaShadows.sm),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 74,
            child: ClipRRect(
              borderRadius: MdaRadius.bSm,
              child: MosaicWidget(filled: preview, pulse: false, gap: 1),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Expanded(child: Text(inst.name, overflow: TextOverflow.ellipsis, style: MdaType.serif(size: 19, color: context.fg1))),
                const SizedBox(width: 8),
                InstanceBadge(mode: inst.mode),
              ]),
              const SizedBox(height: 7),
              Row(children: [
                MdaIcon('users', size: 14, color: context.fg3),
                const SizedBox(width: 5),
                Text('${inst.members}', style: MdaType.sans(size: 12.5, color: context.fg2)),
                const SizedBox(width: 12),
                if (inst.solo)
                  Text(t.labelSolo, style: MdaType.sans(size: 12.5, color: context.fg3))
                else ...[
                  const MdaIcon('trophy', size: 14, color: MdaColors.gold),
                  const SizedBox(width: 5),
                  Text('${inst.place}', style: MdaType.sans(size: 12.5, weight: FontWeight.w700, color: MdaColors.gold)),
                ],
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
