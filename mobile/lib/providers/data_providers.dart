// data_providers.dart — read providers backed by the API (mock fallback).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config.dart';
import '../data/mock_data.dart';
import '../engine/mosaic_engine.dart';
import '../models/game_models.dart';
import 'api_provider.dart';
import 'settings_provider.dart';

/// Photo URLs returned by the API are relative (`/api/v1/photos/file/:id`) so
/// the same DB row works for browser, mobile and tests. Prepend the API base
/// when handing the URL to Image.network.
String absolutePhotoUrl(String url) {
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  return '${AppConfig.apiBaseUrl}$url';
}

// ── Current week's metadata (status + cartel after reveal) ──────────────────
class WeekInfo {
  final String status; // draft | planned | active | revealed
  final String? title;
  final String? artist;
  final int? year;
  final String? description;
  const WeekInfo({this.status = 'active', this.title, this.artist, this.year, this.description});
  bool get revealed => status == 'revealed';
}

final weekInfoProvider = FutureProvider<WeekInfo>((ref) async {
  if (!ref.watch(useApiProvider)) return const WeekInfo();
  try {
    final w = await ref.watch(apiClientProvider).weeksCurrent(lang: ref.watch(langProvider));
    final a = w['artwork'] as Map?;
    if (a == null) return const WeekInfo();
    return WeekInfo(
      status: (a['status'] as String?) ?? 'active',
      title: a['title'] as String?,
      artist: a['artist'] as String?,
      year: (a['year'] as num?)?.toInt(),
      description: a['description'] as String?,
    );
  } catch (_) {
    return const WeekInfo();
  }
});

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
      // Cell map present only for unlocked works → faithful mini-mosaic.
      ArtworkData? art;
      final cells = m['cells'] as List?;
      if (cells != null && cells.isNotEmpty) {
        art = ArtworkData(
          (m['cols'] as num?)?.toInt() ?? kCols,
          (m['rows'] as num?)?.toInt() ?? kRows,
          cells.map((c) {
            final cm = c as Map;
            return ArtCell((cm['i'] as num).toInt(), (cm['col'] as num).toInt(), (cm['row'] as num).toInt(),
                cm['family'] as String, cm['variant'] as String);
          }).toList(),
        );
      }
      return CollectionItem(
        id: (m['id'] as String).hashCode,
        title: (m['title'] as String?) ?? '—',
        artist: (m['artist'] as String?) ?? '',
        year: (m['year'] as num?)?.toInt() ?? 0,
        week: (m['week'] as num?)?.toInt() ?? 0,
        unlocked: m['unlocked'] == true,
        seed: _seedFor(m['id'] as String),
        art: art,
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

// ── Mystery bet options (titles to pick from) ───────────────────────────────
final betOptionsProvider = FutureProvider<List<BetOption>>((ref) async {
  if (!ref.watch(useApiProvider)) return MockData.betOptions;
  try {
    final rows = await ref.watch(apiClientProvider).guessOptions();
    if (rows.isEmpty) return MockData.betOptions;
    return rows.map((r) {
      final m = r as Map<String, dynamic>;
      return BetOption(
        (m['id'] as String?) ?? '',
        (m['title'] as String?) ?? '—',
        (m['artist'] as String?) ?? '',
        (m['year'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  } catch (_) {
    return MockData.betOptions;
  }
});

// ── Claims (variantKey → pseudo of who took it) ─────────────────────────────
final claimsProvider = FutureProvider.family<Map<String, String>, String>((ref, instanceId) async {
  if (!ref.watch(useApiProvider) || instanceId.isEmpty) return const {};
  try {
    final rows = await ref.watch(apiClientProvider).claims(instanceId);
    final out = <String, String>{};
    for (final r in rows) {
      final m = r as Map<String, dynamic>;
      final vk = m['variantKey'] as String?;
      if (vk != null) out[vk] = (m['pseudo'] as String?) ?? 'Anonyme';
    }
    return out;
  } catch (_) {
    return const {};
  }
});

// ── Real photo gallery for an instance ──────────────────────────────────────
final instancePhotosProvider = FutureProvider.family<List<InstancePhoto>, String>((ref, instanceId) async {
  if (!ref.watch(useApiProvider) || instanceId.isEmpty) return const [];
  try {
    final art = await ref.watch(apiClientProvider).instanceArtwork(instanceId);
    final out = <InstancePhoto>[];
    for (final f in (art['filled'] as List? ?? const [])) {
      final m = f as Map;
      final url = m['url'] as String?;
      if (url == null || url.isEmpty) continue;
      out.add(InstancePhoto(
        contributionId: (m['contributionId'] as String?) ?? '',
        url: absolutePhotoUrl(url),
        pseudo: (m['pseudo'] as String?) ?? '—',
        pig: (m['pig'] as String?) ?? 'ardoise',
        variantKey: (m['variantKey'] as String?) ?? '',
        deltaE: (m['deltaE'] as num?)?.toDouble() ?? 30,
      ));
    }
    return out;
  } catch (_) {
    return const [];
  }
});

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
