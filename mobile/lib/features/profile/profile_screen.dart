// profile_screen.dart — Profil : avatar, stats, assiduité, instances.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/mock_data.dart';
import '../../engine/mosaic_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../models/game_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/colors.dart';
import '../../theme/palette.dart';
import '../../theme/theme.dart';
import '../../theme/typography.dart';
import '../../widgets/game_widgets.dart';
import '../../widgets/mda_icon.dart';
import '../../widgets/primitives.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context);
    final lang = ref.watch(langProvider);
    final g = ref.watch(gameProvider);
    final auth = ref.watch(authProvider);
    final pseudo = auth.pseudo;
    const famKeys = ['bleus', 'ors', 'verts', 'terres', 'roses', 'rouges', 'gris'];

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        TopBar(title: t.tabProfile, trailing: IconTapButton('settings', onTap: () => context.push('/settings'))),
        Column(children: [
          MdaAvatar(pig: MockData.myPig, initial: pseudo.isNotEmpty ? pseudo[0] : 'C', size: 84, ring: 2),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _editPseudo(context, ref, pseudo),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(pseudo, style: MdaType.serif(size: 24, weight: FontWeight.w500, color: context.fg1)),
              const SizedBox(width: 7),
              MdaIcon('user', size: 15, color: context.fg3),
            ]),
          ),
          Text(t.memberSince(lang == 'en' ? 'March' : 'mars'), style: MdaType.sans(size: 13, color: context.fg2)),
        ]),
        // stats
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Row(children: [
            _stat(context, '${g.points}', t.unitPts, 'star'),
            const SizedBox(width: 11),
            _stat(context, '${g.streak}', t.statStreak, 'flame'),
            const SizedBox(width: 11),
            _stat(context, '12', t.statWorks, 'frame'),
          ]),
        ),
        // assiduité
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Overline(t.attendance),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 7,
              crossAxisSpacing: 7,
              children: [
                for (var i = 0; i < 28; i++)
                  () {
                    final on = i % 9 != 4 && hash(i * 3.7) > 0.32;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        gradient: on ? fillGradient(MdaColors.pig(kFamilies[famKeys[i % 7]]!.variants[1]), i) : null,
                        color: on ? null : MdaColors.cream200,
                      ),
                    );
                  }(),
              ],
            ),
          ]),
        ),
        // instances
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Overline(t.myInstances),
            const SizedBox(height: 10),
            for (final inst in g.instances) ...[
              GestureDetector(
                onTap: () => context.push('/instances/instance/${inst.id}'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(color: context.surface, borderRadius: MdaRadius.bMd, border: Border.all(color: context.line)),
                  child: Row(children: [
                    MdaIcon(inst.mode.isShared ? 'layers' : 'camera', size: 18,
                        color: inst.mode.isShared ? MdaColors.shared : MdaColors.separate),
                    const SizedBox(width: 11),
                    Expanded(child: Text(inst.name, style: MdaType.sans(size: 14.5, weight: FontWeight.w600, color: context.fg1))),
                    InstanceBadge(mode: inst.mode),
                  ]),
                ),
              ),
              const SizedBox(height: 9),
            ],
          ]),
        ),
      ],
    );
  }

  Future<void> _editPseudo(BuildContext context, WidgetRef ref, String current) async {
    final t = L10n.of(context);
    final ctrl = TextEditingController(text: current);
    final next = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.renameTitle),
        content: TextField(controller: ctrl, autofocus: true, maxLength: 32),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: Text(t.save)),
        ],
      ),
    );
    if (next != null && next.trim().isNotEmpty && next.trim() != current) {
      await ref.read(authProvider.notifier).updatePseudo(next);
    }
  }

  Widget _stat(BuildContext context, String value, String label, String icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        decoration: BoxDecoration(color: context.surface, borderRadius: MdaRadius.bMd, border: Border.all(color: context.line)),
        child: Column(children: [
          MdaIcon(icon, size: 19, color: MdaColors.gold),
          const SizedBox(height: 5),
          Text(value, style: MdaType.serif(size: 23, height: 1, color: context.fg1)),
          const SizedBox(height: 4),
          Overline(label, fontSize: 10),
        ]),
      ),
    );
  }
}
