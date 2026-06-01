import 'package:flutter/material.dart';
import '../../models/instance.dart';
import '../../models/zone.dart';
import '../../services/session_manager.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../theme/typography.dart';
import '../../widgets/avatar.dart';
import '../../widgets/instance_badge.dart';
import '../../widgets/overline.dart';
import '../../widgets/top_bar.dart';

// Data bundle passed per instance to the group screen
class GroupInstanceData {
  final Instance instance;
  final Zone     todayZone;
  final bool     isCurrent;
  final bool     isSolo;
  final bool     isOnline;
  final bool     isCreator;

  const GroupInstanceData({
    required this.instance,
    required this.todayZone,
    required this.isCurrent,
    this.isSolo    = false,
    this.isOnline  = false,
    this.isCreator = false,
  });
}

class GroupScreen extends StatefulWidget {
  // Legacy single-instance signature kept for backward compat
  final Instance instance;
  final Zone todayZone;
  final List<GroupInstanceData>? allInstances;

  const GroupScreen({
    super.key,
    required this.instance,
    required this.todayZone,
    this.allInstances,
  });

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  late final List<GroupInstanceData> _groups;

  // Track which sections are expanded
  late final Map<String, bool> _expanded;

  @override
  void initState() {
    super.initState();
    _groups = widget.allInstances ??
        [GroupInstanceData(instance: widget.instance, todayZone: widget.todayZone, isCurrent: true)];
    _expanded = { for (final g in _groups) g.instance.code: true };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper  = isDark ? MdaDark.paper  : MdaLight.paper;
    final fg2    = isDark ? MdaDark.fg2    : MdaLight.fg2;

    final now = DateTime.now();

    return Scaffold(
      backgroundColor: paper,
      body: SafeArea(
        child: Column(
          children: [
            MdaTopBar(
              overline: 'Aujourd\'hui · ${now.day} ${_monthLabel(now.month)}',
              title: 'Le groupe',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 112),
                children: [
                  for (final group in _groups) ...[
                    _InstanceSection(
                      data:     group,
                      expanded: _expanded[group.instance.code] ?? true,
                      onToggle: () => setState(() {
                        _expanded[group.instance.code] = !(_expanded[group.instance.code] ?? true);
                      }),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _monthLabel(int m) {
    const l = ['','jan','fév','mar','avr','mai','juin','juil','août','sep','oct','nov','déc'];
    return l[m.clamp(1, 12)];
  }
}

// ── Instance section ──────────────────────────────────────────────────────────

class _InstanceSection extends StatelessWidget {
  final GroupInstanceData data;
  final bool expanded;
  final VoidCallback onToggle;

  const _InstanceSection({
    required this.data,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final surface  = isDark ? MdaDark.surface  : MdaLight.surface;
    final fg1      = isDark ? MdaDark.fg1      : MdaLight.fg1;
    final fg2      = isDark ? MdaDark.fg2      : MdaLight.fg2;
    final fg3      = isDark ? MdaDark.fg3      : MdaLight.fg3;
    final line     = isDark ? MdaDark.line     : MdaLight.line;
    final accent   = isDark ? MdaDark.accent   : MdaLight.accent;

    final inst      = data.instance;
    final zone      = data.todayZone;
    final players   = inst.players;
    final me        = players.firstWhere((p) => p.isMe, orElse: () => players.first);
    final contributed = players.where((p) => p.hasContributedToday).length;

    // Sort: me first, then contributed, then pending
    final sorted = [...players]..sort((a, b) {
      if (a.isMe) return -1;
      if (b.isMe) return 1;
      if (a.hasContributedToday && !b.hasContributedToday) return -1;
      if (!a.hasContributedToday && b.hasContributedToday) return 1;
      return 0;
    });

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: MdaRadius.bMd,
        border: Border.all(color: data.isCurrent ? accent.withAlpha(0x66) : line, width: data.isCurrent ? 1.5 : 1),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // ── Section header ─────────────────────────────────────
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  if (data.isCurrent)
                    Container(
                      width: 8, height: 8, margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                inst.name.isNotEmpty ? inst.name : inst.code,
                                style: MdaType.title(color: fg1).copyWith(fontSize: 15),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            ...instanceBadges(
                              isSolo:    data.isSolo,
                              isOnline:  data.isOnline,
                              isCreator: data.isCreator,
                            ).map((b) => Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: b,
                            )),
                          ],
                        ),
                        Text(
                          '${inst.code} · $contributed/${players.length} contributions',
                          style: MdaType.caption(color: fg2),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: fg3, size: 20,
                  ),
                ],
              ),
            ),
          ),

          // ── Player list ────────────────────────────────────────
          if (expanded)
            Column(
              children: [
                Divider(height: 1, color: line),
                ...sorted.map((player) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Opacity(
                    opacity: player.hasContributedToday ? 1.0 : 0.6,
                    child: Row(
                      children: [
                        MdaAvatar(
                          pigmentKey: player.avatarPigment,
                          initial: player.pseudo.isNotEmpty ? player.pseudo[0] : '?',
                          size: 38,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(player.pseudo,
                                      style: MdaType.title(color: fg1).copyWith(fontSize: 14)),
                                  if (player.isMe) ...[
                                    const SizedBox(width: 6),
                                    Text('· toi', style: MdaType.body(color: fg3).copyWith(fontSize: 14)),
                                  ],
                                ],
                              ),
                              Text(
                                player.hasContributedToday
                                    ? 'a photographié du ${zone.pigment.label.toLowerCase()}'
                                    : 'pas encore photographié',
                                style: MdaType.caption(color: fg2),
                              ),
                            ],
                          ),
                        ),
                        if (player.hasContributedToday)
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9),
                              color: zone.pigment.color,
                            ),
                          )
                        else
                          Icon(Icons.schedule_rounded, size: 18, color: fg3),
                      ],
                    ),
                  ),
                )),
              ],
            ),
        ],
      ),
    );
  }
}
