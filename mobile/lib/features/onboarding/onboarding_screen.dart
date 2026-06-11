// onboarding_screen.dart — 3 étapes : OAuth + RGPD → pseudo → rejoindre/créer.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/artist_names.dart';
import '../../l10n/app_localizations.dart';
import '../../models/game_models.dart';
import '../../providers/api_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../theme/colors.dart';
import '../../theme/palette.dart';
import '../../theme/theme.dart';
import '../../theme/typography.dart';
import '../../widgets/game_widgets.dart';
import '../../widgets/mda_icon.dart';
import '../../widgets/mosaic.dart';
import '../../widgets/primitives.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int step = 0;
  bool consent = false;
  String join = 'join'; // join | create
  String via = 'code'; // code | link | qr
  InstanceMode mode = InstanceMode.shared;
  final _pseudo = TextEditingController();
  final _code = TextEditingController();
  final _instName = TextEditingController();
  late final List<String> _suggestions = randomArtistSuggestions(4);

  @override
  void dispose() {
    _pseudo.dispose();
    _code.dispose();
    _instName.dispose();
    super.dispose();
  }

  void _provider(AuthProvider p) {
    ref.read(authProvider.notifier).startProvider(p);
    setState(() => step = 1);
  }

  Future<void> _finish() async {
    await ref.read(authProvider.notifier).completeOnboarding(pseudo: _pseudo.text);
    if (ref.read(useApiProvider) && ref.read(authProvider).online) {
      final api = ref.read(apiClientProvider);
      try {
        if (join == 'join') {
          final code = _code.text.trim();
          if (code.isNotEmpty) await api.joinInstance(code);
        } else {
          final name = _instName.text.trim();
          await api.createInstance(
            name: name.isEmpty ? null : name,
            mode: mode == InstanceMode.shared ? 'shared' : 'separate',
          );
        }
      } catch (_) {/* graceful: proceed without instance */}
      await ref.read(gameProvider.notifier).loadFromApi();
    }
    if (mounted) context.go('/today');
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return Scaffold(
      backgroundColor: context.paper,
      body: SafeArea(
        child: Column(children: [
          const SizedBox(height: 8),
          // progress dots
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: i == step ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i <= step ? context.accent : MdaColors.cream300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ]),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: switch (step) {
                  0 => _step0(t),
                  1 => _step1(t),
                  _ => _step2(t),
                },
              ),
            ),
          ),
          _footer(t),
        ]),
      ),
    );
  }

  Widget _step0(L10n t) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 4),
      Center(
        child: Column(children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [MdaColors.safran, MdaColors.clay500, MdaColors.cobalt]),
              boxShadow: MdaShadows.md,
            ),
            child: const Center(child: MdaIcon('frame', size: 36, color: Colors.white)),
          ),
          const SizedBox(height: 12),
          Text('Mémoire de l\'art', textAlign: TextAlign.center, style: MdaType.serif(size: 29, weight: FontWeight.w500, color: context.fg1)),
          const SizedBox(height: 6),
          Text(t.appTagline, textAlign: TextAlign.center, style: MdaType.serif(size: 15.5, italic: true, height: 1.3, color: context.fg2)),
        ]),
      ),
      const SizedBox(height: 22),
      // mystery teaser
      ClipRRect(
        borderRadius: MdaRadius.bLg,
        child: Stack(children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: const MosaicWidget(filled: {'bleus', 'ors'}, pulse: false),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [context.paper.withValues(alpha: 0.20), context.paper.withValues(alpha: 0.55)],
                ),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                MdaIcon('lock', size: 20, color: context.fg1),
                const SizedBox(height: 7),
                Text(t.mysteryArtworkOfWeek, style: MdaType.serif(size: 17, italic: true, color: context.fg1)),
                const SizedBox(height: 4),
                Overline(t.revealedSunday, fontSize: 11),
              ]),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 24),
      _AuthButton(provider: 'apple', label: t.continueWithApple, onTap: () => _provider(AuthProvider.apple)),
      const SizedBox(height: 10),
      _AuthButton(provider: 'google', label: t.continueWithGoogle, onTap: () => _provider(AuthProvider.google)),
      const SizedBox(height: 8),
      Text(t.accountSyncNote, textAlign: TextAlign.center, style: MdaType.sans(size: 12, height: 1.45, color: context.fg3)),
      const SizedBox(height: 18),
      // RGPD consent
      GestureDetector(
        onTap: () => setState(() => consent = !consent),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: consent ? context.accent : Colors.transparent,
              border: Border.all(color: consent ? context.accent : context.lineStrong, width: 1.5),
            ),
            child: consent ? const Center(child: MdaIcon('check', size: 14, color: Colors.white, strokeWidth: 2.5)) : null,
          ),
          const SizedBox(width: 11),
          Expanded(child: Text(t.consentText, style: MdaType.sans(size: 12.5, height: 1.45, color: context.fg2))),
        ]),
      ),
      const SizedBox(height: 4),
    ]);
  }

  Widget _step1(L10n t) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 12),
      Overline(t.onbStep2),
      const SizedBox(height: 8),
      Text(t.onbWhatsYourName, style: MdaType.serif(size: 25, weight: FontWeight.w500, color: context.fg1)),
      const SizedBox(height: 4),
      Text(t.onbPseudoHint, style: MdaType.sans(size: 14, height: 1.4, color: context.fg2)),
      const SizedBox(height: 22),
      TextField(
        controller: _pseudo,
        autofocus: true,
        style: MdaType.serif(size: 17, color: context.fg1),
        decoration: const InputDecoration(hintText: 'Camille'),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final name in _suggestions)
            MdaChip(
              name,
              active: _pseudo.text.trim() == name,
              onTap: () => setState(() {
                _pseudo.text = name;
                _pseudo.selection = TextSelection.collapsed(offset: name.length);
              }),
            ),
        ],
      ),
    ]);
  }

  Widget _step2(L10n t) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 12),
      Overline(t.onbStep3),
      const SizedBox(height: 8),
      Text(t.onbJoinOrCreate, style: MdaType.serif(size: 25, weight: FontWeight.w500, color: context.fg1)),
      const SizedBox(height: 16),
      _Segmented(
        options: [('join', t.actionJoin), ('create', t.actionCreate)],
        value: join,
        onChanged: (v) => setState(() => join = v),
      ),
      const SizedBox(height: 18),
      if (join == 'join') ..._joinBlock(t) else ..._createBlock(t),
    ]);
  }

  List<Widget> _joinBlock(L10n t) {
    return [
      Row(children: [
        _viaTab('code', t.viaCode, 'qr'),
        const SizedBox(width: 8),
        _viaTab('link', t.viaLink, 'link'),
        const SizedBox(width: 8),
        _viaTab('qr', t.viaQr, 'qr'),
      ]),
      const SizedBox(height: 16),
      if (via == 'code') _CodeInput(controller: _code),
      if (via == 'link')
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: context.surface, borderRadius: MdaRadius.bMd, border: Border.all(color: context.line)),
          child: Row(children: [
            MdaIcon('link', size: 18, color: context.fg3),
            const SizedBox(width: 10),
            Expanded(child: Text('memoire.art/i/ARL8-camille', overflow: TextOverflow.ellipsis, style: MdaType.sans(size: 14, color: context.fg2))),
            MdaChip(t.onbOpen, onTap: () => _code.text = 'ARL8X7'),
          ]),
        ),
      if (via == 'qr')
        Center(
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: MdaRadius.bLg, boxShadow: MdaShadows.md),
              child: const MdaQr('ARL8-MDA', size: 150),
            ),
            const SizedBox(height: 12),
            Text(t.onbScanQr, textAlign: TextAlign.center, style: MdaType.sans(size: 13, color: context.fg2)),
          ]),
        ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: context.surfaceSunk, borderRadius: MdaRadius.bMd),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          MdaIcon('info', size: 16, color: context.fg3),
          const SizedBox(width: 9),
          Expanded(child: Text(t.onbMidWeekNote, style: MdaType.sans(size: 12.5, height: 1.45, color: context.fg2))),
        ]),
      ),
    ];
  }

  List<Widget> _createBlock(L10n t) {
    return [
      TextField(controller: _instName, decoration: InputDecoration(hintText: t.onbInstanceNamePlaceholder)),
      const SizedBox(height: 16),
      Overline(t.onbInstanceMode),
      const SizedBox(height: 9),
      _ModeCard(
        mode: InstanceMode.shared,
        desc: t.modeSharedDesc,
        selected: mode == InstanceMode.shared,
        onTap: () => setState(() => mode = InstanceMode.shared),
      ),
      const SizedBox(height: 9),
      _ModeCard(
        mode: InstanceMode.separate,
        desc: t.modeSeparateDesc,
        selected: mode == InstanceMode.separate,
        onTap: () => setState(() => mode = InstanceMode.separate),
      ),
    ];
  }

  Widget _viaTab(String k, String label, String icon) {
    final on = via == k;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => via = k),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: on ? MdaColors.clay100 : context.surface,
            borderRadius: MdaRadius.bMd,
            border: Border.all(color: on ? context.accent : context.line),
          ),
          child: Column(children: [
            MdaIcon(icon, size: 18, color: on ? MdaColors.clay600 : context.fg2, strokeWidth: 1.8),
            const SizedBox(height: 5),
            Text(label, style: MdaType.sans(size: 12.5, weight: FontWeight.w600, color: on ? MdaColors.clay600 : context.fg2)),
          ]),
        ),
      ),
    );
  }

  Widget _footer(L10n t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (step == 0)
          MdaButton(t.onbStart, full: true, disabled: !consent, onTap: consent ? () => setState(() => step = 1) : null),
        if (step == 1) MdaButton(t.actionContinue, full: true, iconRight: 'right', onTap: () => setState(() => step = 2)),
        if (step == 2) MdaButton(join == 'join' ? t.onbJoinInstance : t.onbCreateInstance, full: true, onTap: _finish),
        if (step == 0) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              await ref.read(authProvider.notifier).signInDev();
              if (ref.read(authProvider).online) await ref.read(gameProvider.notifier).loadFromApi();
              if (mounted) context.go('/today');
            },
            child: Text(t.devContinue, style: MdaType.sans(size: 13, weight: FontWeight.w600, color: context.fg3)),
          ),
        ],
        if (step > 0) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => step -= 1),
            child: Text(t.actionBack, style: MdaType.sans(size: 13, weight: FontWeight.w600, color: context.fg3)),
          ),
        ],
      ]),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String provider;
  final String label;
  final VoidCallback onTap;
  const _AuthButton({required this.provider, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isApple = provider == 'apple';
    final bg = isApple ? context.fg1 : context.surface;
    final fg = isApple ? context.paper : context.fg1;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: MdaRadius.bPill,
          border: isApple ? null : Border.all(color: context.lineStrong),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          MdaIcon(provider, size: 19, color: fg, strokeWidth: 1.6),
          const SizedBox(width: 10),
          Text(label, style: MdaType.sans(size: 15.5, weight: FontWeight.w600, color: fg)),
        ]),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final List<(String, String)> options;
  final String value;
  final ValueChanged<String> onChanged;
  const _Segmented({required this.options, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: context.surfaceSunk, borderRadius: MdaRadius.bPill),
      child: Row(children: [
        for (final o in options)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(o.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: value == o.$1 ? context.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: value == o.$1 ? MdaShadows.sm : null,
                ),
                child: Text(o.$2,
                    textAlign: TextAlign.center,
                    style: MdaType.sans(size: 14, weight: FontWeight.w600, color: value == o.$1 ? context.fg1 : context.fg2)),
              ),
            ),
          ),
      ]),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final InstanceMode mode;
  final String desc;
  final bool selected;
  final VoidCallback onTap;
  const _ModeCard({required this.mode, required this.desc, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final col = mode.isShared ? MdaColors.shared : MdaColors.separate;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: MdaRadius.bMd,
          border: Border.all(color: selected ? col : context.line, width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            InstanceBadge(mode: mode, big: true),
            if (selected) MdaIcon('checkCircle', size: 18, color: col),
          ]),
          const SizedBox(height: 6),
          Text(desc, style: MdaType.sans(size: 12.5, height: 1.4, color: context.fg2)),
        ]),
      ),
    );
  }
}

class _CodeInput extends StatefulWidget {
  final TextEditingController controller;
  const _CodeInput({required this.controller});
  @override
  State<_CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<_CodeInput> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clean = widget.controller.text.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    return GestureDetector(
      onTap: () => _focus.requestFocus(),
      child: Stack(children: [
        Row(children: [
          for (var i = 0; i < 6; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: AspectRatio(
                aspectRatio: 0.82,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: MdaRadius.bSm,
                    border: Border.all(
                      color: i < clean.length ? context.accent : (i == clean.length ? context.lineStrong : context.line),
                      width: 1.5,
                    ),
                  ),
                  child: Text(i < clean.length ? clean[i] : '·',
                      style: MdaType.serif(size: 25, color: i < clean.length ? context.fg1 : context.fg3)),
                ),
              ),
            ),
          ],
        ]),
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
      ]),
    );
  }
}
