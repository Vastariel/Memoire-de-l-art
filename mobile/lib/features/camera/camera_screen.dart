import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/zone.dart';
import '../../providers/camera_provider.dart';
import '../../services/color_analyzer.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../theme/typography.dart';

class CameraScreen extends ConsumerStatefulWidget {
  final ZoneColor targetPigment;
  final VoidCallback onClose;
  final void Function(CaptureResult result) onCapture;

  const CameraScreen({
    super.key,
    required this.targetPigment,
    required this.onClose,
    required this.onCapture,
  });

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    await Permission.camera.request();
  }

  Future<void> _onCapture(CameraController ctrl) async {
    if (_capturing) return;
    setState(() => _capturing = true);
    try {
      final result = await capturPhoto(ctrl, widget.targetPigment.color);
      if (mounted) widget.onCapture(result);
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _onGallery() async {
    final picker = ImagePicker();
    final file   = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (file == null || !mounted) return;

    final bytes    = await file.readAsBytes();
    final detected = await _averageColorFromJpeg(bytes);
    final delta    = colorDelta(detected, widget.targetPigment.color);
    final verdict  = verdictFromDelta(delta);
    final mode     = delta < 22 ? 'replace' : 'blend';

    widget.onCapture(CaptureResult(
      photoPath: file.path,
      detected:  detected,
      delta:     delta,
      verdict:   verdict,
      mode:      mode,
    ));
  }

  Future<Color> _averageColorFromJpeg(List<int> bytes) async {
    final start  = bytes.length ~/ 3;
    final end    = (bytes.length * 2) ~/ 3;
    int rSum = 0, gSum = 0, bSum = 0, count = 0;
    for (int i = start; i < end; i += 50) {
      rSum += bytes[i].clamp(0, 255);
      gSum += bytes[(i + 1).clamp(0, end - 1)].clamp(0, 255);
      bSum += bytes[(i + 2).clamp(0, end - 1)].clamp(0, 255);
      count++;
    }
    if (count == 0) return Colors.grey;
    return Color.fromARGB(255, rSum ~/ count, gSum ~/ count, bSum ~/ count);
  }

  void _toggleLens() {
    final current = ref.read(lensDirectionProvider);
    ref.read(lensDirectionProvider.notifier).state =
        current == CameraLensDirection.back
            ? CameraLensDirection.front
            : CameraLensDirection.back;
  }

  @override
  Widget build(BuildContext context) {
    final direction = ref.watch(lensDirectionProvider);
    final ctrlAsync = ref.watch(cameraControllerProvider(direction));

    return Scaffold(
      backgroundColor: Colors.black,
      body: ctrlAsync.when(
        loading: () => const _LoadingView(),
        error:   (e, _) => _ErrorView(error: e.toString(), onClose: widget.onClose),
        data:    (ctrl) => _CameraView(
          ctrl:      ctrl,
          target:    widget.targetPigment,
          capturing: _capturing,
          onClose:   widget.onClose,
          onCapture: () => _onCapture(ctrl),
          onGallery: _onGallery,
          onFlip:    _toggleLens,
        ),
      ),
    );
  }
}

// ── Camera preview + HUD ─────────────────────────────────────────────────────

class _CameraView extends ConsumerStatefulWidget {
  final CameraController ctrl;
  final ZoneColor target;
  final bool capturing;
  final VoidCallback onClose, onCapture, onGallery, onFlip;

  const _CameraView({
    required this.ctrl,
    required this.target,
    required this.capturing,
    required this.onClose,
    required this.onCapture,
    required this.onGallery,
    required this.onFlip,
  });

  @override
  ConsumerState<_CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends ConsumerState<_CameraView> {
  @override
  void initState() {
    super.initState();
    widget.ctrl.startImageStream(_onFrame);
  }

  @override
  void dispose() {
    widget.ctrl.stopImageStream();
    super.dispose();
  }

  void _onFrame(CameraImage image) {
    ref.read(liveColorProvider(widget.target.color).notifier).onFrame(image);
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(liveColorProvider(widget.target.color));
    final toneColor = switch (live.verdict) {
      ColorVerdict.perfect => MdaColors.ok,
      ColorVerdict.correct => MdaColors.warn,
      ColorVerdict.weak    => MdaColors.error,
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: Colors.black),

        // ── Square viewfinder ──────────────────────────────────
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _SquarePreview(ctrl: widget.ctrl),
                    Positioned(
                      top: 14, left: 14,
                      child: _ColorRing(detected: live.detected, toneColor: toneColor),
                    ),
                    Positioned(
                      left: 14, right: 14, bottom: 14,
                      child: _VerdictCard(live: live, target: widget.target, toneColor: toneColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Top HUD ────────────────────────────────────────────
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                _GlassButton(icon: Icons.close, onTap: widget.onClose),
                const Spacer(),
                _TargetChip(pigment: widget.target),
                const Spacer(),
                _GlassButton(icon: Icons.flip_camera_ios_outlined, onTap: widget.onFlip),
              ],
            ),
          ),
        ),

        // ── Bottom controls ─────────────────────────────────────
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: SafeArea(
            minimum: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 20, 30, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _GalleryButton(onTap: widget.onGallery),
                  _ShutterButton(onTap: widget.onCapture, capturing: widget.capturing),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Square preview (cover) ────────────────────────────────────────────────────
//
// Root cause of the squish: Align passes constraints.loosen() which still
// has maxHeight = squareSide, clamping SizedBox(height > side).
// Fix: OverflowBox ignores parent height constraint → ClipRRect clips overflow.
class _SquarePreview extends StatelessWidget {
  final CameraController ctrl;
  const _SquarePreview({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final side = constraints.maxWidth;
      return ValueListenableBuilder<CameraValue>(
        valueListenable: ctrl,
        builder: (_, value, __) {
          // CameraPreview internally applies rotation for device orientation.
          // In portrait: effective ratio = 1 / rawAspectRatio (landscape sensor → portrait display)
          final rawAspect = value.aspectRatio;
          final effectiveRatio = rawAspect < 1.0 ? rawAspect : 1.0 / rawAspect;
          // height > side when effectiveRatio < 1 → taller than square → clips top/bottom ✓
          final h = side / effectiveRatio;

          return OverflowBox(
            alignment: Alignment.center,
            minWidth: side, maxWidth: side,
            minHeight: h,   maxHeight: h,
            child: CameraPreview(ctrl),
          );
        },
      );
    });
  }
}

// ── HUD sub-widgets ───────────────────────────────────────────────────────────

class _ColorRing extends StatelessWidget {
  final Color detected, toneColor;
  const _ColorRing({required this.detected, required this.toneColor});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: MdaDuration.std,
      curve: MdaCurve.easeOut,
      width: 32, height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: detected,
        boxShadow: [
          BoxShadow(color: toneColor, spreadRadius: 3, blurRadius: 0),
          BoxShadow(color: Colors.white.withAlpha(0x50), spreadRadius: 5, blurRadius: 0),
        ],
      ),
    );
  }
}

