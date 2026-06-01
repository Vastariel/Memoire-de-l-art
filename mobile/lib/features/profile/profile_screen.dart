import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/artwork.dart';
import '../../models/instance.dart';
import '../../models/zone.dart';
import '../../services/api_client.dart';
import '../../services/session_manager.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../theme/typography.dart';
import '../../widgets/avatar.dart';
import '../../widgets/mosaic.dart';
import '../../widgets/overline.dart';

class PastArtwork {
  final String month;
  final Artwork artwork;
  const PastArtwork({required this.month, required this.artwork});
}

class ProfileScreen extends StatefulWidget {
  final Player me;
  final Instance instance;
  final List<Zone> myContributions;
  final void Function(String newPseudo)? onRenamed;

  const ProfileScreen({
    super.key,
    required this.me,
    required this.instance,
    required this.myContributions,
    this.onRenamed,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool   _editing        = false;
  bool   _saving         = false;
  bool   _historyLoading = true;
  List<PastArtwork> _pastArtworks = [];

  late final _pseudoCtrl = TextEditingController(text: widget.me.pseudo);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() { _pseudoCtrl.dispose(); super.dispose(); }

  Future<void> _loadHistory() async {
    try {
      final client = await ApiClient.get();
      final raw    = await client.fetchHistory();
      final parsed = raw.map((m) {
        final a     = Artwork.fromJson(m);
        final month = m['month'] as int? ?? 0;
        return PastArtwork(
          month:   '${Instance.monthLabel(month)} ${a.year}',
          artwork: a,
        );
      }).toList();
      if (mounted) setState(() { _pastArtworks = parsed; _historyLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  Future<void> _savePseudo() async {
    final newPseudo = _pseudoCtrl.text.trim();
    if (newPseudo.isEmpty || newPseudo == widget.me.pseudo) {
      setState(() => _editing = false);
      return;
    }
    setState(() => _saving = true);
    try {
      final client = await ApiClient.get();
      await client.updatePlayer(pseudo: newPseudo);
      final sm   = SessionManager.instance;
      final curr = sm.current;
      if (curr != null) {
        await sm.addOrUpdate(SavedInstance(
          code:          curr.code,
          name:          curr.name,
          pseudo:        newPseudo,
          avatarPigment: curr.avatarPigment,
          token:         curr.token,
          isSolo:        curr.isSolo,
          isCreator:     curr.isCreator,
        ));
      }
      widget.onRenamed?.call(newPseudo);
      if (mounted) setState(() { _editing = false; _saving = false; });
    } catch (_) {
      widget.onRenamed?.call(newPseudo);
      if (mounted) setState(() { _editing = false; _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper  = isDark ? MdaDark.paper  : MdaLight.paper;
    final fg1    = isDark ? MdaDark.fg1    : MdaLight.fg1;
    final fg2    = isDark ? MdaDark.fg2    : MdaLight.fg2;
    final fg3    = isDark ? MdaDark.fg3    : MdaLight.fg3;
    final line   = isDark ? MdaDark.line   : MdaLight.line;
    final accent = isDark ? MdaDark.accent : MdaLight.accent;
    final me     = widget.me;

    return Scaffold(
      backgroundColor: paper,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 112),
          children: [

            // ── Header ─────────────────────────────────────────────
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MdaAvatar(
                  pigmentKey: me.avatarPigment,
                  initial: me.pseudo.isNotEmpty ? me.pseudo[0] : '?',
                  size: 64,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_editing)
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _pseudoCtrl,
                                autofocus: true,
                                style: MdaType.h2(color: fg1).copyWith(fontSize: 24),
                                decoration: const InputDecoration(
                                  isDense: true, contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                ),
                                textCapitalization: TextCapitalization.words,
                                onSubmitted: (_) => _savePseudo(),
                              ),
                            ),
                            if (_saving)
                              const SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            else ...[
                              GestureDetector(
                                onTap: _savePseudo,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Icon(Icons.check_rounded, color: accent, size: 22)),
                              ),
                              GestureDetector(
                                onTap: () { _pseudoCtrl.text = me.pseudo; setState(() => _editing = false); },
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Icon(Icons.close_rounded, color: fg3, size: 22)),
                              ),
                            ],
                          ],
                        )
                      else
                        Row(
                          children: [
                            Flexible(
                              child: Text(me.pseudo,
                                style: MdaType.h2(color: fg1).copyWith(fontSize: 26)),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() { _editing = true; }),
                              child: Icon(Icons.edit_outlined, size: 18, color: fg3),
                            ),
                          ],
                        ),
                      const SizedBox(height: 3),
                      MdaOverline(
                        '${widget.instance.name.isNotEmpty ? widget.instance.name : widget.instance.code}'
                        ' · ${widget.myContributions.length} contributions',
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── This month photos ───────────────────────────────────
            const SizedBox(height: 24),
            MdaOverline('Mes photos de ${Instance.monthLabel(widget.instance.month).toLowerCase()}'),
            const SizedBox(height: 12),
            widget.myContributions.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? MdaDark.surface : MdaLight.surface,
                      borderRadius: MdaRadius.bMd,
                      border: Border.all(color: line),
                    ),
                    child: Center(
                      child: Text('Tes contributions apparaîtront ici.',
                          style: MdaType.caption(color: fg3)),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.myContributions.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6),
                    itemBuilder: (_, i) {
                      final z       = widget.myContributions[i];
                      final contrib = z.contribution!;
                      final url     = contrib.photoUrl;
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Photo or pigment fallback
                            if (url != null && url.isNotEmpty)
                              _ContribPhoto(url: url, fallbackColor: z.pigment.color)
                            else
                              Container(color: z.pigment.color),
                            // Date overlay
                            Positioned(
                              bottom: 5, left: 7,
                              child: Text(
                                '${contrib.contributedAt.day} ${_monthShort(contrib.contributedAt.month)}',
                                style: TextStyle(
                                  fontFamily: MdaFonts.serif, fontSize: 11,
                                  color: Colors.white,
                                  shadows: const [Shadow(color: Color(0x66000000), blurRadius: 2)],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

            // ── Past artworks ────────────────────────────────────────
            const SizedBox(height: 26),
            const MdaOverline('Œuvres passées'),
            const SizedBox(height: 12),
            if (_historyLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: fg3)),
                ),
              )
            else if (_pastArtworks.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? MdaDark.surface : MdaLight.surface,
                  borderRadius: MdaRadius.bMd,
                  border: Border.all(color: line),
                ),
                child: Center(
                  child: Text('Les œuvres des mois passés apparaîtront ici.',
                      style: MdaType.caption(color: fg3)),
                ),
              )
            else
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _pastArtworks.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (_, i) {
                    final past = _pastArtworks[i];
                    return SizedBox(
                      width: 96,
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: line),
                                  boxShadow: MdaShadows.sm,
                                ),
                                child: MosaicWidget(
                                  artwork: past.artwork,
                                  showPulse: false, gap: 1, radius: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(past.month,
                            style: MdaType.caption(color: fg2).copyWith(fontSize: 12),
                            textAlign: TextAlign.center),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _monthShort(int m) {
    const l = ['','jan','fév','mar','avr','mai','juin','juil','août','sep','oct','nov','déc'];
    return l[m.clamp(1, 12)];
  }
}

// ── Contribution photo (local file or remote URL) ─────────────────────────────

class _ContribPhoto extends StatelessWidget {
  final String url;
  final Color fallbackColor;
  const _ContribPhoto({required this.url, required this.fallbackColor});

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
      errorWidget: (_, __, ___) => fallback,
    );
  }
}
