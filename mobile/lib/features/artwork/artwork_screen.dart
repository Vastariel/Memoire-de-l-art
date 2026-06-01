import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/artwork.dart';
import '../../models/instance.dart';
import '../../models/zone.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../theme/typography.dart';
import '../../widgets/avatar.dart';
import '../../widgets/mosaic.dart';
import '../../widgets/overline.dart';
import '../../widgets/top_bar.dart';

class ArtworkScreen extends StatefulWidget {
  final Artwork artwork;
  final String instanceCode;
  final int month;

  const ArtworkScreen({
    super.key,
    required this.artwork,
    required this.instanceCode,
    required this.month,
  });

  @override
  State<ArtworkScreen> createState() => _ArtworkScreenState();
}

class _ArtworkScreenState extends State<ArtworkScreen> {
  Zone?   _selected;
  double  _photoRevealFactor = 0.0;  // 0–1 driven by zoom (2x→3x)
  bool    _zoomed            = false;

  final _tc = TransformationController();

  @override
  void initState() {
    super.initState();
    _tc.addListener(_onTransform);
  }

  @override
  void dispose() {
    _tc.removeListener(_onTransform);
    _tc.dispose();
    super.dispose();
  }

  void _onTransform() {
    final scale  = _tc.value.getMaxScaleOnAxis();
    final factor = ((scale - 2.0) / 1.0).clamp(0.0, 1.0);
    final nowZoomed = scale >= 1.2;
    if ((factor - _photoRevealFactor).abs() > 0.02 || nowZoomed != _zoomed) {
      setState(() { _photoRevealFactor = factor; _zoomed = nowZoomed; });
    }
  }

