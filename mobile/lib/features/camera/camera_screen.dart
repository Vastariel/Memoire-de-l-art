// camera_screen.dart — viseur (simulé Phase 1) avec HUD teinte cible.
// Le vrai flux caméra (camera + color_analyzer) se branchera ici en Phase 2 ;
// le design lui-même simule la prise et le score de matching.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../engine/mosaic_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/game_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/typography.dart';
import '../../widgets/game_widgets.dart';
import '../../widgets/mda_icon.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});
  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  bool _shot = false;

  void _shoot() {
    if (_shot) return;
    setState(() => _shot = true);
    Future.delayed(const Duration(milliseconds: 1050), () {
      if (!mounted) return;
      final score = 72 + math.Random().nextInt(22);
      ref.read(gameProvider.notifier).captureDone(score);
      context.pushReplacement('/confirm');
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final lang = ref.watch(langProvider);
    final g = ref.watch(gameProvider);
    final task = g.currentTask;
    final v = kVariants[task?.variant ?? g.myVariant]!;
    final layers = photoLayers(v.family);

    return Scaffold(
      backgroundColor: const Color(0xFF15110C),
      body: Stack(children: [
        // viseur simulé : fond « photo » de la famille
        Positioned.fill(
          child: Stack(children: [
            for (final gr in layers) DecoratedBox(decoration: BoxDecoration(gradient: gr), child: const SizedBox.expand()),
          ]),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x59000000), Color(0x00000000), Color(0x00000000), Color(0x8C000000)],
                stops: [0, 0.22, 0.62, 1],
              ),
            ),
          ),
        ),
        // HUD haut
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _RoundBtn(icon: 'x', onTap: () => context.pop()),
                InstanceBadge(mode: task?.kind ?? g.activeInstance.mode, big: true),
              ]),
              const SizedBox(height: 24),
              // cible teinte
              Container(
                padding: const EdgeInsets.fromLTRB(9, 9, 16, 9),
                decoration: BoxDecoration(color: const Color(0x66000000), borderRadius: BorderRadius.circular(999)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: v.color,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(t.camTarget.toUpperCase(),
                        style: MdaType.sans(size: 10.5, weight: FontWeight.w600, letterSpacing: 1.2, color: Colors.white70)),
                    Text(v.name(lang), style: MdaType.serif(size: 18, height: 1, color: Colors.white)),
                  ]),
                ]),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: const Color(0x4D000000), borderRadius: BorderRadius.circular(999)),
                child: Text(t.camFrameSomething, style: MdaType.sans(size: 13, color: Colors.white.withValues(alpha: 0.85))),
              ),
            ]),
          ),
        ),
        // réticule
        Center(
          child: Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2),
            ),
          ),
        ),
        if (_shot)
          Positioned.fill(child: Container(color: Colors.white.withValues(alpha: 0.9))),
        // shutter
        Positioned(
          left: 0,
          right: 0,
          bottom: 44,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _RoundBtn(icon: 'image', onTap: () {}, size: 46),
            const SizedBox(width: 34),
            GestureDetector(
              onTap: _shoot,
              child: Container(
                width: 78,
                height: 78,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  color: Colors.white.withValues(alpha: 0.22),
                ),
                child: const DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 34),
            _RoundBtn(icon: 'refresh', onTap: () {}, size: 46),
          ]),
        ),
      ]),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;
  final double size;
  const _RoundBtn({required this.icon, required this.onTap, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.16)),
        child: Center(child: MdaIcon(icon, size: 20, color: Colors.white)),
      ),
    );
  }
}
