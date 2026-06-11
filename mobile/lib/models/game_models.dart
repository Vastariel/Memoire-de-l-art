// game_models.dart — modèles du domaine v2 (immutables).

enum InstanceMode { shared, separate }

extension InstanceModeX on InstanceMode {
  bool get isShared => this == InstanceMode.shared;
}

/// Résumé d'une instance pour les listes / le hero classement.
class InstanceSummary {
  final String id;
  final String name;
  final InstanceMode mode;
  final int members;
  final int place;
  final bool solo;

  const InstanceSummary({
    required this.id,
    required this.name,
    required this.mode,
    required this.members,
    this.place = 1,
    this.solo = false,
  });
}

/// Une « photo à faire aujourd'hui ».
class DailyTask {
  final String id;
  final InstanceMode kind;
  final String variant; // clé de variante (engine)
  final List<String> covers; // ids d'instances nourries (shared)
  final String? instanceId; // pour separate
  final String? instanceName; // pour separate
  final bool done;

  const DailyTask({
    required this.id,
    required this.kind,
    required this.variant,
    this.covers = const [],
    this.instanceId,
    this.instanceName,
    this.done = false,
  });

  bool get isSeparate => kind == InstanceMode.separate;

  DailyTask copyWith({bool? done}) => DailyTask(
        id: id,
        kind: kind,
        variant: variant,
        covers: covers,
        instanceId: instanceId,
        instanceName: instanceName,
        done: done ?? this.done,
      );
}

/// Ligne de classement.
class LeaderEntry {
  final String pseudo;
  final String pig; // clé pigment de l'avatar
  final int points;
  final int streak;
  final int photos;
  final bool you;

  const LeaderEntry({
    required this.pseudo,
    required this.pig,
    required this.points,
    required this.streak,
    required this.photos,
    this.you = false,
  });
}

/// Œuvre du musée perso (collection).
class CollectionItem {
  final int id;
  final String title;
  final String artist;
  final int year;
  final int week;
  final bool unlocked;
  final List<String> seed; // clés pigment pour la vignette

  const CollectionItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.year,
    required this.week,
    required this.unlocked,
    required this.seed,
  });
}

/// Option de pari (œuvre mystère).
class BetOption {
  final String id;
  final String title;
  final String artist;
  final int year;
  const BetOption(this.id, this.title, this.artist, this.year);
}

/// Pari posé.
class Bet {
  final String title;
  final int day;
  const Bet(this.title, this.day);
}

/// Contribution d'un bloc (détail vitrail) indexée par variante.
class BlockContribution {
  final String pseudo;
  final String date;
  final int score;
  const BlockContribution(this.pseudo, this.date, this.score);
}
