// collection_screen.dart — musée personnel : œuvres débloquées / verrouillées.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../engine/mosaic_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../models/game_models.dart';
import '../../providers/data_providers.dart';
import '../../theme/colors.dart';
import '../../theme/palette.dart';
import '../../theme/theme.dart';
import '../../theme/typography.dart';
import '../../widgets/game_widgets.dart';
import '../../widgets/mda_icon.dart';
import '../../widgets/primitives.dart';

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context);
    final items = ref.watch(collectionProvider).valueOrNull ?? const <CollectionItem>[];
    final unlocked = items.where((g) => g.unlocked).length;

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        TopBar(
          overline: t.worksAcquired(unlocked),
          title: t.tabCollection,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          child: Text(t.collectionLead, style: MdaType.serif(size: 15.5, italic: true, height: 1.3, color: context.fg2)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.62,
            children: [for (final g in items) _GalleryCard(item: g)],
          ),
        ),
      ],
    );
  }
}

class _GalleryCard extends StatelessWidget {
  final CollectionItem item;
  const _GalleryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      DecoratedBox(
        decoration: const BoxDecoration(borderRadius: MdaRadius.bSm, boxShadow: MdaShadows.md),
        child: item.art != null
            ? _MiniMosaic(art: item.art!)
            : _MiniArt(seed: item.seed, unlocked: item.unlocked),
      ),
      const SizedBox(height: 9),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Cartel(title: item.title, artist: item.artist, year: item.year, locked: !item.unlocked)),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Overline(t.weekShort(item.week), fontSize: 10),
        ),
      ]),
    ]);
  }
}

/// Vignette fidèle : peint les vraies cellules de l'œuvre (plat, sans photos).
class _MiniMosaic extends StatelessWidget {
  final ArtworkData art;
  const _MiniMosaic({required this.art});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: ClipRRect(
        borderRadius: MdaRadius.bSm,
        child: CustomPaint(painter: _CellsPainter(art), child: const SizedBox.expand()),
      ),
    );
  }
}

class _CellsPainter extends CustomPainter {
  final ArtworkData art;
  _CellsPainter(this.art);

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width / art.cols;
    final ch = size.height / art.rows;
    final paint = Paint();
    for (final c in art.cells) {
      paint.color = kVariants[c.variant]?.color ?? MdaColors.cream200;
      canvas.drawRect(Rect.fromLTWH(c.col * cw, c.row * ch, cw + 0.5, ch + 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_CellsPainter old) => old.art != art;
}

class _MiniArt extends StatelessWidget {
  final List<String> seed;
  final bool unlocked;
  const _MiniArt({required this.seed, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: ClipRRect(
        borderRadius: MdaRadius.bSm,
        child: Stack(children: [
          GridView.count(
            crossAxisCount: 4,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 1.5,
            crossAxisSpacing: 1.5,
            children: [
              for (var i = 0; i < 20; i++)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: unlocked ? fillGradient(MdaColors.pig(seed[i % seed.length]), i) : null,
                    color: unlocked ? null : MdaColors.cream200,
                  ),
                ),
            ],
          ),
          if (!unlocked)
            Positioned.fill(
              child: Container(
                color: context.paper.withValues(alpha: 0.4),
                child: const Center(child: MdaIcon('lock', size: 20, color: MdaColors.ink500)),
              ),
            ),
        ]),
      ),
    );
  }
}
