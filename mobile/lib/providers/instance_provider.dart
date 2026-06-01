import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/artwork.dart';
import '../models/instance.dart';
import '../models/zone.dart';
import '../services/api_client.dart';

// ── Session ───────────────────────────────────────────────────────────────────

class SessionState {
  final bool hasSession;
  final String? token;
  const SessionState({required this.hasSession, this.token});
  factory SessionState.none() => const SessionState(hasSession: false);
}

class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier() : super(SessionState.none());

  Future<bool> restore() async {
    final client = await ApiClient.get();
    final token  = await client.loadToken();
    if (token == null) return false;
    state = SessionState(hasSession: true, token: token);
    return true;
  }

  Future<void> save(String token) async {
    final client = await ApiClient.get();
    await client.saveSession(token);
    state = SessionState(hasSession: true, token: token);
  }

  Future<void> clear() async {
    final client = await ApiClient.get();
    await client.clearSession();
    state = SessionState.none();
  }
}

final sessionProvider =
    StateNotifierProvider<SessionNotifier, SessionState>((ref) => SessionNotifier());

// ── Instance state ─────────────────────────────────────────────────────────────

class InstanceState {
  final Instance instance;
  final Artwork  artwork;

  const InstanceState({required this.instance, required this.artwork});
}

class InstanceNotifier extends StateNotifier<AsyncValue<InstanceState>> {
  InstanceNotifier(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref _ref;
  static const _cacheKey = 'instance_state_cache';

  Future<void> _load() async {
    // Try cache first for instant UI
    final cached = await _fromCache();
    if (cached != null) state = AsyncValue.data(cached);

    // Then refresh from API
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final client = await ApiClient.get();
      final data   = await client.fetchInstanceState();
      final parsed = _parse(data);
      state = AsyncValue.data(parsed);
      await _toCache(data);
    } on Exception catch (e, st) {
      if (state is! AsyncData) {
        state = AsyncValue.error(e, st);
      }
      // Keep stale data if API fails — offline resilience
    }
  }

  // Called after submitting a photo — update today's zone locally
  void markZoneFilled(String zoneId, String playerPseudo, String playerAvatar) {
    final current = state.valueOrNull;
    if (current == null) return;
    final zones = Map<String, Zone>.from(current.artwork.zones);
    final zone  = zones[zoneId];
    if (zone == null) return;
    zones[zoneId] = zone.copyWith(
      isToday:      false,
      contribution: ZoneContribution(
        playerPseudo:  playerPseudo,
        playerAvatar:  playerAvatar,
        contributedAt: DateTime.now(),
      ),
    );
    state = AsyncValue.data(InstanceState(
      instance: current.instance,
      artwork:  Artwork(
        id:    current.artwork.id,
        cols:  current.artwork.cols,
        rows:  current.artwork.rows,
        cells: current.artwork.cells,
        zones: zones,
      ),
    ));
  }

  static InstanceState _parse(Map<String, dynamic> data) {
    final artworkData = data['artwork'] as Map<String, dynamic>;
    final zonesData   = artworkData['zones'] as Map<String, dynamic>;
    final cellsData   = (artworkData['cells'] as List).cast<Map<String, dynamic>>();
    final playersData = (data['players'] as List).cast<Map<String, dynamic>>();

    final zones = <String, Zone>{};
    for (final entry in zonesData.entries) {
      final z = entry.value as Map<String, dynamic>;
      zones[entry.key] = Zone(
        id:        z['id'] as String,
        pigment:   ZoneColor.fromJson(z),
        cellCount: z['cellCount'] as int,
        isToday:   z['isToday'] as bool? ?? false,
        contribution: z['contribution'] == null ? null : ZoneContribution(
          playerPseudo:  (z['contribution']['playerPseudo'] as String?) ?? 'Anonyme',
          playerAvatar:  (z['contribution']['playerAvatar'] as String?) ?? 'slate',
          contributedAt: DateTime.parse(z['contribution']['contributedAt'] as String),
          photoUrl:       z['contribution']['photoUrl'] as String?,
        ),
      );
    }

    final cells = cellsData.map((c) => MosaicCell(
      index:  c['index'] as int,
      col:    c['col']   as int,
      row:    c['row']   as int,
      zoneId: c['zoneId'] as String,
    )).toList();

    final artwork = Artwork(
      id:   artworkData['id'] as String,
      cols: artworkData['cols'] as int,
      rows: artworkData['rows'] as int,
      cells: cells,
      zones: zones,
    );

    final players = playersData.map((p) => Player(
      id:                  p['id'] as String,
      pseudo:              (p['pseudo'] as String?) ?? 'Anonyme',
      avatarPigment:       p['avatarPigment'] as String? ?? 'slate',
      isMe:                p['isMe'] as bool? ?? false,
      hasContributedToday: p['hasContributedToday'] as bool? ?? false,
      todayZoneId:         p['todayZoneId'] as String?,
    )).toList();

    final instance = Instance(
      code:       data['code'] as String,
      artworkId:  data['artworkId'] as String,
      year:       data['year'] as int,
      month:      data['month'] as int,
      players:    players,
      dayNumber:  data['dayNumber'] as int,
      daysInMonth: data['daysInMonth'] as int,
    );

    return InstanceState(instance: instance, artwork: artwork);
  }

  Future<InstanceState?> _fromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final json  = prefs.getString(_cacheKey);
    if (json == null) return null;
    try {
      return _parse(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _toCache(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(data));
  }
}

final instanceProvider =
    StateNotifierProvider<InstanceNotifier, AsyncValue<InstanceState>>(
  (ref) => InstanceNotifier(ref),
);
