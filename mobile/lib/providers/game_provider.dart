// game_provider.dart — état de jeu de la semaine (Phase 1 : données simulées).

import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_data.dart';
import '../engine/mosaic_engine.dart';
import '../models/game_models.dart';
import '../services/api_client.dart';
import 'api_provider.dart';

class GameState {
  final int week;
  final int weekDay; // 1..7
  final String todayFamily;
  final String myVariant;
  final Set<String> filled; // familles contribuées
  final int points;
  final int streak;
  final int works; // œuvres débloquées dans la collection
  final List<String> activity; // jours avec photo (ISO yyyy-mm-dd, 28 derniers jours)
  final Bet? bet;
  final List<InstanceSummary> instances;
  final String activeInstanceId;
  final List<DailyTask> tasks;
  // transitoire (capture en cours)
  final String? captureTaskId;
  // transitoire (rattrapage en cours) — famille d'un jour passé
  final String? catchupFamily;
  final int catchupDay;
  final String? catchupVariant;
  final int lastScore;
  final int lastPoints;
  final String? lastError;

  const GameState({
    required this.week,
    required this.weekDay,
    required this.todayFamily,
    required this.myVariant,
    required this.filled,
    required this.points,
    required this.streak,
    this.works = 0,
    this.activity = const [],
    required this.bet,
    required this.instances,
    required this.activeInstanceId,
    required this.tasks,
    this.captureTaskId,
    this.catchupFamily,
    this.catchupDay = 0,
    this.catchupVariant,
    this.lastScore = 0,
    this.lastPoints = 0,
    this.lastError,
  });

  bool get isCatchup => catchupFamily != null;

  factory GameState.initial() => GameState(
        week: MockData.week,
        weekDay: MockData.weekDay,
        todayFamily: familyKeyOfDay(MockData.weekDay) ?? 'verts',
        myVariant: 'olive',
        filled: {'bleus'},
        points: MockData.points,
        streak: MockData.streak,
        bet: null,
        instances: MockData.instances,
        activeInstanceId: MockData.activeInstance,
        tasks: MockData.tasks,
      );

  int get doneCount => filled.length;
  int get tasksLeft => tasks.where((t) => !t.done).length;

  InstanceSummary get activeInstance {
    if (instances.isEmpty) {
      return const InstanceSummary(id: '', name: '—', mode: InstanceMode.shared, members: 1);
    }
    return instances.firstWhere((i) => i.id == activeInstanceId, orElse: () => instances.first);
  }

  /// Familles des jours passés non couvertes (rattrapage).
  List<String> get missedFamilies {
    final out = <String>[];
    for (var d = 1; d < weekDay; d++) {
      final f = familyKeyOfDay(d);
      if (f != null && !filled.contains(f)) out.add(f);
    }
    return out;
  }

  DailyTask? get currentTask {
    if (captureTaskId == null) return tasks.isNotEmpty ? tasks.first : null;
    for (final t in tasks) {
      if (t.id == captureTaskId) return t;
    }
    return tasks.isNotEmpty ? tasks.first : null;
  }

  GameState copyWith({
    String? myVariant,
    Set<String>? filled,
    int? points,
    int? streak,
    int? works,
    List<String>? activity,
    Bet? bet,
    bool clearBet = false,
    List<DailyTask>? tasks,
    String? captureTaskId,
    String? catchupFamily,
    int? catchupDay,
    String? catchupVariant,
    bool clearCatchup = false,
    int? lastScore,
    int? lastPoints,
    String? lastError,
    bool clearError = false,
  }) =>
      GameState(
        week: week,
        weekDay: weekDay,
        todayFamily: todayFamily,
        myVariant: myVariant ?? this.myVariant,
        filled: filled ?? this.filled,
        points: points ?? this.points,
        streak: streak ?? this.streak,
        works: works ?? this.works,
        activity: activity ?? this.activity,
        bet: clearBet ? null : (bet ?? this.bet),
        instances: instances,
        activeInstanceId: activeInstanceId,
        tasks: tasks ?? this.tasks,
        captureTaskId: captureTaskId ?? this.captureTaskId,
        catchupFamily: clearCatchup ? null : (catchupFamily ?? this.catchupFamily),
        catchupDay: clearCatchup ? 0 : (catchupDay ?? this.catchupDay),
        catchupVariant: clearCatchup ? null : (catchupVariant ?? this.catchupVariant),
        lastScore: lastScore ?? this.lastScore,
        lastPoints: lastPoints ?? this.lastPoints,
        lastError: clearError ? null : (lastError ?? this.lastError),
      );
}

class GameNotifier extends StateNotifier<GameState> {
  GameNotifier(this._api, this._useApi) : super(GameState.initial());
  final ApiClient _api;
  final bool _useApi;
  bool _uploadedOnline = false; // last capture was submitted to the server

