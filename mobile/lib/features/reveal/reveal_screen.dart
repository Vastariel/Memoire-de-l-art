// reveal_screen.dart — Reveal du dimanche : stagger → vitrail → cartel.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../engine/mosaic_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/data_providers.dart';
import '../../providers/game_provider.dart';
import '../../theme/theme.dart';
import '../../theme/typography.dart';
import '../../widgets/mda_icon.dart';
import '../../widgets/mosaic.dart';
import '../../widgets/primitives.dart';

class RevealScreen extends ConsumerStatefulWidget {
  const RevealScreen({super.key});
  @override
  ConsumerState<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends ConsumerState<RevealScreen> {
  int _phase = 0; // 0 build → 1 vitrail → 2 cartel

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _phase = 1);
    });
    Future.delayed(const Duration(milliseconds: 2100), () {
      if (mounted) setState(() => _phase = 2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final g = ref.watch(gameProvider);
    final artwork = ref.watch(artworkDataProvider).valueOrNull;
    final info = ref.watch(weekInfoProvider).valueOrNull ?? const WeekInfo();
    final photos = ref.watch(instancePhotoUrlsProvider(g.activeInstanceId)).valueOrNull ?? const {};
    final all = kFamilies.keys.toSet();

    // Avant le reveal du dimanche : teaser, pas de spoil.
    if (!info.revealed) return _pending(context, t, g.week);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C1813), Color(0xFF2A2017)]),
        ),
        child: SafeArea(
          child: Column(children: [
            Align(
              alignment: Alignment.topRight,
              child: IconTapButton('x', color: Colors.white70, onTap: () => context.pop()),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26, 4, 26, 0),
                  child: Column(children: [
                    Overline(t.revealOverline(g.week), color: Colors.white.withValues(alpha: 0.55)),
                    const SizedBox(height: 8),
                    Text(t.artworkRevealed, textAlign: TextAlign.center, style: MdaType.serif(size: 26, weight: FontWeight.w500, color: Colors.white)),
                    const SizedBox(height: 20),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: MdaRadius.bLg,
                          border: Border.all(color: const Color(0xFF0E0B07), width: 6),
                          boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 70, offset: Offset(0, 30))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: MosaicWidget(
                            filled: all,
                            revealAll: true,
                            vitrail: _phase >= 1 ? 1 : 0,
                            stagger: _phase == 0,
                            pulse: false,
                            gap: 1,
                            artwork: artwork,
                            photos: photos,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    AnimatedOpacity(
                      opacity: _phase >= 2 ? 1 : 0,
                      duration: const Duration(milliseconds: 500),
                      child: Column(children: [
                        Text(info.title ?? '—', textAlign: TextAlign.center,
                            style: MdaType.serif(size: 23, italic: true, color: Colors.white)),
                        const SizedBox(height: 6),
                        Text(
                            [if (info.artist != null) info.artist!, if (info.year != null) '${info.year}'].join(' · '),
                            textAlign: TextAlign.center, style: MdaType.sans(size: 13.5, color: Colors.white.withValues(alpha: 0.7))),
                        if (g.bet?.correct == true) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                            decoration: BoxDecoration(color: const Color(0x383F8E5C), borderRadius: BorderRadius.circular(999)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const MdaIcon('checkCircle', size: 15, color: Color(0xFF8FD3A6)),
                              const SizedBox(width: 7),
                              Text('${t.betWon} · +${g.bet!.points} pts',
                                  style: MdaType.sans(size: 13, weight: FontWeight.w700, color: const Color(0xFF8FD3A6))),
                            ]),
                          ),
                        ],
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: _phase >= 2 ? 1 : 0,
              duration: const Duration(milliseconds: 500),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26, 8, 26, 16),
                child: Column(children: [
                  MdaButton(t.shareCard, full: true, variant: MdaBtnVariant.dark, icon: 'share',
                      onTap: () => Share.share(t.shareRevealMessage(info.title ?? '—', g.week))),
                  const SizedBox(height: 10),
                  MdaButton(t.addToCollection, full: true, variant: MdaBtnVariant.ghost, textColor: Colors.white, onTap: () => context.go('/collection')),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  /// Teaser avant le reveal : pas de cartel, pas de spoil.
  Widget _pending(BuildContext context, L10n t, int week) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C1813), Color(0xFF2A2017)]),
        ),
        child: SafeArea(
          child: Column(children: [
            Align(
              alignment: Alignment.topRight,
              child: IconTapButton('x', color: Colors.white70, onTap: () => context.pop()),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const MdaIcon('lock', size: 40, color: Colors.white54),
                  const SizedBox(height: 18),
                  Overline(t.revealOverline(week), color: Colors.white.withValues(alpha: 0.55)),
                  const SizedBox(height: 10),
                  Text(t.revealPendingTitle, textAlign: TextAlign.center,
                      style: MdaType.serif(size: 24, weight: FontWeight.w500, color: Colors.white)),
                  const SizedBox(height: 10),
                  Text(t.revealPendingBody, textAlign: TextAlign.center,
                      style: MdaType.sans(size: 14, height: 1.5, color: Colors.white.withValues(alpha: 0.7))),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
