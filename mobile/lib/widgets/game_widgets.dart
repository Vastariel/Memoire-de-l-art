// game_widgets.dart — composants spécifiques au jeu (port de ui.jsx v2).

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../engine/mosaic_engine.dart';
import '../l10n/app_localizations.dart';
import '../models/game_models.dart';
import '../theme/colors.dart';
import '../theme/palette.dart';
import '../theme/theme.dart';
import '../theme/typography.dart';
import 'mda_icon.dart';
import 'primitives.dart';

// ── 7 points lun→dim ────────────────────────────────────────────────────────
class DayDots extends StatelessWidget {
  final int done;
  final int? today;
  final bool labels;
  final String lang;
  const DayDots({super.key, this.done = 0, this.today, this.labels = false, this.lang = 'fr'});

  @override
  Widget build(BuildContext context) {
    final letters = lang == 'en'
        ? ['M', 'T', 'W', 'T', 'F', 'S', 'S']
        : ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < 7; i++) ...[
        if (i > 0) const SizedBox(width: 7),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (i + 1) <= done ? context.accent : MdaColors.cream200,
              border: (i + 1) == today ? Border.all(color: context.accent, width: 2.5) : Border.all(color: context.line),
            ),
          ),
          if (labels) ...[
            const SizedBox(height: 4),
            Text(letters[i],
                style: MdaType.sans(size: 10, weight: FontWeight.w600, color: (i + 1) == today ? context.accent : context.fg3)),
          ],
        ]),
      ],
    ]);
  }
}

// ── Score de matching circulaire ────────────────────────────────────────────
class MatchScore extends StatelessWidget {
  final int value;
  final double size;
  final String? label;
  final double strokeWidth;
  const MatchScore({super.key, required this.value, this.size = 64, this.label, this.strokeWidth = 6});

  @override
  Widget build(BuildContext context) {
    final col = value >= 80 ? MdaColors.match : (value >= 55 ? MdaColors.gold : MdaColors.warn);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(value / 100, col, strokeWidth, MdaColors.cream200),
          child: Center(
            child: Text('$value',
                style: MdaType.serif(size: size * 0.30, color: context.fg1)
                    .copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
          ),
        ),
      ),
      if (label != null && label!.isNotEmpty) ...[
        const SizedBox(height: 5),
        Overline(label!, fontSize: 10),
      ],
    ]);
  }
}

class _RingPainter extends CustomPainter {
  final double t;
  final Color color;
  final double sw;
  final Color track;
  _RingPainter(this.t, this.color, this.sw, this.track);

  @override
  void paint(Canvas canvas, Size size) {
    final r = (size.width - sw) / 2;
    final c = size.center(Offset.zero);
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..color = track;
    canvas.drawCircle(c, r, bg);
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, 2 * math.pi * t.clamp(0, 1), false, fg);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t || old.color != color;
}

// ── Badge partagée / séparée (impossible à confondre) ───────────────────────
class InstanceBadge extends StatelessWidget {
  final InstanceMode mode;
  final bool big;
  const InstanceBadge({super.key, required this.mode, this.big = false});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final shared = mode.isShared;
    final col = shared ? MdaColors.shared : MdaColors.separate;
    final label = shared ? l.modeSharedTitle : l.modeSeparateTitle;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: big ? 14 : 10, vertical: big ? 7 : 4),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.11),
        borderRadius: MdaRadius.bPill,
        border: Border.all(color: col.withValues(alpha: 0.33)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        MdaIcon(shared ? 'layers' : 'camera', size: big ? 15 : 13, color: col, strokeWidth: 2.1),
        const SizedBox(width: 7),
        Text(label.toUpperCase(),
            style: MdaType.sans(size: big ? 13 : 11.5, weight: FontWeight.w700, letterSpacing: 0.5, color: col)),
      ]),
    );
  }
}

// ── Hero : famille du jour + MA variante ────────────────────────────────────
class VariantBadge extends StatelessWidget {
  final String family;
  final String variant;
  final String lang;
  const VariantBadge({super.key, required this.family, required this.variant, required this.lang});

  @override
  Widget build(BuildContext context) {
    final f = kFamilies[family]!;
    final v = kVariants[variant]!;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 18, 12),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: MdaRadius.bLg,
        border: Border.all(color: context.line),
        boxShadow: MdaShadows.md,
      ),
      child: Row(children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(clipBehavior: Clip.none, children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: fillGradient(v.color, 7),
                border: Border.all(color: const Color(0x1A000000)),
              ),
            ),
            Positioned(
              right: -5,
              bottom: -5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(8), boxShadow: MdaShadows.sm),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  for (final vk in f.variants) ...[
                    if (vk != f.variants.first) const SizedBox(width: 2),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: MdaColors.pig(vk),
                        borderRadius: BorderRadius.circular(2),
                        border: vk == variant ? Border.all(color: context.fg1, width: 1.5) : null,
                      ),
                    ),
                  ],
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Overline(L10n.of(context).familyOfDay(f.name(lang))),
            const SizedBox(height: 2),
            Text(v.name(lang), style: MdaType.serif(size: 23, height: 1.05, color: context.fg1)),
            Text(L10n.of(context).variantToPhotograph, style: MdaType.sans(size: 12.5, color: context.fg2)),
          ]),
        ),
      ]),
    );
  }
}

// ── Cartel de musée ─────────────────────────────────────────────────────────
class Cartel extends StatelessWidget {
  final String title;
  final String artist;
  final int? year;
  final bool locked;
  const Cartel({super.key, required this.title, required this.artist, this.year, this.locked = false});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(locked ? l.lockedWork : title,
          style: MdaType.serif(size: 14, italic: true, height: 1.2, color: locked ? context.fg3 : context.fg1)),
      Text(locked ? l.incompleteWeek : '$artist${year != null ? ' · $year' : ''}',
          style: MdaType.sans(size: 11, letterSpacing: 0.2, color: context.fg2)),
    ]);
  }
}

