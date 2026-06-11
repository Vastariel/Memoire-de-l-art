import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/color_analyzer.dart';

// ── Available cameras ────────────────────────────────────────────────────────

final availableCamerasProvider = FutureProvider<List<CameraDescription>>((ref) async {
  return availableCameras();
});

// ── Lens direction (back / front toggle) ─────────────────────────────────────

final lensDirectionProvider = StateProvider<CameraLensDirection>((_) => CameraLensDirection.back);

// ── Camera controller lifecycle (family keyed on lens direction) ─────────────

final cameraControllerProvider = StateNotifierProvider.autoDispose
    .family<CameraNotifier, AsyncValue<CameraController>, CameraLensDirection>(
  (ref, direction) => CameraNotifier(ref, direction),
);

class CameraNotifier extends StateNotifier<AsyncValue<CameraController>> {
  CameraNotifier(this._ref, this._direction) : super(const AsyncValue.loading()) {
    _init();
  }

  final Ref _ref;
  final CameraLensDirection _direction;
  CameraController? _ctrl;

  Future<void> _init() async {
    state = const AsyncValue.loading();
    try {
      final cameras = await _ref.read(availableCamerasProvider.future);
      if (cameras.isEmpty) throw CameraException('no_camera', 'Aucune caméra disponible');
      final camera = cameras.firstWhere((c) => c.lensDirection == _direction, orElse: () => cameras.first);
      final ctrl = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await ctrl.initialize();
      _ctrl = ctrl;
      state = AsyncValue.data(ctrl);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }
}

// ── Live colour stream (throttled ~2 fps) ────────────────────────────────────

class LiveColorState {
  final Color detected;
  final double delta;
  final ColorVerdict verdict;
  const LiveColorState({required this.detected, required this.delta, required this.verdict});

  static LiveColorState initial() =>
      const LiveColorState(detected: Colors.grey, delta: 100, verdict: ColorVerdict.weak);
}

class LiveColorNotifier extends StateNotifier<LiveColorState> {
  LiveColorNotifier(this._target) : super(LiveColorState.initial());

  final Color _target;
  bool _processing = false;
  DateTime _lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> onFrame(CameraImage image) async {
    final now = DateTime.now();
    if (_processing || now.difference(_lastUpdate).inMilliseconds < 500) return;
    _processing = true;
    _lastUpdate = now;
    try {
      final detected = await dominantColorFromFrame(image);
      if (!mounted) return;
      final delta = colorDelta(detected, _target);
      state = LiveColorState(detected: detected, delta: delta, verdict: verdictFromDelta(delta));
    } finally {
      _processing = false;
    }
  }
}

final liveColorProvider =
    StateNotifierProvider.autoDispose.family<LiveColorNotifier, LiveColorState, Color>(
  (ref, targetColor) => LiveColorNotifier(targetColor),
);

// ── Capture result ───────────────────────────────────────────────────────────

class CaptureResult {
  final String photoPath;
  final Color detected;
  final double delta;
  final ColorVerdict verdict;
  const CaptureResult({required this.photoPath, required this.detected, required this.delta, required this.verdict});

  /// Score de matching 0..100 (plus haut = plus fidèle) pour le scoring v2.
  int get score => (100 - delta).clamp(0, 100).round();
}

Future<CaptureResult> capturePhoto(CameraController ctrl, Color targetColor) async {
  final file = await ctrl.takePicture();
  final bytes = await file.readAsBytes();
  final detected = await _averageColorFromJpeg(bytes);
  final delta = colorDelta(detected, targetColor);
  return CaptureResult(photoPath: file.path, detected: detected, delta: delta, verdict: verdictFromDelta(delta));
}

// Quick average colour from JPEG bytes (heuristic, no extra packages).
Future<Color> _averageColorFromJpeg(List<int> bytes) async {
  final start = bytes.length ~/ 3;
  final end = (bytes.length * 2) ~/ 3;
  int rSum = 0, gSum = 0, bSum = 0, count = 0;
  for (int i = start; i < end - 2; i += 50) {
    rSum += bytes[i].clamp(0, 255);
    gSum += bytes[i + 1].clamp(0, 255);
    bSum += bytes[i + 2].clamp(0, 255);
    count++;
  }
  if (count == 0) return Colors.grey;
  return Color.fromARGB(255, rSum ~/ count, gSum ~/ count, bSum ~/ count);
}
