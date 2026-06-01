import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/artwork.dart';
import '../../models/instance.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../theme/typography.dart';
import '../../widgets/mda_button.dart';
import '../../widgets/mosaic.dart';
import '../../widgets/overline.dart';

class RevealScreen extends StatefulWidget {
  final Artwork artwork;
  final VoidCallback onShare;
  final VoidCallback onContinue;

  const RevealScreen({super.key, required this.artwork, required this.onShare, required this.onContinue});

  @override
  State<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends State<RevealScreen> with TickerProviderStateMixin {
  // Phase 0: mosaic stagger reveal
  // Phase 1: wall label appears
  // Phase 2 (if hdUrl): crossfade to HD photo
  int   _phase   = 0;
  bool  _sharing = false;
  final _mosaicKey = GlobalKey();

  late final AnimationController _hdCtrl = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 2500));
  late final Animation<double> _hdFade = CurvedAnimation(parent: _hdCtrl, curve: Curves.easeInOut);

  @override
  void initState() {
    super.initState();
    // Phase 1: wall label after stagger
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _phase = 1);
    });
    // Phase 2: HD reveal after label appears (only if hdUrl exists)
    if (widget.artwork.hdUrl != null) {
      Future.delayed(const Duration(milliseconds: 4500), () {
        if (mounted) { setState(() => _phase = 2); _hdCtrl.forward(); }
      });
    }
  }

  @override
  void dispose() { _hdCtrl.dispose(); super.dispose(); }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final bytes = await _captureMosaic();
      if (bytes == null) { widget.onShare(); return; }
      final dir  = await getTemporaryDirectory();
      final file = File('${dir.path}/mda_mosaic.png');
      await file.writeAsBytes(bytes);
      final a    = widget.artwork;
      final text = a.title != null
          ? '${a.title}${a.artist != null ? ' · ${a.artist}' : ''}\nMémoire de l\'art'
          : 'Notre œuvre du mois — Mémoire de l\'art';
      await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')], text: text);
      widget.onShare();
    } catch (_) { widget.onShare(); }
    finally { if (mounted) setState(() => _sharing = false); }
  }

  Future<Uint8List?> _captureMosaic() async {
    final boundary = _mosaicKey.currentContext
        ?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image    = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper  = isDark ? MdaDark.paper : MdaLight.paper;
    final fg1    = isDark ? MdaDark.fg1   : MdaLight.fg1;
    final fg2    = isDark ? MdaDark.fg2   : MdaLight.fg2;
    final line   = isDark ? MdaDark.line  : MdaLight.line;
    final a      = widget.artwork;

    return Scaffold(
      backgroundColor: paper,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Center(child: MdaOverline('Fin du mois · L\'œuvre est complète')),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
                child: Column(
                  children: [
                    // ── Mosaic / HD stack ─────────────────────────
                    RepaintBoundary(
                      key: _mosaicKey,
                      child: Container(
                        decoration: BoxDecoration(
                          color: paper, borderRadius: MdaRadius.bMd,
                          border: Border.all(color: line), boxShadow: MdaShadows.lg,
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Stack(
                          children: [
                            // Always present: staggered mosaic reveal
                            MosaicWidget(
                              artwork: a, revealAll: true,
                              showPulse: false, gap: 2, radius: 2.5,
                            ),
                            // HD photo fades over the mosaic
                            if (a.hdUrl != null)
                              FadeTransition(
                                opacity: _hdFade,
                                child: CachedNetworkImage(
                                  imageUrl: a.hdUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  placeholder: (_, __) => const SizedBox.shrink(),
                                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // ── HD label ──────────────────────────────────
                    if (_phase >= 2 && a.hdUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.hd_rounded, size: 16, color: fg2),
                            const SizedBox(width: 6),
                            Text('Vue originale', style: MdaType.caption(color: fg2)),
                          ],
                        ),
                      ),

                    // ── Wall label ────────────────────────────────
                    AnimatedOpacity(
                      opacity: _phase >= 1 ? 1.0 : 0.0,
                      duration: MdaDuration.slow, curve: MdaCurve.easeOut,
                      child: AnimatedSlide(
                        offset: _phase >= 1 ? Offset.zero : const Offset(0, 0.08),
                        duration: MdaDuration.slow, curve: MdaCurve.easeOut,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 28),
                          child: Column(
                            children: [
                              if (a.title != null)
                                Text(a.title!,
                                  style: MdaType.display(color: fg1).copyWith(
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500, fontSize: 28),
                                  textAlign: TextAlign.center),
                              if (a.artist != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  '${a.artist}${a.year != 0 ? ' — ${a.year}' : ''}',
                                  style: MdaType.serifItalic(color: fg2).copyWith(fontSize: 16),
                                  textAlign: TextAlign.center),
                              ],
                              if (a.description != null) ...[
                                const SizedBox(height: 16),
                                Text(a.description!,
                                  style: MdaType.bodySm(color: fg2).copyWith(height: 1.6),
                                  textAlign: TextAlign.center),
                              ],
                              const SizedBox(height: 28),
                              MdaButton(
                                label: _sharing ? 'Partage en cours…' : 'Partager l\'œuvre',
                                icon: Icons.share_outlined,
                                onPressed: _sharing ? null : _share),
                              const SizedBox(height: 12),
                              MdaButton(
                                label: 'Retour',
                                variant: MdaButtonVariant.ghost,
                                onPressed: widget.onContinue),
                            ],
                          ),
                        ),
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

// Helper: should the reveal screen be shown?
bool shouldReveal(Artwork artwork, Instance instance) {
  final allFilled = artwork.zones.values.every((z) => z.isFilled);
  return allFilled || instance.isMonthComplete;
}
