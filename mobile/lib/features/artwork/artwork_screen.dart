// artwork_screen.dart — Œuvre : zoom plat↔vitrail + détail bloc (le « wow »).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../engine/mosaic_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/api_provider.dart';
import '../../providers/data_providers.dart';
import '../../providers/game_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/colors.dart';
import '../../theme/palette.dart';
import '../../theme/theme.dart';
import '../../theme/typography.dart';
import '../../widgets/game_widgets.dart';
import '../../widgets/mda_icon.dart';
import '../../widgets/mosaic.dart';
import '../../widgets/primitives.dart';

class ArtworkScreen extends ConsumerStatefulWidget {
  const ArtworkScreen({super.key});
  @override
  ConsumerState<ArtworkScreen> createState() => _ArtworkScreenState();
}

class _ArtworkScreenState extends ConsumerState<ArtworkScreen> {
  double _zoom = 0;
  final _tc = TransformationController();
  double _scale = 1.0;

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  void _showBlock(ArtCell cell, String lang) {
    final v = kVariants[cell.variant]!;
    final fills = ref.read(instanceFillProvider(ref.read(gameProvider).activeInstanceId)).valueOrNull ??
        const <String, FilledInfo>{};
    final c = fills[cell.variant] ?? const FilledInfo('—', 80, null);
    final t = L10n.of(context);
    showMdaSheet(context, builder: (ctx) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 96, height: 96, child: VitrailFragment(cell, radius: BorderRadius.circular(16))),
          const SizedBox(width: 15),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Overline('${t.variantLabel} · ${kFamilies[v.family]!.name(lang)}'),
              const SizedBox(height: 4),
              Text(v.name(lang), style: MdaType.serif(size: 23, weight: FontWeight.w500, color: ctx.fg1)),
              const SizedBox(height: 8),
              Row(children: [
                MdaAvatar(pig: cell.variant, initial: c.pseudo.isNotEmpty ? c.pseudo[0] : '—', size: 30),
                const SizedBox(width: 9),
                Text(c.pseudo, style: MdaType.sans(size: 14, weight: FontWeight.w700, color: ctx.fg1)),
              ]),
            ]),
          ),
          MatchScore(value: c.score, size: 56, strokeWidth: 5, label: ''),
        ]),
        const SizedBox(height: 18),
        Overline(t.leaveAStamp),
        const SizedBox(height: 9),
        StampRow(
          onToggle: c.contributionId == null
              ? null
              : (id, _) => ref.read(apiClientProvider).reactToContribution(c.contributionId!, id).catchError((_) {}),
        ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final lang = ref.watch(langProvider);
    final g = ref.watch(gameProvider);
    ref.watch(instanceFillProvider(g.activeInstanceId)); // prefetch block authors
    final artwork = ref.watch(artworkDataProvider).valueOrNull;
    final photos = ref.watch(instancePhotoUrlsProvider(g.activeInstanceId)).valueOrNull ?? const {};
    final filledCount = g.filled.length;

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        TopBar(
          overline: t.artworkOverline(g.week),
          title: t.theArtwork,
          trailing: IconTapButton('share', onTap: () => context.push('/reveal')),
        ),
        // cadre + œuvre zoomable
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 18),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: context.surface, borderRadius: MdaRadius.bLg, border: Border.all(color: context.line), boxShadow: MdaShadows.md),
          child: Column(children: [
            ClipRRect(
              borderRadius: MdaRadius.bMd,
              child: Stack(children: [
                InteractiveViewer(
                  transformationController: _tc,
                  minScale: 1.0,
                  maxScale: 8.0,
                  boundaryMargin: const EdgeInsets.all(40),
                  panEnabled: true,
                  scaleEnabled: true,
                  onInteractionUpdate: (_) {
                    final s = _tc.value.getMaxScaleOnAxis();
                    if ((s - _scale).abs() > 0.01) setState(() => _scale = s);
                  },
                  child: MosaicWidget(
                    filled: g.filled,
                    todayFamily: g.todayFamily,
                    vitrail: _zoom,
                    pulse: _zoom < 0.3 && _scale < 1.05,
                    artwork: artwork,
                    photos: photos,
                    onTapCell: (cell, isFilled) {
                      if (isFilled) _showBlock(cell, lang);
                    },
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0x6B000000), borderRadius: BorderRadius.circular(999)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      MdaIcon(_zoom > 0.5 ? 'eye' : 'frame', size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(_zoom > 0.5 ? t.renderGlass : t.renderFlat,
                          style: MdaType.sans(size: 11, weight: FontWeight.w600, letterSpacing: 0.4, color: Colors.white)),
                    ]),
                  ),
                ),
                if (_scale > 1.05)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _tc.value = Matrix4.identity();
                        _scale = 1.0;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(color: const Color(0x6B000000), borderRadius: BorderRadius.circular(999)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const MdaIcon('minus', size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text('${_scale.toStringAsFixed(1)}×',
                              style: MdaType.sans(size: 11, weight: FontWeight.w600, letterSpacing: 0.4, color: Colors.white)),
                        ]),
                      ),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 10),
            Row(children: [
              MdaIcon('minus', size: 18, color: context.fg3),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: context.accent,
                    inactiveTrackColor: MdaColors.cream300,
                    thumbColor: context.surface,
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(value: _zoom, onChanged: (v) => setState(() => _zoom = v)),
                ),
              ),
              MdaIcon('plus', size: 18, color: context.fg3),
            ]),
            Text(t.zoomHint, textAlign: TextAlign.center, style: MdaType.sans(size: 12, color: context.fg3)),
          ]),
        ),
        // légende avancement
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(t.familiesCount(filledCount), style: MdaType.serif(size: 22, color: context.fg1)),
              Text(t.coloursThisWeek, style: MdaType.sans(size: 13, color: context.fg2)),
            ]),
            MdaButton(t.actionContribute, variant: MdaBtnVariant.secondary, icon: 'camera', fontSize: 14,
                padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11), onTap: () => context.go('/today')),
          ]),
        ),
        // familles déposées
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final entry in kFamilies.entries)
              _familyChip(entry.value, g.filled.contains(entry.key), entry.key == g.todayFamily, lang, t),
          ]),
        ),
        // carte mystère
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
            decoration: const BoxDecoration(color: MdaColors.clay100, borderRadius: MdaRadius.bMd),
            child: Row(children: [
              const MdaIcon('lock', size: 20, color: MdaColors.clay600),
              const SizedBox(width: 13),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(t.whichArtworkHides, style: MdaType.serif(size: 15.5, italic: true, color: MdaColors.clay600)),
                  Text(g.bet != null ? t.yourBet(g.bet!.title) : t.revealedSunday, style: MdaType.sans(size: 12.5, color: context.fg2)),
                ]),
              ),
              MdaButton(g.bet != null ? t.actionEdit : t.actionBet, variant: MdaBtnVariant.ghost, fontSize: 13.5,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), onTap: () => context.push('/bet')),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _familyChip(FamilyDef f, bool done, bool today, String lang, L10n t) {
    final label = '${f.name(lang)}${today && !done ? ' · ${t.todaySuffix}' : ''}';
    return MdaChip(label, swatch: done ? MdaColors.pig(f.variants[1]) : null, active: done, opacity: done ? 1 : 0.5);
  }
}