// ── Ligne de classement ─────────────────────────────────────────────────────
class LeaderRow extends StatelessWidget {
  final int rank;
  final LeaderEntry entry;
  const LeaderRow({super.key, required this.rank, required this.entry});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final medal = rank <= 3;
    final medalCol = rank == 1 ? MdaColors.gold : (rank == 2 ? const Color(0xFF9AA1A8) : const Color(0xFFB5743A));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: entry.you ? MdaColors.clay100 : context.surface,
        borderRadius: MdaRadius.bMd,
        border: Border.all(color: entry.you ? Colors.transparent : context.line),
      ),
      child: Row(children: [
        SizedBox(
          width: 26,
          child: Text('$rank',
              textAlign: TextAlign.center,
              style: MdaType.serif(size: 18, weight: medal ? FontWeight.w600 : FontWeight.w400, color: medal ? medalCol : context.fg3)),
        ),
        const SizedBox(width: 12),
        MdaAvatar(pig: entry.pig, initial: entry.pseudo[0], size: 38, ring: rank == 1 ? 1 : 0),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text.rich(TextSpan(children: [
              TextSpan(text: entry.pseudo, style: MdaType.sans(size: 15, weight: FontWeight.w600, color: context.fg1)),
              if (entry.you)
                TextSpan(text: ' · ${l.labelYou}', style: MdaType.sans(size: 15, weight: FontWeight.w500, color: context.fg3)),
            ])),
            const SizedBox(height: 2),
            Row(children: [
              if (entry.streak > 0) ...[
                const MdaIcon('flame', size: 12, color: MdaColors.gold, strokeWidth: 2),
                const SizedBox(width: 3),
                Text('${entry.streak}', style: MdaType.sans(size: 12, weight: FontWeight.w700, color: MdaColors.gold)),
                const SizedBox(width: 8),
              ],
              Text(l.nPhotos(entry.photos), style: MdaType.sans(size: 12, color: context.fg2)),
            ]),
          ]),
        ),
        Text.rich(TextSpan(children: [
          TextSpan(text: '${entry.points}', style: MdaType.serif(size: 17, color: context.fg1)),
          TextSpan(text: ' ${l.unitPts}', style: MdaType.sans(size: 11, weight: FontWeight.w600, color: context.fg3)),
        ])),
      ]),
    );
  }
}

// ── Tampons (pas d'emoji) ───────────────────────────────────────────────────
class StampDef {
  final String id;
  final String pig;
  const StampDef(this.id, this.pig);
  String label(L10n l) => switch (id) {
        'bravo' => l.stampBravo,
        'audacieux' => l.stampBold,
        'trouvaille' => l.stampFind,
        'pile' => l.stampSpotOn,
        _ => l.stampLight,
      };
}

const List<StampDef> kStamps = [
  StampDef('bravo', 'garance'),
  StampDef('audacieux', 'cobalt'),
  StampDef('trouvaille', 'veronese'),
  StampDef('pile', 'safran'),
  StampDef('lumiere', 'ambre'),
];

class ReactionStamp extends StatelessWidget {
  final StampDef stamp;
  final bool active;
  final VoidCallback? onTap;
  const ReactionStamp({super.key, required this.stamp, this.active = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final hex = MdaColors.pig(stamp.pig);
    final fg = active ? Colors.white : shade(hex, -0.25);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: active ? hex : hex.withValues(alpha: 0.12),
          borderRadius: MdaRadius.bPill,
          boxShadow: active ? MdaShadows.sm : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: active ? Colors.white : hex)),
          const SizedBox(width: 7),
          Text(stamp.label(L10n.of(context)),
              style: MdaType.sans(size: 13, weight: FontWeight.w700, letterSpacing: 0.2, color: fg)),
        ]),
      ),
    );
  }
}

class StampRow extends StatefulWidget {
  const StampRow({super.key});
  @override
  State<StampRow> createState() => _StampRowState();
}

class _StampRowState extends State<StampRow> {
  final Set<String> _active = {};
  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final s in kStamps)
        ReactionStamp(
          stamp: s,
          active: _active.contains(s.id),
          onTap: () => setState(() => _active.contains(s.id) ? _active.remove(s.id) : _active.add(s.id)),
        ),
    ]);
  }
}

// ── QR (qr_flutter) ─────────────────────────────────────────────────────────
/// Fragment vitrail d'une cellule : montre la portion de la photo famille
/// correspondant à la position de la cellule (cf. cellPhotoAlignment).
class VitrailFragment extends StatelessWidget {
  final ArtCell cell;
  final BorderRadius radius;
  const VitrailFragment(this.cell, {super.key, this.radius = const BorderRadius.all(Radius.circular(6))});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final s = c.maxWidth;
      return ClipRRect(
        borderRadius: radius,
        child: OverflowBox(
          maxWidth: s * kCols,
          maxHeight: s * kRows,
          alignment: cellPhotoAlignment(cell),
          child: SizedBox(
            width: s * kCols,
            height: s * kRows,
            child: Stack(children: [
              for (final g in photoLayers(cell.family))
                DecoratedBox(decoration: BoxDecoration(gradient: g), child: const SizedBox.expand()),
            ]),
          ),
        ),
      );
    });
  }
}

class MdaQr extends StatelessWidget {
  final String data;
  final double size;
  const MdaQr(this.data, {super.key, this.size = 150});

  @override
  Widget build(BuildContext context) {
    return QrImageView(
      data: data,
      size: size,
      backgroundColor: Colors.white,
      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: MdaColors.ink900),
      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: MdaColors.ink900),
    );
  }
}
