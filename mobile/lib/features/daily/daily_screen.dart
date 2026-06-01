import 'package:flutter/material.dart';
import '../../models/artwork.dart';
import '../../models/instance.dart';
import '../../models/zone.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../theme/typography.dart';
import '../../widgets/avatar.dart';
import '../../widgets/mosaic.dart';
import '../../widgets/mda_button.dart';
import '../../widgets/mda_banner.dart';
import '../../widgets/color_day_card.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/top_bar.dart';

class DailyScreen extends StatelessWidget {
  final Instance instance;
  final Artwork artwork;
  final Zone todayZone;
  final bool hasDoneToday;
  final VoidCallback onCapture;
  final VoidCallback onSettings;
  final VoidCallback? onReveal;

  const DailyScreen({
    super.key,
    required this.instance,
    required this.artwork,
    required this.todayZone,
    required this.hasDoneToday,
    required this.onCapture,
    required this.onSettings,
    this.onReveal,
  });

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final paper   = isDark ? MdaDark.paper   : MdaLight.paper;
    final surface = isDark ? MdaDark.surface : MdaLight.surface;
    final line    = isDark ? MdaDark.line    : MdaLight.line;

    final daysLeft = (instance.daysInMonth - instance.dayNumber).clamp(0, instance.daysInMonth);

    return Scaffold(
      backgroundColor: paper,
      body: SafeArea(
        child: Column(
          children: [
            MdaTopBar(
              overline: '${Instance.monthLabel(instance.month)} · Instance ${instance.code}',
              title: "Aujourd'hui",
              trailing: IconButton(
                icon: Icon(Icons.settings_outlined, color: isDark ? MdaDark.fg2 : MdaLight.fg2),
                onPressed: onSettings,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 112),
                child: Column(
                  children: [
                    // ── Artwork vignette ──────────────────────────
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: MdaRadius.bLg,
                        border: Border.all(color: line),
                        boxShadow: MdaShadows.md,
                      ),
                      child: Column(
                        children: [
                          MosaicWidget(
                            artwork: artwork,
                            showPulse: !hasDoneToday,
                            gap: 2.5,
                            radius: 3,
                          ),
                          const SizedBox(height: 12),
                          // Progress bar + days remaining
                          Row(
                            children: [
                              Expanded(
                                child: MdaProgressBar(
                                  day: instance.dayNumber,
                                  total: instance.daysInMonth,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                daysLeft == 0
                                    ? 'Terminé'
                                    : 'J·$daysLeft',
                                style: TextStyle(
                                  fontFamily: MdaFonts.serif,
                                  fontSize: 13,
                                  color: isDark ? MdaDark.fg3 : MdaLight.fg3,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Group today row (multi-player only) ───────
                    if (instance.players.length > 1)
                      _GroupTodayRow(instance: instance),

                    // ── Status banner ─────────────────────────────
                    const SizedBox(height: 14),
                    if (instance.isMonthComplete || artwork.progress >= 1.0)
                      MdaBanner(
                        text: 'L\'œuvre est complète ! Découvrez la révélation.',
                        icon: Icons.auto_awesome_rounded,
                        onTap: onReveal,
                      )
                    else if (hasDoneToday)
                      const MdaBanner(
                        text: "C'est fait pour aujourd'hui. À demain !",
                        icon: Icons.check_circle_outline_rounded,
                      )
                    else
                      MdaBanner(
                        text: 'Ta couleur du jour t\'attend — ${todayZone.pigment.label}',
                        icon: Icons.camera_alt_outlined,
                        onTap: onCapture,
                      ),

                    // ── Pig badge + CTA ───────────────────────────
                    if (!instance.isMonthComplete && artwork.progress < 1.0)
                      Column(
                        children: [
                          ColorDayCard(zoneColor: todayZone.pigment),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: MdaButton(
                              label: hasDoneToday
                                  ? 'Reprendre ma photo'
                                  : 'Photographier ma couleur',
                              icon: Icons.camera_alt_outlined,
                              expand: true,
                              onPressed: onCapture,
                            ),
                          ),
                        ],
                      )
                    else if (onReveal != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                        child: MdaButton(
                          label: 'Voir l\'œuvre révélée',
                          icon: Icons.auto_awesome_rounded,
                          expand: true,
                          onPressed: onReveal,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Group contribution row ─────────────────────────────────────────────────────

class _GroupTodayRow extends StatelessWidget {
  final Instance instance;
  const _GroupTodayRow({required this.instance});

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final fg2      = isDark ? MdaDark.fg2 : MdaLight.fg2;
    final fg3      = isDark ? MdaDark.fg3 : MdaLight.fg3;
    final surface  = isDark ? MdaDark.surface : MdaLight.surface;
    final line     = isDark ? MdaDark.line : MdaLight.line;

    final players    = instance.players;
    final done       = players.where((p) => p.hasContributedToday).toList();
    final total      = players.length;
    final doneCount  = done.length;

    // Show max 4 avatars, rest as "+N"
    const maxAvatars = 4;
    final shown = done.take(maxAvatars).toList();
    final overflow = (doneCount - maxAvatars).clamp(0, 999);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: MdaRadius.bMd,
          border: Border.all(color: line),
        ),
        child: Row(
          children: [
            // Stacked avatars
            if (shown.isNotEmpty)
              SizedBox(
                width: shown.length * 22.0 + (overflow > 0 ? 24.0 : 0),
                height: 28,
                child: Stack(
                  children: [
                    for (int i = 0; i < shown.length; i++)
                      Positioned(
                        left: i * 22.0,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: surface, width: 2),
                          ),
                          child: MdaAvatar(
                            pigmentKey: shown[i].avatarPigment,
                            initial: shown[i].pseudo.isNotEmpty ? shown[i].pseudo[0] : '?',
                            size: 24,
                          ),
                        ),
                      ),
                    if (overflow > 0)
                      Positioned(
                        left: shown.length * 22.0,
                        child: Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? MdaDark.surfaceSunk : MdaLight.surfaceSunk,
                            border: Border.all(color: surface, width: 2),
                          ),
                          child: Center(
                            child: Text('+$overflow',
                              style: TextStyle(fontSize: 9, color: fg3,
                                  fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (shown.isNotEmpty) const SizedBox(width: 10),
            Expanded(
              child: Text(
                doneCount == 0
                    ? 'Personne n\'a encore contribué aujourd\'hui'
                    : doneCount == total
                        ? 'Tout le groupe a contribué aujourd\'hui !'
                        : '$doneCount/$total joueur${total > 2 ? 's ont' : ' a'} contribué aujourd\'hui',
                style: MdaType.caption(color: doneCount == total ? MdaColors.ok : fg2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
