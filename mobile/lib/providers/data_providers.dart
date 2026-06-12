// data_providers.dart — read providers backed by the API (mock fallback).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_data.dart';
import '../engine/mosaic_engine.dart';
import '../models/game_models.dart';
import 'api_provider.dart';

// ── Current week's artwork (cells) — drives the mosaic from the API ─────────
final artworkDataProvider = FutureProvider<ArtworkData>((ref) async {
  if (!ref.watch(useApiProvider)) return kArtwork;
  try {
    final w = await ref.watch(apiClientProvider).weeksCurrent();
    final a = w['artwork'] as Map?;
    final cells = (a?['cells'] as List?) ?? const [];
    if (a == null || cells.isEmpty) return kArtwork;
    final list = cells.map((c) {
      final m = c as Map;
      return ArtCell((m['i'] as num).toInt(), (m['col'] as num).toInt(), (m['row'] as num).toInt(),
          m['family'] as String, m['variant'] as String);
    }).toList();
    return ArtworkData((a['cols'] as num?)?.toInt() ?? kCols, (a['rows'] as num?)?.toInt() ?? kRows, list);
  } catch (_) {
    return kArtwork;
  }
});

// ── Weekly leaderboard for an instance ──────────────────────────────────────
final leaderboardProvider = FutureProvider.family<List<LeaderEntry>, String>((ref, instanceId) async {
  if (!ref.watch(useApiProvider) || instanceId.isEmpty) return MockData.members;
  try {
    final rows = await ref.watch(apiClientProvider).leaderboard(instanceId);
    if (rows.isEmpty) return const [];
    return rows.map((r) {
      final m = r as Map<String, dynamic>;
      return LeaderEntry(
        pseudo: (m['pseudo'] as String?) ?? 'Anonyme',
        pig: (m['pig'] as String?) ?? 'ardoise',
        points: (m['points'] as num?)?.toInt() ?? 0,
        streak: (m['streak'] as num?)?.toInt() ?? 0,
        photos: (m['photos'] as num?)?.toInt() ?? 0,
        you: m['you'] == true,
      );
    }).toList();
  } catch (_) {
    return MockData.members;
  }
});

// ── Personal collection ─────────────────────────────────────────────────────
final collectionProvider = FutureProvider<List<CollectionItem>>((ref) async {
  if (!ref.watch(useApiProvider)) return MockData.gallery;
  try {
    final rows = await ref.watch(apiClientProvider).collection();
    return rows.map((r) {
      final m = r as Map<String, dynamic>;
      return CollectionItem(
        id: (m['id'] as String).hashCode,
        title: (m['title'] as String?) ?? '—',
        artist: (m['artist'] as String?) ?? '',
        year: (m['year'] as num?)?.toInt() ?? 0,
        week: (m['week'] as num?)?.toInt() ?? 0,
        unlocked: m['unlocked'] == true,
        seed: _seedFor(m['id'] as String),
      );
    }).toList();
  } catch (_) {
    return MockData.gallery;
  }
});

const _palette = ['cobalt', 'safran', 'veronese', 'sienne', 'rose', 'vermillon', 'ardoise', 'azur', 'ambre', 'prune'];
List<String> _seedFor(String id) {
  final h = id.hashCode.abs();
  return [_palette[h % _palette.length], _palette[(h ~/ 7) % _palette.length], _palette[(h ~/ 53) % _palette.length]];
}

// ── Contributions filled in an instance (variantKey → author/score/id) ──────
class FilledInfo {
  final String pseudo;
  final int score;
  final String? contributionId; // null when from mock / no id
  const FilledInfo(this.pseudo, this.score, this.contributionId);
}

final instanceFillProvider = FutureProvider.family<Map<String, FilledInfo>, String>((ref, instanceId) async {
  Map<String, FilledInfo> mock() =>
      {for (final e in MockData.contributors.entries) e.key: FilledInfo(e.value.pseudo, e.value.score, null)};
  if (!ref.watch(useApiProvider) || instanceId.isEmpty) return mock();
  try {
    final art = await ref.watch(apiClientProvider).instanceArtwork(instanceId);
    final map = <String, FilledInfo>{};
    for (final f in (art['filled'] as List? ?? const [])) {
      final m = f as Map;
      final vk = m['variantKey'] as String?;
      if (vk == null) continue;
      final delta = (m['deltaE'] as num?)?.toDouble() ?? 30;
      map[vk] = FilledInfo(
        (m['pseudo'] as String?) ?? '—',
        (100 - delta).clamp(0, 100).round(),
        m['contributionId'] as String?,
      );
    }
    return map;
  } catch (_) {
    return mock();
  }
});
