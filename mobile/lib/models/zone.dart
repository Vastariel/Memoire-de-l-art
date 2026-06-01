import 'package:flutter/material.dart';
import '../theme/colors.dart';

// ── ZoneColor — replaces the fixed Pigment enum ──────────────────────────────
// Colors come from k-means centroids on the server; labels are evocative names.

class ZoneColor {
  final String id;      // e.g. "zone-03"
  final String label;   // e.g. "Mer du Nord"
  final Color  color;

  const ZoneColor({required this.id, required this.label, required this.color});

  factory ZoneColor.fromJson(Map<String, dynamic> json) {
    final hex = (json['targetHex'] as String?) ?? '#808080';
    return ZoneColor(
      id:    (json['pigment']      as String?) ?? 'zone-01',
      label: (json['label']        as String?) ?? 'Teinte naturelle',
      color: _hexToColor(hex),
    );
  }

  // Backward compat: reconstruct from stored hex (solo data saved pre-migration)
  factory ZoneColor.fromHex(String id, String label, String hex) =>
      ZoneColor(id: id, label: label, color: _hexToColor(hex));

  // Legacy: map old Pigment enum names to a ZoneColor for pre-existing solo data
  static ZoneColor fromLegacyPigment(String pigmentName) {
    final color = MdaColors.pigments[pigmentName] ?? const Color(0xFF808080);
    return ZoneColor(id: pigmentName, label: pigmentName, color: color);
  }

  static Color _hexToColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  Map<String, dynamic> toJson() => {
    'pigment':   id,
    'label':     label,
    'targetHex': '#${color.toARGB32().toRadixString(16).substring(2)}',
  };
}

// ── ZoneContribution ──────────────────────────────────────────────────────────

class ZoneContribution {
  final String   playerPseudo;
  final String   playerAvatar;   // pigment key used for avatar color
  final DateTime contributedAt;
  final String?  photoUrl;

  const ZoneContribution({
    required this.playerPseudo,
    required this.playerAvatar,
    required this.contributedAt,
    this.photoUrl,
  });

  factory ZoneContribution.fromJson(Map<String, dynamic> json) =>
      ZoneContribution(
        playerPseudo:  json['player_pseudo']  as String,
        playerAvatar:  json['player_avatar']  as String,
        contributedAt: DateTime.parse(json['contributed_at'] as String),
        photoUrl:      json['photo_url']      as String?,
      );
}

// ── Zone ─────────────────────────────────────────────────────────────────────

class Zone {
  final String           id;
  final ZoneColor        pigment;     // field kept as 'pigment' to minimise diff
  final int              cellCount;
  final ZoneContribution? contribution;
  final bool             isToday;

  const Zone({
    required this.id,
    required this.pigment,
    required this.cellCount,
    this.contribution,
    this.isToday = false,
  });

  bool get isFilled => contribution != null;
  bool get isEmpty  => contribution == null && !isToday;

  Zone copyWith({ZoneContribution? contribution, bool? isToday}) => Zone(
    id:           id,
    pigment:      pigment,
    cellCount:    cellCount,
    contribution: contribution ?? this.contribution,
    isToday:      isToday ?? this.isToday,
  );

  factory Zone.fromJson(Map<String, dynamic> json) => Zone(
    id:        json['id']         as String,
    pigment:   ZoneColor.fromJson(json),
    cellCount: json['cell_count'] as int,
    contribution: json['contribution'] != null
        ? ZoneContribution.fromJson(json['contribution'] as Map<String, dynamic>)
        : null,
    isToday: json['is_today'] as bool? ?? false,
  );
}
