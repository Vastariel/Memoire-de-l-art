// game_provider.dart — état de jeu de la semaine (Phase 1 : données simulées).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_data.dart';
import '../engine/mosaic_engine.dart';
import '../models/game_models.dart';

class GameState {
  final int week;
  final int weekDay; // 1..7
  final String todayFamily;
  final String myVariant;
  final Set<String> filled; // familles contribuées
  final int points;
  final int streak;
  final Bet? bet;
  final List<InstanceSummary> instances;
  final String activeInstanceId;
  final List<DailyTask> tasks;
  // transitoire (capture en cours)
  final String? captureTaskId;
  final int lastScore;
  final int lastPoints;

  const GameState({
    required this.week,
    required this.weekDay,
    required this.todayFamily,
    required this.myVariant,
    required this.filled,
    required this.points,
    required this.streak,
    required this.bet,
    required this.instances,
    required this.activeInstanceId,
    required this.tasks,
    this.captureTaskId,
    this.lastScore = 0,
    this.lastPoints = 0,
  });

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

  InstanceSummary get activeInstance =>
      instances.firstWhere((i) => i.id == activeInstanceId, orElse: () => instances.first);

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
    Bet? bet,
    bool clearBet = false,
    List<DailyTask>? tasks,
    String? captureTaskId,
    int? lastScore,
    int? lastPoints,
  }) =>
      GameState(
        week: week,
        weekDay: weekDay,
        todayFamily: todayFamily,
        myVariant: myVariant ?? this.myVariant,
        filled: filled ?? this.filled,
        points: points ?? this.points,
        streak: streak ?? this.streak,
        bet: clearBet ? null : (bet ?? this.bet),
        instances: instances,
        activeInstanceId: activeInstanceId,
        tasks: tasks ?? this.tasks,
        captureTaskId: captureTaskId ?? this.captureTaskId,
        lastScore: lastScore ?? this.lastScore,
        lastPoints: lastPoints ?? this.lastPoints,
      );
}

class GameNotifier extends StateNotifier<GameState> {
  GameNotifier() : super(GameState.initial());

  void claimVariant(String v) => state = state.copyWith(myVariant: v);

  void setCaptureTask(DailyTask task) => state = state.copyWith(captureTaskId: task.id);

  /// Score de matching → points (port de app.jsx captureDone).
  void captureDone(int score) {
    final bonus = (score * 0.6).round();
    final pts = 60 + bonus + (state.streak > 0 ? 20 : 0);
    state = state.copyWith(lastScore: score, lastPoints: pts);
  }

  /// Valide la contribution : marque la tâche faite, remplit la famille si
  /// la photo partagée est posée, crédite les points (port de confirmDone).
  void confirmDone() {
    final task = state.currentTask;
    if (task == null) return;
    final tasks = state.tasks.map((t) => t.id == task.id ? t.copyWith(done: true) : t).toList();
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

  void placeBet(String title) => state = state.copyWith(bet: Bet(title, state.weekDay));
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) => GameNotifier());
