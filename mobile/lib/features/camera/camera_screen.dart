// camera_screen.dart — viseur v2 : vraie caméra + feedback couleur temps réel
// (camera + color_analyzer), avec repli simulé si aucun capteur (desktop/web).

import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../engine/mosaic_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/camera_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/color_analyzer.dart';
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
  bool _streaming = false;
  CameraController? _ctrl;

  void _ensureStream(CameraController ctrl, Color target) {
    if (_streaming) return;
    _streaming = true;
    _ctrl = ctrl;
    ctrl.startImageStream((img) {
      if (mounted) ref.read(liveColorProvider(target).notifier).onFrame(img);
    });
  }

  Future<void> _stopStream() async {
    if (_streaming && _ctrl != null && _ctrl!.value.isStreamingImages) {
      try {
        await _ctrl!.stopImageStream();
      } catch (_) {}
    }
    _streaming = false;
  }

  /// Galerie : choisir une photo existante → même pipeline analyse/upload.
  Future<void> _pickFromGallery(Color target) async {
    if (_shot) return;
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (picked == null || !mounted) return;
    await _stopStream();
    int score;
    String? photoPath;
    try {
      final res = await analyzeImageFile(picked.path, target);
      score = res.score;
      photoPath = res.photoPath;
    } catch (_) {
      score = 72 + math.Random().nextInt(22);
      photoPath = picked.path;
    }
    if (!mounted) return;
    setState(() => _shot = true);
    await ref.read(gameProvider.notifier).captureDone(photoPath: photoPath, fallbackScore: score);
    if (!mounted) return;
    context.pushReplacement('/confirm');
  }

  Future<void> _capture(Color target, {CameraController? real}) async {
    if (_shot) return;
    int score;
    String? photoPath;
    if (real != null) {
      await _stopStream();
      try {
        final res = await capturePhoto(real, target);
        score = res.score;
        photoPath = res.photoPath;
      } catch (_) {
        score = 72 + math.Random().nextInt(22);
      }
    } else {
      score = 72 + math.Random().nextInt(22);
    }
    if (!mounted) return;
    setState(() => _shot = true);
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    // Online + a real file → uploads to the server (real ΔE/score/points).
    await ref.read(gameProvider.notifier).captureDone(photoPath: photoPath, fallbackScore: score);
    if (!mounted) return;
    context.pushReplacement('/confirm');
  }

  @override
  void dispose() {
    _stopStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final lang = ref.watch(langProvider);
    final g = ref.watch(gameProvider);
    final task = g.currentTask;
    final v = kVariants[g.activeVariantKey]!;
    final target = v.color;

    final camsAsync = ref.watch(availableCamerasProvider);
    final hasCamera = camsAsync.maybeWhen(data: (c) => c.isNotEmpty, orElse: () => false);

    return Scaffold(
      backgroundColor: const Color(0xFF15110C),
      body: Stack(children: [
        // fond : vraie caméra ou viseur simulé
        Positioned.fill(child: hasCamera ? _realPreview(target) : _simulated(v.family)),
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
              _targetChip(t, v, lang),
              const SizedBox(height: 10),
              _liveHint(t, target, hasCamera),
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
        if (_shot) Positioned.fill(child: Container(color: Colors.white.withValues(alpha: 0.9))),
        // shutter
        Positioned(
          left: 0,
          right: 0,
          bottom: 44,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _RoundBtn(icon: 'image', onTap: () => _pickFromGallery(target), size: 46),
            const SizedBox(width: 34),
            GestureDetector(
              onTap: () => _capture(target, real: hasCamera ? _ctrl : null),
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
            _RoundBtn(
              icon: 'refresh',
              size: 46,
              onTap: () {
                final cur = ref.read(lensDirectionProvider);
                ref.read(lensDirectionProvider.notifier).state =
                    cur == CameraLensDirection.back ? CameraLensDirection.front : CameraLensDirection.back;
                _streaming = false;
              },
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _realPreview(Color target) {
    final lens = ref.watch(lensDirectionProvider);
    final ctrlAsync = ref.watch(cameraControllerProvider(lens));
    return ctrlAsync.when(
      data: (ctrl) {
        _ensureStream(ctrl, target);
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: ctrl.value.previewSize?.height ?? 1080,
              height: ctrl.value.previewSize?.width ?? 1920,
              child: CameraPreview(ctrl),
            ),
          ),
        );
      },
      loading: () => const ColoredBox(color: Color(0xFF15110C)),
      error: (_, __) => _simulated(kVariants[ref.read(gameProvider).myVariant]!.family),
    );
  }

  // Viseur simulé : fonds « photo » de la famille (repli desktop/web).
  Widget _simulated(String family) {
    return Stack(children: [
      for (final gr in photoLayers(family)) DecoratedBox(decoration: BoxDecoration(gradient: gr), child: const SizedBox.expand()),
    ]);
  }

  Widget _targetChip(L10n t, VariantDef v, String lang) {
    return Container(
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
    );
  }

  // Sous le chip : feedback temps réel (« Parfait ! / Trop chaud … ») si caméra,
  // sinon consigne simple.
  Widget _liveHint(L10n t, Color target, bool hasCamera) {
    String label;
    if (hasCamera) {
      final live = ref.watch(liveColorProvider(target));
      label = verdictLabel(live.verdict, live.detected, target);
    } else {
      label = t.camFrameSomething;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: const Color(0x4D000000), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: MdaType.sans(size: 13, color: Colors.white.withValues(alpha: 0.9))),
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
