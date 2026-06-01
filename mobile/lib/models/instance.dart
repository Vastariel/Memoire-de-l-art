// ignore_for_file: unused_import
import 'zone.dart';

class Player {
  final String id;
  final String pseudo;
  final String avatarPigment;    // pigment key for avatar color
  final bool isMe;
  final String? todayZoneId;
  final bool hasContributedToday;

  const Player({
    required this.id,
    required this.pseudo,
    required this.avatarPigment,
    this.isMe = false,
    this.todayZoneId,
    this.hasContributedToday = false,
  });

  factory Player.fromJson(Map<String, dynamic> json, {String? myId}) => Player(
    id:                  json['id'] as String,
    pseudo:              (json['pseudo'] as String?) ?? 'Anonyme',
    avatarPigment:       (json['avatarPigment'] as String?) ?? (json['avatar_pigment'] as String?) ?? 'cobalt',
    isMe:                json['isMe'] as bool? ?? json['id'] == myId,
    hasContributedToday: json['hasContributedToday'] as bool? ?? json['has_contributed_today'] as bool? ?? false,
    todayZoneId:         json['todayZoneId'] as String?,
  );
}

class Instance {
  final String code;
  final String name;       // user-defined label
  final String artworkId;
  final int year;
  final int month;
  final List<Player> players;
  final int dayNumber;
  final int daysInMonth;

  const Instance({
    required this.code,
    required this.artworkId,
    required this.year,
    required this.month,
    required this.players,
    required this.dayNumber,
    required this.daysInMonth,
    this.name = '',
  });

  bool get isMonthComplete => dayNumber >= daysInMonth;

  Instance copyWith({String? code, String? name}) => Instance(
    code:        code ?? this.code,
    name:        name ?? this.name,
    artworkId:   artworkId,
    year:        year,
    month:       month,
    players:     players,
    dayNumber:   dayNumber,
    daysInMonth: daysInMonth,
  );

  factory Instance.fromJson(Map<String, dynamic> json, {String? myId}) => Instance(
    code: json['code'] as String,
    artworkId: json['artwork_id'] as String,
    year: json['year'] as int,
    month: json['month'] as int,
    players: (json['players'] as List)
        .map((p) => Player.fromJson(p as Map<String, dynamic>, myId: myId))
        .toList(),
    dayNumber: json['day_number'] as int,
    daysInMonth: json['days_in_month'] as int,
  );

  static String monthLabel(int month) {
    const labels = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
    ];
    return labels[month.clamp(1, 12)];
  }
}
