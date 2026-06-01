import 'dart:convert';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/artwork.dart';
import '../models/zone.dart';

const _keyArtwork        = 'solo_artwork_v1';
const _keyContributions  = 'solo_contributions_v1';

// ── Photo persistence ─────────────────────────────────────────────────────────

/// Compress and persist a photo to permanent app storage.
/// Returns the compressed file path; falls back to a plain copy on error.
Future<String> persistPhoto(String tempPath, String zoneId) async {
  try {
    final dir  = await getApplicationDocumentsDirectory();
    final dest = '${dir.path}/mda_${zoneId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      tempPath, dest,
      minWidth:  1920,
      minHeight: 1920,
      quality:   82,
      keepExif:  false,
    );
    if (result != null) return result.path;
    // Fallback: plain copy if compression fails
    await File(tempPath).copy(dest);
    return dest;
  } catch (_) {
    return tempPath;
  }
}

/// Delete a locally stored photo file (zone replacement).
Future<void> deletePhoto(String? path) async {
  if (path == null || path.startsWith('http')) return;
  try { await File(path).delete(); } catch (_) {}
}

// ── Artwork storage ───────────────────────────────────────────────────────────

/// Persist the current artwork (solo mode) to SharedPreferences.
Future<void> saveArtwork(Artwork artwork) async {
  final prefs = await SharedPreferences.getInstance();
  final cells = artwork.cells.map((c) => {
    'index': c.index, 'col': c.col, 'row': c.row, 'zoneId': c.zoneId,
  }).toList();
  final zones = artwork.zones.map((k, z) => MapEntry(k, {
    ...z.pigment.toJson(),
    'id': z.id, 'cellCount': z.cellCount,
  }));
  await prefs.setString(_keyArtwork, jsonEncode({
    'id':    artwork.id,
    'cols':  artwork.cols,
    'rows':  artwork.rows,
    'cells': cells,
    'zones': zones,
    if (artwork.title       != null) 'title':       artwork.title,
    if (artwork.artist      != null) 'artist':      artwork.artist,
    if (artwork.description != null) 'description': artwork.description,
    if (artwork.year        != 0)    'year':        artwork.year,
  }));
}

/// Parse an artwork from admin-generated JSON.
/// Returns null if the JSON is invalid.
Artwork? parseArtworkJson(String json) {
  try {
    final data = jsonDecode(json) as Map<String, dynamic>;
    return _artworkFromMap(data);
  } catch (_) {
    return null;
  }
}

/// Load the saved artwork from SharedPreferences (null = use bundled default).
Future<Artwork?> loadSavedArtwork() async {
  final prefs = await SharedPreferences.getInstance();
  final raw   = prefs.getString(_keyArtwork);
  if (raw == null) return null;
  try { return _artworkFromMap(jsonDecode(raw) as Map<String, dynamic>); }
  catch (_) { return null; }
}

Artwork _artworkFromMap(Map<String, dynamic> data) {
  final cellsData = (data['cells'] as List).cast<Map<String, dynamic>>();
  final zonesData = (data['zones'] as Map<String, dynamic>);

  final zones = <String, Zone>{};
  for (final entry in zonesData.entries) {
    final z = entry.value as Map<String, dynamic>;
    // Support both new format (targetHex present) and legacy (pigment name only)
    final ZoneColor color;
    if (z['targetHex'] != null) {
      color = ZoneColor.fromJson(z);
    } else {
      color = ZoneColor.fromLegacyPigment(z['pigment'] as String? ?? 'slate');
    }
    zones[entry.key] = Zone(
      id:        z['id'] as String,
      pigment:   color,
      cellCount: z['cellCount'] as int,
    );
  }

  return Artwork(
    id:          data['id']   as String,
    cols:        data['cols'] as int,
    rows:        data['rows'] as int,
    cells:       cellsData.map((c) => MosaicCell(
      index:  c['index']  as int,
      col:    c['col']    as int,
      row:    c['row']    as int,
      zoneId: c['zoneId'] as String,
    )).toList(),
    zones: zones,
    title:       data['title']       as String?,
    artist:      data['artist']      as String?,
    description: data['description'] as String?,
    year:        data['year']        as int? ?? 0,
  );
}

// ── Contribution persistence (solo mode) ─────────────────────────────────────

/// Save all contributions for the current solo artwork.
Future<void> saveContributions(Map<String, ZoneContribution> contribs) async {
  final prefs = await SharedPreferences.getInstance();
  final map   = contribs.map((k, v) => MapEntry(k, {
    'playerPseudo': v.playerPseudo,
    'playerAvatar': v.playerAvatar,
    'contributedAt': v.contributedAt.toIso8601String(),
    if (v.photoUrl != null) 'photoUrl': v.photoUrl,
  }));
  await prefs.setString(_keyContributions, jsonEncode(map));
}

/// Load saved contributions (keyed by zoneId).
Future<Map<String, ZoneContribution>> loadContributions() async {
  final prefs = await SharedPreferences.getInstance();
  final raw   = prefs.getString(_keyContributions);
  if (raw == null) return {};
  try {
    final map = (jsonDecode(raw) as Map<String, dynamic>);
    return map.map((k, v) {
      final m = v as Map<String, dynamic>;
      return MapEntry(k, ZoneContribution(
        playerPseudo:  m['playerPseudo'] as String,
        playerAvatar:  m['playerAvatar'] as String,
        contributedAt: DateTime.parse(m['contributedAt'] as String),
        photoUrl:      m['photoUrl']     as String?,
      ));
    });
  } catch (_) { return {}; }
}

/// Clear all solo data (used by "delete data" in settings).
Future<void> clearSoloData() async {
  final prefs = await SharedPreferences.getInstance();
  // Delete persisted photos
  final contribsRaw = prefs.getString(_keyContributions);
  if (contribsRaw != null) {
    try {
      final map = jsonDecode(contribsRaw) as Map<String, dynamic>;
      for (final v in map.values) {
        final url = (v as Map<String, dynamic>)['photoUrl'] as String?;
        await deletePhoto(url);
      }
    } catch (_) {}
  }
  await prefs.remove(_keyArtwork);
  await prefs.remove(_keyContributions);
}
