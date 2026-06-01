import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
// ignore_for_file: unused_import
import '../../data/artist_names.dart';
import '../../models/artwork.dart';
import '../../models/zone.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../theme/typography.dart';
import '../../widgets/mosaic.dart';
import '../../widgets/mda_button.dart';
import '../../widgets/overline.dart';

// onJoin: code is null → create new instance. onSolo: local-only, no server.
class OnboardingScreen extends StatefulWidget {
  final void Function(String? code, String pseudo, String name) onJoin;
  final void Function(String pseudo, String? artworkJson) onSolo;
  // When true, the Solo tab is hidden (only one solo instance allowed).
  final bool hasSolo;

  const OnboardingScreen({
    super.key,
    required this.onJoin,
    required this.onSolo,
    this.hasSolo = false,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _code = '';
  final _pseudoCtrl    = TextEditingController();
  final _nameCtrl      = TextEditingController();
  final _artworkCtrl   = TextEditingController(); // for pasted JSON in solo mode
  bool  _showArtwork   = false;
  static const _codeLength = 6;

  late final List<String> _suggestions = randomArtistSuggestions(4);

  bool get _canJoin   => _code.length >= 4 && _pseudoCtrl.text.trim().isNotEmpty;
  bool get _canCreate => _pseudoCtrl.text.trim().isNotEmpty;
  bool get _canSolo   => _pseudoCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: widget.hasSolo ? 2 : 3, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    _pseudoCtrl.dispose();
    _nameCtrl.dispose();
    _artworkCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final pseudo = _pseudoCtrl.text.trim();
    if (pseudo.isEmpty) return;
    final name   = _nameCtrl.text.trim();
    switch (_tab.index) {
      case 0: // Rejoindre
        if (!_canJoin) return;
        widget.onJoin(_code, pseudo, name.isEmpty ? _code : name);
      case 1: // Créer
        widget.onJoin(null, pseudo, name);
      case 2: // Solo
        final json = _artworkCtrl.text.trim();
        widget.onSolo(pseudo, json.isEmpty ? null : json);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final paper    = isDark ? MdaDark.paper    : MdaLight.paper;
    final fg1      = isDark ? MdaDark.fg1      : MdaLight.fg1;
    final fg2      = isDark ? MdaDark.fg2      : MdaLight.fg2;
    final fg3      = isDark ? MdaDark.fg3      : MdaLight.fg3;
    final line     = isDark ? MdaDark.line     : MdaLight.line;
    final surface  = isDark ? MdaDark.surface  : MdaLight.surface;
    final accent   = isDark ? MdaDark.accent   : MdaLight.accent;

    return Scaffold(
      backgroundColor: paper,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Logo + heading ─────────────────────────────────
              const SizedBox(height: 8),
              Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: MdaShadows.lg,
                ),
                clipBehavior: Clip.hardEdge,
                child: SvgPicture.asset(
                  'assets/images/app-icon.svg',
                  width: 110, height: 110,
                ),
              ),
              const SizedBox(height: 10),
              Text('Mémoire de l\'art',
                style: MdaType.h1(color: fg1), textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                'Une couleur par jour, une œuvre par mois.',
                style: MdaType.serifItalic(color: fg2).copyWith(fontSize: 16),
                textAlign: TextAlign.center,
              ),

              // ── Blurred mosaic teaser ──────────────────────────
              const SizedBox(height: 26),
              Container(
                decoration: BoxDecoration(
                  borderRadius: MdaRadius.bLg,
                  border: Border.all(color: line),
                  boxShadow: MdaShadows.md,
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: [
                    ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 11, sigmaY: 11),
                      child: Transform.scale(
                        scale: 1.12,
                        child: MosaicWidget(artwork: _stubArtwork(), showPulse: false, gap: 2, radius: 3),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [paper.withAlpha(0x4C), paper.withAlpha(0x9E)],
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline_rounded, size: 22, color: fg1),
                            const SizedBox(height: 7),
                            Text('L\'œuvre de juin', style: MdaType.h2(color: fg1).copyWith(fontSize: 18)),
                            const SizedBox(height: 4),
                            MdaOverline('Rejoins ou crée une instance', color: fg2),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Tab selector ───────────────────────────────────
              const SizedBox(height: 28),
              Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: MdaRadius.bSm,
                  border: Border.all(color: line),
                ),
                child: TabBar(
                  controller: _tab,
                  labelStyle: TextStyle(fontFamily: MdaFonts.sans,
                      fontSize: 14, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: TextStyle(fontFamily: MdaFonts.sans, fontSize: 14),
                  labelColor: accent,
                  unselectedLabelColor: fg3,
                  indicator: BoxDecoration(
                    color: accent.withAlpha(0x1A),
                    borderRadius: MdaRadius.bSm,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: [
                    const Tab(text: 'Rejoindre'),
                    const Tab(text: 'Créer'),
                    if (!widget.hasSolo) const Tab(text: 'Solo'),
                  ],
                ),
              ),

              // ── Join panel ─────────────────────────────────────
              if (_tab.index == 0) ...[
                const SizedBox(height: 22),
                Align(alignment: Alignment.centerLeft, child: MdaOverline('Code d\'instance')),
                const SizedBox(height: 10),
                _SplitCodeInput(
                  length: _codeLength,
                  value: _code,
                  onChanged: (v) => setState(() => _code = v),
                  accent: accent, surface: surface, line: line, fg1: fg1, fg3: fg3,
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Demande le code à la personne qui a créé l\'instance.',
                    style: MdaType.caption(color: fg3),
                  ),
                ),
              ],

              // ── Create panel ───────────────────────────────────
              if (_tab.index == 1) ...[
                const SizedBox(height: 22),
                Align(alignment: Alignment.centerLeft,
                    child: MdaOverline('Nom de l\'instance · facultatif')),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameCtrl,
                  style: MdaType.body(color: fg1),
                  decoration: InputDecoration(
                    hintText: 'Les copains de fac',
                    hintStyle: MdaType.body(color: fg3)),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 8),
                Text('Un code à partager sera généré automatiquement.',
                    style: MdaType.caption(color: fg3)),
              ],

              // ── Solo panel ─────────────────────────────────────
              if (!widget.hasSolo && _tab.index == 2) ...[
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: surface, borderRadius: MdaRadius.bMd,
                    border: Border.all(color: line),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.person_outline_rounded, size: 20, color: accent),
                      const SizedBox(width: 10),
                      Expanded(child: Text(
                        'Mode solo — aucun serveur requis. '
                        'Tu joues seul(e) : une couleur par jour, les photos sont stockées sur ton téléphone.',
                        style: MdaType.caption(color: fg2),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Optional artwork import
                GestureDetector(
                  onTap: () => setState(() => _showArtwork = !_showArtwork),
                  child: Row(
                    children: [
                      Icon(
                        _showArtwork ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        size: 18, color: fg2,
                      ),
                      const SizedBox(width: 6),
                      Text('Importer l\'œuvre du mois (JSON)',
                          style: MdaType.bodySm(color: fg2).copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                if (_showArtwork) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _artworkCtrl,
                    style: MdaType.caption(color: fg1).copyWith(fontFamily: 'monospace', fontSize: 11),
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: '{ "id": "jun26", "cols": 14, … }',
                      hintStyle: MdaType.caption(color: fg3),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Colle le JSON généré par l\'admin. Laisse vide pour utiliser l\'œuvre par défaut.',
                    style: MdaType.caption(color: fg3),
                  ),
                ],
              ],

              // ── Pseudo (obligatoire) ────────────────────────────
              const SizedBox(height: 20),
              Align(alignment: Alignment.centerLeft, child: MdaOverline('Ton prénom ou pseudonyme')),
              const SizedBox(height: 10),
              TextField(
                controller: _pseudoCtrl,
                style: MdaType.body(color: fg1),
                decoration: InputDecoration(
                  hintText: 'ex : Camille ou Vincent',
                  hintStyle: MdaType.body(color: fg3),
                  suffixIcon: _pseudoCtrl.text.trim().isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 18, color: fg3),
                          onPressed: () { _pseudoCtrl.clear(); setState(() {}); },
                        )
                      : null,
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              // Artist name suggestion chips
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _suggestions.map((name) => GestureDetector(
                  onTap: () { _pseudoCtrl.text = name; setState(() {}); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: surface, borderRadius: MdaRadius.bPill,
                      border: Border.all(
                        color: _pseudoCtrl.text == name ? accent : line,
                        width: _pseudoCtrl.text == name ? 1.5 : 1,
                      ),
                    ),
                    child: Text(name, style: MdaType.bodySm(
                      color: _pseudoCtrl.text == name ? accent : fg2)),
                  ),
                )).toList(),
              ),

              // ── CTA ────────────────────────────────────────────
              const SizedBox(height: 28),
              MdaButton(
                label: switch (_tab.index) {
                  0 => 'Rejoindre l\'instance',
                  1 => 'Créer une instance',
                  _ => 'Jouer en solo',
                },
                expand: true,
                onPressed: switch (_tab.index) {
                  0 => _canJoin   ? _submit : null,
                  1 => _canCreate ? _submit : null,
                  _ => _canSolo   ? _submit : null,
                },
              ),
              // Reminder when solo is already taken
              if (widget.hasSolo) ...[
                const SizedBox(height: 10),
                Text(
                  'Une instance solo existe déjà — elle ne peut être créée qu\'une seule fois.',
                  style: MdaType.caption(color: fg3),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Artwork _stubArtwork() {
    const cols = 14, rows = 18;
    final contrib = ZoneContribution(
      playerPseudo: '', playerAvatar: 'ochre', contributedAt: DateTime.now());
    final zones = <String, Zone>{
      'sky':   Zone(id: 'sky',   pigment: ZoneColor.fromLegacyPigment('cobalt'),   cellCount: 80, contribution: contrib),
      'sun':   Zone(id: 'sun',   pigment: ZoneColor.fromLegacyPigment('saffron'),  cellCount: 10, contribution: contrib),
      'halo':  Zone(id: 'halo',  pigment: ZoneColor.fromLegacyPigment('ochre'),    cellCount: 24, contribution: contrib),
      'hills': Zone(id: 'hills', pigment: ZoneColor.fromLegacyPigment('viridian'), cellCount: 42, contribution: contrib),
      'earth': Zone(id: 'earth', pigment: ZoneColor.fromLegacyPigment('sienna'),   cellCount: 96),
    };
    final cells = <MosaicCell>[];
    int idx = 0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final String z;
        if (r < 9) {
          final dx = c - 9.3, dy = (r - 3.4) * 1.15;
          final d = (dx * dx + dy * dy).sqrt();
          if (d < 2.1) z = 'sun';
          else if (d < 3.3) z = 'halo';
          else z = 'sky';
        } else if (r < 13) {
          z = 'hills';
        } else {
          z = 'earth';
        }
        cells.add(MosaicCell(index: idx++, col: c, row: r, zoneId: z));
      }
    }
    return Artwork(id: 'stub', cols: cols, rows: rows, cells: cells, zones: zones);
  }
}

class _SplitCodeInput extends StatefulWidget {
  final int length;
  final String value;
  final ValueChanged<String> onChanged;
  final Color accent, surface, line, fg1, fg3;

  const _SplitCodeInput({
    required this.length, required this.value, required this.onChanged,
    required this.accent, required this.surface, required this.line,
    required this.fg1, required this.fg3,
  });

  @override
  State<_SplitCodeInput> createState() => _SplitCodeInputState();
}

class _SplitCodeInputState extends State<_SplitCodeInput> {
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() { _ctrl.dispose(); _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _focus.requestFocus,
      child: Stack(
        children: [
          Row(
            children: List.generate(widget.length, (i) {
              final ch     = i < widget.value.length ? widget.value[i] : null;
              final active = i == widget.value.length;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < widget.length - 1 ? 9 : 0),
                  height: 52,
                  decoration: BoxDecoration(
                    color: widget.surface,
                    borderRadius: MdaRadius.bSm,
                    border: Border.all(
                      color: ch != null ? widget.accent : active ? widget.fg3 : widget.line,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    ch ?? '·',
                    style: TextStyle(
                      fontFamily: MdaFonts.serif, fontSize: 26,
                      color: ch != null ? widget.fg1 : widget.fg3,
                    ),
                  ),
                ),
              );
            }),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                maxLength: widget.length,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  _UpperCase(),
                ],
                onChanged: widget.onChanged,
                decoration: const InputDecoration(counterText: ''),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpperCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue _, TextEditingValue v) =>
      v.copyWith(text: v.text.toUpperCase());
}

extension on double {
  double sqrt() => (this <= 0) ? 0 : _sqrtIter(this);
  static double _sqrtIter(double x) {
    double r = x / 2;
    for (int i = 0; i < 20; i++) r = (r + x / r) / 2;
    return r;
  }
}
