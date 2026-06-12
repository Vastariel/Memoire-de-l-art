// data_providers.dart — read providers backed by the API (mock fallback).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_data.dart';
import '../models/game_models.dart';
import 'api_provider.dart';

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

// ── Contributions filled in an instance (variantKey → author/score) ─────────
final instanceFillProvider = FutureProvider.family<Map<String, BlockContribution>, String>((ref, instanceId) async {
  if (!ref.watch(useApiProvider) || instanceId.isEmpty) return MockData.contributors;
  try {
    final art = await ref.watch(apiClientProvider).instanceArtwork(instanceId);
    final map = <String, BlockContribution>{};
    for (final f in (art['filled'] as List? ?? const [])) {
      final m = f as Map;
      final vk = m['variantKey'] as String?;
      if (vk == null) continue;
      final delta = (m['deltaE'] as num?)?.toDouble() ?? 30;
      map[vk] = BlockContribution((m['pseudo'] as String?) ?? '—', '', (100 - delta).clamp(0, 100).round());
    }
    return map;
  } catch (_) {
    return MockData.contributors;
  }
});
