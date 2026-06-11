// instance_detail_screen.dart — détail instance : classement, membres, invitation.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/mock_data.dart';
import '../../l10n/app_localizations.dart';
import '../../models/game_models.dart';
import '../../providers/game_provider.dart';
import '../../theme/colors.dart';
import '../../theme/palette.dart';
import '../../theme/theme.dart';
import '../../theme/typography.dart';
import '../../widgets/game_widgets.dart';
import '../../widgets/mda_icon.dart';
import '../../widgets/primitives.dart';

class InstanceDetailScreen extends ConsumerStatefulWidget {
  final String instanceId;
  const InstanceDetailScreen({super.key, required this.instanceId});
  @override
  ConsumerState<InstanceDetailScreen> createState() => _InstanceDetailScreenState();
}

class _InstanceDetailScreenState extends ConsumerState<InstanceDetailScreen> {
  String _tab = 'rank';

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final g = ref.watch(gameProvider);
    final inst = g.instances.firstWhere((i) => i.id == widget.instanceId, orElse: () => g.instances.first);
    final ranked = [...MockData.members]..sort((a, b) => b.points.compareTo(a.points));

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        TopBar(
          overline: inst.name,
          title: t.leaderboard,
          leading: IconTapButton('back', color: context.fg1, onTap: () => context.pop()),
          trailing: IconTapButton('share', color: context.accent, onTap: () => _invite(inst)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            InstanceBadge(mode: inst.mode, big: true),
            const SizedBox(width: 9),
            Expanded(
              child: Text(inst.mode.isShared ? t.sharedExplain : t.separateExplain,
                  style: MdaType.sans(size: 12.5, height: 1.4, color: context.fg2)),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        if (inst.solo)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(children: [
              const MdaIcon('user', size: 30, color: MdaColors.ardoise),
              const SizedBox(height: 8),
              Text(t.soloInstance, style: MdaType.serif(size: 18, color: context.fg1)),
              const SizedBox(height: 4),
              Text(t.soloInstanceDesc, textAlign: TextAlign.center, style: MdaType.sans(size: 13, color: context.fg2)),
            ]),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              _tabBtn('rank', t.weeklyTab),
              const SizedBox(width: 8),
              _tabBtn('members', t.membersTab),
            ]),
          ),
          const SizedBox(height: 12),
          if (_tab == 'rank')
            for (var i = 0; i < ranked.length; i++)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 9),
                child: LeaderRow(rank: i + 1, entry: ranked[i]),
              )
          else
            for (final m in ranked)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 9),
                child: _MemberRow(entry: m),
              ),
        ],
      ],
    );
  }

  Widget _tabBtn(String k, String label) {
    final on = _tab == k;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = k),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(color: on ? context.fg1 : context.surfaceSunk, borderRadius: BorderRadius.circular(999)),
          child: Text(label,
              textAlign: TextAlign.center,
              style: MdaType.sans(size: 13.5, weight: FontWeight.w600, color: on ? context.paper : context.fg2)),
        ),
      ),
    );
  }

  void _invite(InstanceSummary inst) {
    final t = L10n.of(context);
    showMdaSheet(context, builder: (ctx) => _InviteSheet(inst: inst, t: t));
  }
}

class _MemberRow extends StatelessWidget {
  final LeaderEntry entry;
  const _MemberRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: context.surface, borderRadius: MdaRadius.bMd, border: Border.all(color: context.line)),
      child: Row(children: [
        MdaAvatar(pig: entry.pig, initial: entry.pseudo[0], size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(TextSpan(children: [
            TextSpan(text: entry.pseudo, style: MdaType.sans(size: 15, weight: FontWeight.w600, color: context.fg1)),
            if (entry.you) TextSpan(text: ' · ${t.labelYou}', style: MdaType.sans(size: 15, color: context.fg3)),
          ])),
        ),
        StreakChip(entry.streak, small: true),
      ]),
    );
  }
}

class _InviteSheet extends StatefulWidget {
  final InstanceSummary inst;
  final L10n t;
  const _InviteSheet({required this.inst, required this.t});
  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  String _via = 'code';
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final code = '${widget.inst.id}X7';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(t.inviteTo(widget.inst.name), style: MdaType.serif(size: 23, weight: FontWeight.w500, color: context.fg1)),
      const SizedBox(height: 4),
      Text(t.inviteShareAny, style: MdaType.sans(size: 13.5, color: context.fg2)),
      const SizedBox(height: 18),
      Row(children: [
        _viaTab('code', t.viaCode, 'qr'),
        const SizedBox(width: 8),
        _viaTab('link', t.viaLink, 'link'),
        const SizedBox(width: 8),
        _viaTab('qr', t.viaQr, 'qr'),
      ]),
      const SizedBox(height: 18),
      if (_via == 'code')
        Center(
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
              for (final ch in code.split('')) ...[
                Container(
                  width: 46,
                  height: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 4.5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: context.surfaceSunk, borderRadius: MdaRadius.bSm),
                  child: Text(ch, style: MdaType.serif(size: 27, color: context.fg1)),
                ),
              ],
            ]),
            const SizedBox(height: 10),
            Text(t.validDays(7), style: MdaType.sans(size: 13, color: context.fg2)),
          ]),
        ),
      if (_via == 'link')
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: context.surfaceSunk, borderRadius: MdaRadius.bMd),
          child: Row(children: [
            MdaIcon('link', size: 18, color: context.fg3),
            const SizedBox(width: 10),
            Expanded(child: Text('memoire.art/i/${widget.inst.id}-x7', overflow: TextOverflow.ellipsis, style: MdaType.sans(size: 14, color: context.fg1))),
            MdaButton(_copied ? t.actionCopied : t.actionCopy, variant: MdaBtnVariant.ink, icon: _copied ? 'check' : 'copy',
                fontSize: 13, padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7), onTap: () => setState(() => _copied = true)),
          ]),
        ),
      if (_via == 'qr')
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: MdaRadius.bLg, boxShadow: MdaShadows.md),
            child: MdaQr('${widget.inst.id}-MDA', size: 150),
          ),
        ),
      const SizedBox(height: 20),
      MdaButton(t.shareInvite, full: true, icon: 'share', onTap: () => Navigator.of(context).pop()),
    ]);
  }

  Widget _viaTab(String k, String label, String icon) {
    final on = _via == k;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _via = k),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: on ? MdaColors.clay100 : context.surface,
            borderRadius: MdaRadius.bMd,
            border: Border.all(color: on ? context.accent : context.line),
          ),
          child: Column(children: [
            MdaIcon(icon, size: 18, color: on ? MdaColors.clay600 : context.fg2, strokeWidth: 1.8),
            const SizedBox(height: 5),
            Text(label, style: MdaType.sans(size: 12.5, weight: FontWeight.w600, color: on ? MdaColors.clay600 : context.fg2)),
          ]),
        ),
      ),
    );
  }
}