class _VerdictCard extends StatelessWidget {
  final LiveColorState live;
  final ZoneColor target;
  final Color toneColor;
  const _VerdictCard({required this.live, required this.target, required this.toneColor});

  @override
  Widget build(BuildContext context) {
    final label = verdictLabel(live.verdict, live.detected, target.color);
    final hint  = verdictHint(live.verdict, live.detected, target.color);
    final textColor = switch (live.verdict) {
      ColorVerdict.perfect => const Color(0xFF7BE0A0),
      ColorVerdict.correct => const Color(0xFFF0C679),
      ColorVerdict.weak    => const Color(0xFFFF8A80),
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedContainer(
          duration: MdaDuration.std,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: Colors.black.withAlpha(0x8C),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: MdaDuration.std,
                child: Text(label, key: ValueKey(label),
                    style: TextStyle(fontFamily: MdaFonts.serif, fontSize: 22, color: textColor)),
              ),
              const SizedBox(height: 2),
              Text(hint, style: TextStyle(
                fontFamily: MdaFonts.sans, fontSize: 13,
                color: Colors.white.withAlpha(0xBF))),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetChip extends StatelessWidget {
  final ZoneColor pigment;
  const _TargetChip({required this.pigment});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: MdaRadius.bPill,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: Colors.white.withAlpha(0x25),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14, height: 14,
                decoration: BoxDecoration(
                  color: pigment.color, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 9),
              Text('Cible · ${pigment.label}',
                style: TextStyle(fontFamily: MdaFonts.sans, fontSize: 13,
                  fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 40, height: 40,
            color: Colors.white.withAlpha(0x25),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _GalleryButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GalleryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(0x1F),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.photo_library_outlined, size: 22, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text('Galerie', style: TextStyle(
            fontFamily: MdaFonts.sans, fontSize: 11,
            color: Colors.white.withAlpha(0xCC))),
        ],
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool capturing;
  const _ShutterButton({required this.onTap, required this.capturing});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: capturing ? null : onTap,
      child: AnimatedContainer(
        duration: MdaDuration.fast,
        curve: MdaCurve.easeOut,
        width: 74, height: 74,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: capturing ? Colors.white.withAlpha(0xCC) : Colors.white,
          border: Border.all(color: Colors.white.withAlpha(0x59), width: 5),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 8))],
        ),
        child: capturing
            ? const Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
              )
            : null,
      ),
    );
  }
}

// ── Loading / Error states ────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text('Initialisation de la caméra…',
            style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onClose;
  const _ErrorView({required this.error, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            const Text('Caméra inaccessible',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Vérifie les permissions dans les réglages.',
              style: const TextStyle(color: Colors.white60, fontSize: 14),
              textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextButton(onPressed: onClose,
              child: const Text('Retour', style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }
}
