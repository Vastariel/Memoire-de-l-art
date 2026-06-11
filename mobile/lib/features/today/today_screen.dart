// today_screen.dart — Aujourd'hui : progression, ma variante, photos à faire.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../engine/mosaic_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../models/game_models.dart';
import '../../providers/game_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/colors.dart';
import '../../theme/palette.dart';
import '../../theme/theme.dart';
import '../../theme/typography.dart';
import '../../widgets/game_widgets.dart';
import '../../widgets/mda_icon.dart';
import '../../widgets/primitives.dart';

String weekdayName(L10n t, int d) => switch (d) {
      1 => t.weekdayMon,
      2 => t.weekdayTue,
      3 => t.weekdayWed,
      4 => t.weekdayThu,
      5 => t.weekdayFri,
      6 => t.weekdaySat,
      _ => t.weekdaySun,
    };

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context);
    final lang = ref.watch(langProvider);
    final g = ref.watch(gameProvider);
    final missed = g.missedFamilies;

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        TopBar(
          overline: t.todayOverline(g.week, weekdayName(t, g.weekDay)),
          title: t.tabToday,
          trailing: IconTapButton('settings', onTap: () => context.push('/settings')),
        ),
        // progression
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: context.surfaceSunk, borderRadius: MdaRadius.bMd),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Overline(t.dayProgress(g.weekDay)),
              const SizedBox(height: 8),
              DayDots(done: g.doneCount, today: g.weekDay, labels: true, lang: lang),
            ]),
            StreakChip(g.streak),
          ]),
        ),
        const SizedBox(height: 18),
        // ma variante
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            VariantBadge(family: g.todayFamily, variant: g.myVariant, lang: lang),
            GestureDetector(
              onTap: () => context.push('/variant'),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  MdaIcon('refresh', size: 16, color: context.accent),
                  const SizedBox(width: 7),
                  Text(t.changeVariant, style: MdaType.sans(size: 13.5, weight: FontWeight.w600, color: context.accent)),
                ]),
              ),
            ),
          ]),
        ),
        // photos à faire
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Overline(t.photosToTakeToday),
              Text(t.tasksLeft(g.tasksLeft), style: MdaType.serif(size: 15, color: context.fg2)),
            ]),
            const SizedBox(height: 11),
            for (final task in g.tasks) ...[
              _TaskRow(
                task: task,
                lang: lang,
                onTap: task.done
                    ? null
                    : () {
                        ref.read(gameProvider.notifier).setCaptureTask(task);
                        context.push('/camera');
                      },
              ),
              const SizedBox(height: 11),
            ],
            Text(t.photosHelpNote, style: MdaType.sans(size: 12, height: 1.45, color: context.fg3)),
          ]),
        ),
        const SizedBox(height: 18),
        if (missed.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: MdaBanner(
              icon: 'clock',
              tone: BannerTone.clay,
              text: '${t.catchupCount(missed.length)} · ${missed.map((f) => kFamilies[f]!.name(lang)).join(', ')}',
              onTap: () => context.push('/catchup'),
            ),
          ),
        if (g.bet == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: MdaBanner(icon: 'sparkles', tone: BannerTone.gold, text: t.betBanner, onTap: () => context.push('/bet')),
          ),
        // leaderboard teaser
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: GestureDetector(
            onTap: () => context.push('/instances/instance/${g.activeInstance.id}'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: context.surface, borderRadius: MdaRadius.bMd, border: Border.all(color: context.line)),
              child: Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: MdaColors.gold.withValues(alpha: 0.16)),
                  child: const Center(child: MdaIcon('trophy', size: 20, color: MdaColors.gold)),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(t.leaderTeaser(g.activeInstance.place, g.activeInstance.members, g.activeInstance.name),
                        style: MdaType.sans(size: 14.5, weight: FontWeight.w600, color: context.fg1)),
                    Text(t.seeWeekLeaderboard, style: MdaType.sans(size: 12.5, color: context.fg2)),
                  ]),
                ),
                MdaIcon('right', size: 18, color: context.fg3),
              ]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: MdaProgressBar(value: g.doneCount, total: 7, label: t.weekProgress, unit: t.unitDay),
        ),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  final DailyTask task;
  final String lang;
  final VoidCallback? onTap;
  const _TaskRow({required this.task, required this.lang, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final v = kVariants[task.variant]!;
    final sep = task.isSeparate;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: task.done ? 0.62 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: MdaRadius.bMd,
            border: Border.all(color: sep ? MdaColors.separate : context.line),
            boxShadow: task.done ? null : MdaShadows.sm,
          ),
          child: Row(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: fillGradient(v.color, 4)),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Flexible(
                    child: Text(sep ? (task.instanceName ?? '') : t.sharedPhoto,
                        overflow: TextOverflow.ellipsis, style: MdaType.serif(size: 17, color: context.fg1)),
                  ),
                  const SizedBox(width: 8),
                  InstanceBadge(mode: task.kind),
                ]),
                const SizedBox(height: 4),
                Text(
                  sep ? t.taskSeparateSub(v.name(lang)) : t.taskSharedSub(task.covers.length, v.name(lang)),
                  style: MdaType.sans(size: 12.5, color: context.fg2),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            task.done
                ? const MdaIcon('checkCircle', size: 22, color: MdaColors.ok)
                : MdaIcon('camera', size: 20, color: sep ? MdaColors.separate : context.accent),
          ]),
        ),
      ),
    );
  }
}
