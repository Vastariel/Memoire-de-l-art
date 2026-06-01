import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/artwork.dart';
import '../../models/zone.dart';
import '../../providers/camera_provider.dart';
import '../../services/api_client.dart';
import '../../services/color_analyzer.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../theme/typography.dart';
import '../../widgets/mosaic.dart';
import '../../widgets/mda_button.dart';
import '../../widgets/top_bar.dart';

class ConfirmScreen extends StatefulWidget {
  final Artwork artwork;
  final Zone todayZone;
  final CaptureResult matchResult;
  final VoidCallback onDone;
  final VoidCallback onViewGroup;

  const ConfirmScreen({
    super.key,
    required this.artwork,
    required this.todayZone,
    required this.matchResult,
    required this.onDone,
    required this.onViewGroup,
  });

  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> {
  String? _hint;

  @override
  void initState() {
    super.initState();
    _loadHint();
  }

  Future<void> _loadHint() async {
    try {
      final client = await ApiClient.get();
      final hint   = await client.fetchHint();
      if (mounted && hint != null) setState(() => _hint = hint);
    } catch (_) {}
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
    final good    = widget.matchResult.verdict == ColorVerdict.perfect || widget.matchResult.verdict == ColorVerdict.correct;

    return Scaffold(
      backgroundColor: paper,
      body: SafeArea(
        child: Column(
          children: [
            const MdaTopBar(overline: 'Ta contribution', title: 'Bien joué'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  children: [
                    // ── Artwork with revealed zone ─────────────────
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: MdaRadius.bLg,
                        border: Border.all(color: line),
                        boxShadow: MdaShadows.md,
                      ),
                      child: MosaicWidget(
                        artwork: widget.artwork,
                        revealZoneId: widget.todayZone.id,
                        showPulse: false,
                        gap: 2.5,
                        radius: 3,
                      ),
                    ),

                    // ── Captured photo thumbnail ───────────────────
                    if (widget.matchResult.photoPath.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: MdaRadius.bMd,
                          border: Border.all(color: line),
                          boxShadow: MdaShadows.sm,
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Image.file(
                          File(widget.matchResult.photoPath),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),

                    // ── Match quality row ──────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: MdaRadius.bMd,
                              border: Border.all(color: line),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 30, height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: good ? MdaColors.ok : MdaColors.warn,
                                  ),
                                  child: Icon(
                                    good ? Icons.check_rounded : Icons.info_outline_rounded,
                                    size: 18, color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        good ? 'Belle correspondance' : 'Correspondance correcte',
                                        style: MdaType.title(color: fg1).copyWith(fontSize: 15),
                                      ),
                                      Text(
                                        'Ta photo rejoint la zone ${widget.todayZone.pigment.label.toLowerCase()}.',
                                        style: MdaType.caption(color: fg2),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: widget.onViewGroup,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.group_outlined, size: 20, color: accent),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Voir les contributions du jour',
                                      style: MdaType.title(color: fg1).copyWith(fontSize: 15),
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded, size: 18, color: fg3),
                                ],
                              ),
                            ),
                          ),

                          // ── Indice de l'admin ──────────────────────
                          if (_hint != null) ...[
                            const SizedBox(height: 16),
                            AnimatedOpacity(
                              opacity: 1.0,
                              duration: MdaDuration.slow,
                              curve: MdaCurve.easeOut,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                                decoration: BoxDecoration(
                                  color: isDark ? MdaDark.surface : MdaLight.surface,
                                  borderRadius: MdaRadius.bMd,
                                  border: Border.all(color: accent.withAlpha(0x55)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.lightbulb_outline_rounded,
                                        size: 18, color: accent),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Indice', style: MdaType.overline(color: accent)),
                                          const SizedBox(height: 4),
                                          Text(_hint!,
                                              style: MdaType.serifItalic(color: fg1)
                                                  .copyWith(fontSize: 15, height: 1.5)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),
                          MdaButton(label: 'Terminer', expand: true, onPressed: widget.onDone),
                        ],
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