  /// Build the week's state from the live API (falls back to mock on error).
  Future<void> loadFromApi() async {
    if (!_useApi) return;
    try {
      final week = await _api.weeksCurrent();
      final today = await _api.daysToday();
      final mine = await _api.instancesMine();
      final me = await _api.me();

      final instances = mine.map((m) => _parseInstance(m as Map<String, dynamic>)).toList();
      final activeId = instances.isEmpty
          ? ''
          : instances.firstWhere((i) => !i.solo, orElse: () => instances.first).id;

      final claims = (today['claims'] as List?) ?? const [];
      final variantsList = ((today['variants'] as List?) ?? const [])
          .map((v) => (v as Map)['key'] as String)
          .toList();
      String? claimed;
      for (final c in claims) {
        if ((c as Map)['instanceId'] == activeId) {
          claimed = c['variantKey'] as String?;
          break;
        }
      }
      final myVariant = claimed ?? (variantsList.isNotEmpty ? variantsList.first : state.myVariant);

      // Restore today's submissions so tasks don't reset on relaunch.
      final submittedShared = today['submittedShared'] == true;
      final submittedSeparate =
          ((today['submittedSeparate'] as List?) ?? const []).whereType<String>().toSet();

      final sharedIds = instances.where((i) => i.mode == InstanceMode.shared).map((i) => i.id).toList();
      final tasks = <DailyTask>[
        if (sharedIds.isNotEmpty)
          DailyTask(
              id: 'shared', kind: InstanceMode.shared, variant: myVariant, covers: sharedIds, done: submittedShared),
        for (final i in instances.where((i) => i.mode == InstanceMode.separate))
          DailyTask(
              id: i.id,
              kind: InstanceMode.separate,
              variant: myVariant,
              instanceId: i.id,
              instanceName: i.name,
              done: submittedSeparate.contains(i.id)),
      ];

      // Restore the weekly bet (editable until reveal).
      Bet? bet;
      try {
        final gMine = await _api.myGuess();
        if (gMine != null) {
          bet = Bet(
            (gMine['titleGuess'] as String?) ?? '',
            (gMine['dayPlaced'] as num?)?.toInt() ?? 1,
            correct: gMine['correct'] as bool?,
            points: (gMine['points'] as num?)?.toInt() ?? 0,
          );
        }
      } catch (_) {/* keep null */}

      // Filled families = variants already contributed in the active instance.
      final filled = <String>{};
      if (activeId.isNotEmpty) {
        try {
          final art = await _api.instanceArtwork(activeId);
          for (final f in (art['filled'] as List? ?? const [])) {
            final vk = (f as Map)['variantKey'] as String?;
            final fam = vk == null ? null : kVariants[vk]?.family;
            if (fam != null) filled.add(fam);
          }
        } catch (_) {/* leave empty */}
      }

      state = GameState(
        week: ((week['artwork'] as Map?)?['isoWeek'] as num?)?.toInt() ?? state.week,
        weekDay: (today['weekDay'] as num?)?.toInt() ?? state.weekDay,
        todayFamily: ((today['family'] as Map?)?['key'] as String?) ?? state.todayFamily,
        myVariant: myVariant,
        filled: filled,
        points: (me['points'] as num?)?.toInt() ?? 0,
        streak: (me['streak'] as num?)?.toInt() ?? 0,
        works: (me['works'] as num?)?.toInt() ?? 0,
        activity: ((me['activity'] as List?) ?? const []).whereType<String>().toList(),
        bet: bet,
        instances: instances,
        activeInstanceId: activeId,
        tasks: tasks,
      );
    } catch (_) {/* keep current (mock) state */}
  }

  InstanceSummary _parseInstance(Map<String, dynamic> m) => InstanceSummary(
        id: m['id'] as String,
        code: (m['code'] as String?) ?? '',
        name: (m['name'] as String?) ?? '',
        mode: m['mode'] == 'separate' ? InstanceMode.separate : InstanceMode.shared,
        members: (m['members'] as num?)?.toInt() ?? 1,
        place: (m['place'] as num?)?.toInt() ?? 1,
        solo: m['solo'] == true,
      );

  void claimVariant(String v) {
    state = state.copyWith(myVariant: v);
    if (_useApi && state.activeInstanceId.isNotEmpty) {
      _api.claim(state.activeInstanceId, v).catchError((_) {});
    }
  }

  void setCaptureTask(DailyTask task) =>
      state = state.copyWith(captureTaskId: task.id, clearCatchup: true);