  void _resetZoom() {
    _tc.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final paper   = isDark ? MdaDark.paper   : MdaLight.paper;
    final surface = isDark ? MdaDark.surface : MdaLight.surface;
    final fg1     = isDark ? MdaDark.fg1     : MdaLight.fg1;
    final fg2     = isDark ? MdaDark.fg2     : MdaLight.fg2;
    final fg3     = isDark ? MdaDark.fg3     : MdaLight.fg3;
    final line    = isDark ? MdaDark.line    : MdaLight.line;
    final accent  = isDark ? MdaDark.accent  : MdaLight.accent;

    final a = widget.artwork;
    final filled = a.cells.where((c) => a.zones[c.zoneId]?.isFilled ?? false).length;

    return Scaffold(
      backgroundColor: paper,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── Top bar (hidden when zoomed) ──────────────────
                AnimatedOpacity(
                  opacity: _zoomed ? 0.0 : 1.0,
                  duration: MdaDuration.std,
                  child: MdaTopBar(
                    overline: 'Instance ${widget.instanceCode} · ${Instance.monthLabel(widget.month).toLowerCase()}',
                    title: 'L\'œuvre',
                  ),
                ),

                // ── Interactive mosaic ────────────────────────────
                Expanded(
                  child: Padding(
                    padding: _zoomed
                        ? EdgeInsets.zero
                        : const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: AnimatedContainer(
                      duration: MdaDuration.std,
                      curve: MdaCurve.easeOut,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: _zoomed ? BorderRadius.zero : MdaRadius.bLg,
                        border: _zoomed ? null : Border.all(color: line),
                        boxShadow: _zoomed ? null : MdaShadows.md,
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: InteractiveViewer(
                        transformationController: _tc,
                        minScale: 0.8,
                        maxScale: 8.0,
                        boundaryMargin: const EdgeInsets.all(40),
                        child: Padding(
                          padding: _zoomed ? EdgeInsets.zero : const EdgeInsets.all(14),
                          child: MosaicWidget(
                            artwork: a,
                            showPulse: false,
                            photoRevealFactor: _photoRevealFactor,
                            gap: 2.5,
                            radius: 3,
                            onTapZone: (z) => setState(() => _selected = z),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Progress + hint (hidden when zoomed) ─────────
                AnimatedOpacity(
                  opacity: _zoomed ? 0.0 : 1.0,
                  duration: MdaDuration.std,
                  child: IgnorePointer(
                    ignoring: _zoomed,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const MdaOverline('Progression'),
                              const Spacer(),
                              Text('$filled / ${a.totalCells} blocs',
                                style: TextStyle(
                                  fontFamily: MdaFonts.serif, fontSize: 17,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                  color: fg1,
                                )),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: MdaRadius.bPill,
                            child: LinearProgressIndicator(
                              value: a.progress,
                              minHeight: 8,
                              backgroundColor: isDark ? MdaDark.mosaicEmpty : MdaColors.cream200,
                              valueColor: AlwaysStoppedAnimation(accent),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.lock_outline_rounded, size: 16, color: fg3),
                              const SizedBox(width: 8),
                              Text(
                                'Le titre se révèle fin ${Instance.monthLabel(widget.month).toLowerCase()}.',
                                style: MdaType.serifItalic(color: fg2).copyWith(fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Pince deux doigts pour zoomer et voir les photos.',
                            style: MdaType.caption(color: fg3)),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Reset zoom button (visible when zoomed) ───────────
            if (_zoomed)
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: GestureDetector(
                      onTap: _resetZoom,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(0xB0),
                          borderRadius: MdaRadius.bPill,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.zoom_out_rounded, size: 18, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              _photoRevealFactor == 1.0
                                  ? 'Photos visibles'
                                  : _photoRevealFactor > 0
                                      ? '${(_photoRevealFactor * 100).round()}% photos'
                                      : 'Zoom ×${_tc.value.getMaxScaleOnAxis().toStringAsFixed(1)}',
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Zone detail sheet ─────────────────────────────────
            if (_selected != null)
              _ZoneSheet(
                zone: _selected!,
                onClose: () => setState(() => _selected = null),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Zone detail sheet ─────────────────────────────────────────────────────────

class _ZoneSheet extends StatelessWidget {
  final Zone zone;
  final VoidCallback onClose;
  const _ZoneSheet({required this.zone, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? MdaDark.surface    : MdaLight.surface;
    final fg1     = isDark ? MdaDark.fg1        : MdaLight.fg1;
    final fg2     = isDark ? MdaDark.fg2        : MdaLight.fg2;
    final sunken  = isDark ? MdaDark.surfaceSunk : MdaLight.surfaceSunk;

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: const Color(0x6B1C1813),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: MdaShadows.lg,
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? MdaDark.fg3 : MdaLight.fg3,
                      borderRadius: MdaRadius.bPill,
                    ),
                  ),
                  if (zone.isFilled)
                    _FilledDetail(zone: zone, fg1: fg1, fg2: fg2, sunken: sunken)
                  else
                    _EmptyDetail(zone: zone, fg1: fg1, fg2: fg2,
                        line: isDark ? MdaDark.line : MdaLight.line),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilledDetail extends StatelessWidget {
  final Zone zone; final Color fg1, fg2, sunken;
  const _FilledDetail({required this.zone, required this.fg1, required this.fg2, required this.sunken});

  @override
  Widget build(BuildContext context) {
    final contrib  = zone.contribution!;
    final photoUrl = contrib.photoUrl;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Photo thumbnail (or pigment fallback) — tap opens fullscreen
            GestureDetector(
              onTap: hasPhoto ? () => _openFullscreen(context, photoUrl) : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 72, height: 72,
                  child: hasPhoto
                      ? _ZonePhoto(url: photoUrl, fallbackColor: zone.pigment.color)
                      : Container(color: zone.pigment.color),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MdaOverline('Zone · ${zone.pigment.label}'),
                  const SizedBox(height: 3),
                  Text('Peinte par ${contrib.playerPseudo}',
                      style: MdaType.h2(color: fg1).copyWith(fontSize: 22)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text('le ${_fmtDate(contrib.contributedAt)}',
                          style: MdaType.caption(color: fg2)),
                      if (hasPhoto) ...[
                        Text(' · ', style: MdaType.caption(color: fg2)),
                        Icon(Icons.zoom_in_rounded, size: 13, color: fg2),
                        const SizedBox(width: 2),
                        Text('voir la photo', style: MdaType.caption(color: fg2)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: sunken, borderRadius: MdaRadius.bMd),
          child: Row(
            children: [
              MdaAvatar(pigmentKey: contrib.playerAvatar,
                initial: contrib.playerPseudo.isNotEmpty ? contrib.playerPseudo[0] : '?', size: 36),
              const SizedBox(width: 10),
              Expanded(child: Text(
                '${contrib.playerPseudo} a photographié du ${zone.pigment.label.toLowerCase()} dans le monde réel.',
                style: MdaType.bodySm(color: fg2))),
            ],
          ),
        ),
      ],
    );
  }

  void _openFullscreen(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withAlpha(0xE8),
      builder: (_) => _PhotoFullscreen(url: url),
    );
  }

  String _fmtDate(DateTime dt) {
    const m = ['','janvier','février','mars','avril','mai','juin',
                'juillet','août','septembre','octobre','novembre','décembre'];
    return '${dt.day} ${m[dt.month]}';
  }
}

class _EmptyDetail extends StatelessWidget {
  final Zone zone; final Color fg1, fg2, line;
  const _EmptyDetail({required this.zone, required this.fg1, required this.fg2, required this.line});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: MdaColors.cream200, border: Border.all(color: line, width: 1.5),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MdaOverline('Zone · ${zone.pigment.label}'),
              const SizedBox(height: 4),
              Text('Pas encore remplie', style: MdaType.h2(color: fg1).copyWith(fontSize: 22)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(width: 12, height: 12,
                    decoration: BoxDecoration(color: zone.pigment.color, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(width: 8),
                  Text('attend une photo ${zone.pigment.label.toLowerCase()}',
                      style: MdaType.caption(color: fg2)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Zone contribution photo ───────────────────────────────────────────────────

class _ZonePhoto extends StatelessWidget {
  final String url;
  final Color fallbackColor;
  const _ZonePhoto({required this.url, required this.fallbackColor});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(color: fallbackColor);
    if (!url.startsWith('http')) {
      return Image.file(File(url), fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback);
    }
    return CachedNetworkImage(
      imageUrl: url, fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, __) => fallback,
      errorWidget:  (_, __, ___) => fallback,
    );
  }
}

// ── Fullscreen photo viewer ───────────────────────────────────────────────────

class _PhotoFullscreen extends StatelessWidget {
  final String url;
  const _PhotoFullscreen({required this.url});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    // Square crop: cover the 1:1 frame
    Widget squareImage(Widget child) => SizedBox(
      width: w, height: w,
      child: ClipRect(child: child),
    );

    final image = squareImage(
      url.startsWith('http')
          ? CachedNetworkImage(
              imageUrl: url,
              width: w, height: w,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 200),
              placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(color: Colors.white54)),
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            )
          : Image.file(File(url),
              width: w, height: w,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink()),
    );

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 6.0,
                  child: Center(child: image),
                ),
              ),
              Positioned(
                top: 8, right: 12,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(0x99),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