  /// Rattrapage : prépare la capture pour une famille d'un jour passé.
  /// Choisit la variante déjà réclamée dans cette famille (instance active),
  /// sinon la variante médiane par défaut.
  Future<void> setCatchupTask(String family) async {
    final fam = kFamilies[family];
    if (fam == null) return;
    var variant = fam.variants.length > 1 ? fam.variants[1] : fam.variants.first;
    if (_useApi && state.activeInstanceId.isNotEmpty) {
      try {
        final claims = await _api.claims(state.activeInstanceId);
        for (final c in claims) {
          final vk = (c as Map)['variantKey'] as String?;
          if (vk != null && kVariants[vk]?.family == family) {
            variant = vk;
            break;
          }
        }
      } catch (_) {/* fall back to default variant */}
    }
    state = state.copyWith(
      catchupFamily: family,
      catchupDay: fam.day,
      catchupVariant: variant,
    );
  }

  /// Capture done. Online + a real photo file → upload it (server computes
  /// ΔE/variance/score/points). Otherwise use the simulated score.
  Future<void> captureDone({String? photoPath, required int fallbackScore}) async {
    String? err;
    if (!_useApi) {
      err = 'Mode hors-ligne actif (USE_API=false).';
    } else if (photoPath == null) {
      err = 'Aucun fichier photo (caméra simulée).';
    } else if (state.activeInstanceId.isEmpty) {
      err = 'Aucune instance active — crée ou rejoins une instance.';
    } else {
      final task = state.currentTask;
      final sep = !state.isCatchup && (task?.isSeparate ?? false);
      try {
        final r = await _api.submitPhoto(
          filePath: photoPath,
          day: state.isCatchup ? state.catchupDay : state.weekDay,
          variantKey: state.isCatchup
              ? (state.catchupVariant ?? state.myVariant)
              : (task?.variant ?? state.myVariant),
          shared: !sep,
          separateInstanceId: sep ? task?.instanceId : null,
          catchup: state.isCatchup,
        );
        _uploadedOnline = true;
        state = state.copyWith(
          lastScore: (r['score'] as num?)?.toInt() ?? fallbackScore,
          lastPoints: (r['points'] as num?)?.toInt() ?? 0,
          streak: (r['streak'] as num?)?.toInt() ?? state.streak,
          clearError: true,
        );
        return;
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        final body = e.response?.data;
        err = 'Upload HTTP ${code ?? '?'} : ${body ?? e.message ?? e.type.name}';
        developer.log(err, name: 'mda.upload', error: e);
      } catch (e, st) {
        err = 'Upload : $e';
        developer.log(err, name: 'mda.upload', error: e, stackTrace: st);
      }
    }
    _uploadedOnline = false;
    final bonus = (fallbackScore * 0.6).round();
    final pts = 60 + bonus + (state.streak > 0 ? 20 : 0);
    state = state.copyWith(lastScore: fallbackScore, lastPoints: pts, lastError: err);
  }

  /// Validate the contribution. Online → just refresh from the server (the
  /// upload already created the contribution & points). Offline → optimistic.
  Future<void> confirmDone() async {
    // Rattrapage : pas de tâche du jour — marque la famille couverte.
    if (state.isCatchup) {
      final fam = state.catchupFamily!;
      if (_uploadedOnline) {
        state = state.copyWith(clearCatchup: true);
        await loadFromApi();
      } else {
        state = state.copyWith(
          filled: {...state.filled, fam},
          points: state.points + state.lastPoints,
          clearCatchup: true,
        );
      }
      return;
    }
    final task = state.currentTask;
    if (task == null) return;
    final tasks = state.tasks.map((t) => t.id == task.id ? t.copyWith(done: true) : t).toList();
    if (_uploadedOnline) {
      state = state.copyWith(tasks: tasks);
      await loadFromApi();
      return;
    }
    final sharedDone = tasks.firstWhere(
      (t) => t.id == 'shared',
      orElse: () => const DailyTask(id: '_', kind: InstanceMode.shared, variant: ''),
    ).done;
    state = state.copyWith(
      tasks: tasks,
      filled: sharedDone ? {...state.filled, state.todayFamily} : state.filled,
      points: state.points + state.lastPoints,
    );
  }

  // Barème dégressif du pari (lun→dim) — miroir de scoring.ts.
  static const _betBareme = [70, 50, 35, 25, 15, 10, 5];

  void placeBet(String title) {
    // day_placed du serveur garde la première pose ; localement on conserve
    // le jour du pari existant le cas échéant.
    final day = state.bet?.day ?? state.weekDay;
    state = state.copyWith(bet: Bet(title, day, points: _betBareme[(day - 1).clamp(0, 6)]));
    if (_useApi) _api.placeGuess(title).catchError((_) {});
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>(
  (ref) => GameNotifier(ref.read(apiClientProvider), ref.read(useApiProvider)),
);
