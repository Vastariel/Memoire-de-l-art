import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/artwork.dart';
import 'models/instance.dart';
import 'models/zone.dart';
import 'providers/camera_provider.dart';
import 'services/api_client.dart';
import 'services/local_storage.dart';
import 'services/session_manager.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/daily/daily_screen.dart';
import 'features/camera/camera_screen.dart';
import 'features/confirm/confirm_screen.dart';
import 'features/artwork/artwork_screen.dart';
import 'features/group/group_screen.dart'
    show GroupScreen, GroupInstanceData;
import 'features/profile/profile_screen.dart';
import 'features/reveal/reveal_screen.dart';
import 'features/settings/settings_screen.dart';
import 'widgets/mda_tab_bar.dart';
import 'main.dart';

enum AppRoute { onboarding, loading, daily, camera, confirm, artwork, group, profile, reveal, settings }

class MdaApp extends ConsumerStatefulWidget {
  const MdaApp({super.key});
  @override
  ConsumerState<MdaApp> createState() => _MdaAppState();
}

class _MdaAppState extends ConsumerState<MdaApp> {
  AppRoute       _route       = AppRoute.loading;
  CaptureResult? _lastCapture;
  String?        _apiError;
  String         _pseudo      = 'Toi';
  bool           _isSolo      = false;

  Artwork   _artwork   = _stubArtwork();
  Instance  _instance  = _stubInstance('Toi');

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  // ── Session restore ───────────────────────────────────────────

  Future<void> _restoreSession() async {
    final sm = SessionManager.instance;
    if (!sm.hasSession) {
      if (mounted) setState(() => _route = AppRoute.onboarding);
      return;
    }

    final saved = sm.current!;
    _isSolo = saved.isSolo;

    if (saved.isSolo) {
      await _restoreSoloSession(saved);
    } else {
      _stubApply(saved.pseudo, saved.code, saved.name);
      if (saved.token != null) _refreshFromApi(saved.token!).ignore();
    }

    if (mounted) setState(() => _route = AppRoute.daily);
  }

  Future<void> _restoreSoloSession(SavedInstance saved) async {
    _pseudo = saved.pseudo;
    // Load saved artwork (or use bundled default)
    final savedArtwork = await loadSavedArtwork();
    _artwork = savedArtwork ?? _stubArtwork();
    // Restore contributions
    final contribs = await loadContributions();
    for (final entry in contribs.entries) {
      final zone = _artwork.zones[entry.key];
      if (zone != null) {
        _artwork.zones[entry.key] = zone.copyWith(contribution: entry.value);
      }
    }
    // Assign today's zone
    _assignTodayZoneSolo();
    _instance = _soloInstance(saved.pseudo, saved.code, saved.name);
  }

  Future<void> _refreshFromApi(String token) async {
    try {
      final client = await ApiClient.get();
      final data   = await client.fetchInstanceState();
      if (mounted) {
        _applyInstanceData(data);
        setState(() {});
      }
    } catch (_) {}
  }

  // ── Solo mode ─────────────────────────────────────────────────

  Future<void> _onSolo(String pseudo, String? artworkJson) async {
    // Guard: only one solo instance allowed — switch to existing instead of creating.
    final existingIdx = SessionManager.instance.all.indexWhere((i) => i.isSolo);
    if (existingIdx >= 0) {
      await _switchInstance(existingIdx);
      return;
    }

    _isSolo = true;
    _pseudo = pseudo;

    // Parse artwork from JSON if provided, else use bundled default
    if (artworkJson != null && artworkJson.isNotEmpty) {
      final parsed = parseArtworkJson(artworkJson);
      if (parsed != null) {
        _artwork = parsed;
        await saveArtwork(_artwork);
      } else {
        _artwork = _stubArtwork();
        if (mounted) setState(() => _apiError = 'JSON invalide — œuvre par défaut utilisée.');
      }
    } else {
      _artwork = _stubArtwork();
    }

    // No previous contributions for a fresh solo session
    _assignTodayZoneSolo();
    const code = 'SOLO';
    _instance = _soloInstance(pseudo, code, '');

    await SessionManager.instance.addOrUpdate(SavedInstance(
      code: code, name: 'Solo', pseudo: pseudo,
      avatarPigment: 'sienna', isSolo: true,
    ));

    if (mounted) setState(() => _route = AppRoute.daily);
  }

  // Marks the smallest unfilled zone as "today" for solo play.
  void _assignTodayZoneSolo() {
    // Clear existing isToday flags
    for (final k in _artwork.zones.keys) {
      final z = _artwork.zones[k]!;
      if (z.isToday) _artwork.zones[k] = z.copyWith(isToday: false);
    }
    // Find smallest unfilled zone
    final unfilled = _artwork.zones.entries
        .where((e) => !e.value.isFilled)
        .toList()
      ..sort((a, b) => a.value.cellCount.compareTo(b.value.cellCount));
    if (unfilled.isNotEmpty) {
      final z = unfilled.first;
      _artwork.zones[z.key] = z.value.copyWith(isToday: true);
    }
  }

  Instance _soloInstance(String pseudo, String code, String name) => Instance(
    code: code, name: name.isNotEmpty ? name : 'Solo',
    artworkId: _artwork.id,
    year: DateTime.now().year, month: DateTime.now().month,
    dayNumber: DateTime.now().day,
    daysInMonth: DateUtils.getDaysInMonth(DateTime.now().year, DateTime.now().month),
    players: [
      Player(id: 'solo', pseudo: pseudo, avatarPigment: 'sienna', isMe: true,
          hasContributedToday: false),
    ],
  );

  // ── Join / Create ─────────────────────────────────────────────

  // code == null → create; code != null → join
  Future<void> _onJoin(String? code, String pseudo, String name) async {
    setState(() { _apiError = null; });
    try {
      final client = await ApiClient.get();
      final result = code == null
          ? await client.createInstance(pseudo: pseudo, name: name)
          : await client.joinInstance(code, pseudo: pseudo);
      await client.saveSession(result.token);

      final resolvedCode = (result.instance['code'] as String?) ?? code ?? 'LOCAL';
      await SessionManager.instance.addOrUpdate(SavedInstance(
        code:          resolvedCode,
        name:          name.isEmpty ? resolvedCode : name,
        pseudo:        pseudo,
        avatarPigment: 'sienna',
        token:         result.token,
        isCreator:     code == null,   // null = created, non-null = joined
      ));
      _applyInstanceData(result.instance);
      if (mounted) setState(() => _route = AppRoute.daily);
    } catch (_) {
      // Fallback: demo mode without backend
      final demoCode = code ?? 'DEMO';
      final demoName = name.isEmpty ? demoCode : name;
      await SessionManager.instance.addOrUpdate(SavedInstance(
        code: demoCode, name: demoName, pseudo: pseudo, avatarPigment: 'sienna'));
      _stubApply(pseudo, demoCode, demoName);
      if (mounted) {
        setState(() {
          _route    = AppRoute.daily;
          _apiError = 'Serveur inaccessible — données de démo.';
        });
      }
    }
  }

  void _stubApply(String pseudo, String code, String name) {
    _pseudo   = pseudo;
    _artwork  = _stubArtwork();
    _instance = _stubInstance(pseudo).copyWith(code: code, name: name);
  }

  void _applyInstanceData(Map<String, dynamic> data) {
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

    _artwork = Artwork(
      id:    artworkData['id'] as String,
      cols:  artworkData['cols'] as int,
      rows:  artworkData['rows'] as int,
      cells: cellsData.map((c) => MosaicCell(
        index:  c['index'] as int, col: c['col'] as int,
        row:    c['row']   as int, zoneId: c['zoneId'] as String,
      )).toList(),
      zones: zones,
    );

    _instance = Instance(
      code:        data['code'] as String,
      name:        (data['name'] as String?) ?? (data['code'] as String),
      artworkId:   data['artworkId'] as String,
      year:        data['year'] as int,
      month:       data['month'] as int,
      dayNumber:   data['dayNumber'] as int,
      daysInMonth: data['daysInMonth'] as int,
      players: playersData.map((p) => Player.fromJson(p)).toList(),
    );
  }

  // ── Navigation ────────────────────────────────────────────────

  Zone get _todayZone => _artwork.zones.values.firstWhere(
      (z) => z.isToday,
      orElse: () => _artwork.zones.values.firstWhere((z) => !z.isFilled,
          orElse: () => _artwork.zones.values.first));

  bool get _hasDoneToday => _todayZone.isFilled;

  MdaTab get _activeTab => switch (_route) {
    AppRoute.daily   => MdaTab.today,
    AppRoute.artwork => MdaTab.artwork,
    AppRoute.group   => MdaTab.group,
    AppRoute.profile => MdaTab.profile,
    _                => MdaTab.today,
  };

  bool get _showTabBar => {
    AppRoute.daily, AppRoute.artwork, AppRoute.group,
    AppRoute.profile, AppRoute.settings,
  }.contains(_route);

  void _nav(AppRoute r) => setState(() => _route = r);

  void _onCapture(CaptureResult result) {
    setState(() { _lastCapture = result; _route = AppRoute.confirm; });
  }

  Future<void> _onDone() async {
    final zone    = _todayZone;
    final me      = _instance.players.firstWhere((p) => p.isMe,
        orElse: () => _instance.players.first);
    final capture = _lastCapture;

    // Persist photo locally (solo or not — keeps photos available offline)
    String? photoUrl;
    if (capture != null && capture.photoPath.isNotEmpty) {
      photoUrl = await persistPhoto(capture.photoPath, zone.id);
    }

    final contribution = ZoneContribution(
      playerPseudo:  me.pseudo,
      playerAvatar:  me.avatarPigment,
      contributedAt: DateTime.now(),
      photoUrl:      photoUrl,
    );

    _artwork.zones[zone.id] = zone.copyWith(isToday: false, contribution: contribution);

    if (_isSolo) {
      // Persist contributions to SharedPreferences
      final contribs = <String, ZoneContribution>{};
      for (final entry in _artwork.zones.entries) {
        if (entry.value.contribution != null) contribs[entry.key] = entry.value.contribution!;
      }
      await saveContributions(contribs);
      // Mark the next zone as today's
      _assignTodayZoneSolo();
    }

    if (mounted) setState(() => _route = AppRoute.daily);
  }

  // ── Instance switching ────────────────────────────────────────

  Future<void> _switchInstance(int idx) async {
    await SessionManager.instance.switchTo(idx);
    final saved = SessionManager.instance.current;
    if (saved == null) {
      setState(() => _route = AppRoute.onboarding);
      return;
    }
    _stubApply(saved.pseudo, saved.code, saved.name);
    if (saved.token != null) _refreshFromApi(saved.token!).ignore();
    setState(() => _route = AppRoute.daily);
  }

  Future<void> _leaveInstance(int idx) async {
    await SessionManager.instance.leave(idx);
    if (!SessionManager.instance.hasSession) {
      setState(() => _route = AppRoute.onboarding);
    } else {
      final saved = SessionManager.instance.current!;
      _stubApply(saved.pseudo, saved.code, saved.name);
      setState(() => _route = AppRoute.daily);
    }
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_route == AppRoute.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_route == AppRoute.onboarding) {
      return OnboardingScreen(
        hasSolo: SessionManager.instance.all.any((i) => i.isSolo),
        onJoin: _onJoin,
        onSolo: _onSolo,
      );
    }
    if (_route == AppRoute.camera) {
      return CameraScreen(
        targetPigment: _todayZone.pigment,
        onClose:   () => _nav(AppRoute.daily),
        onCapture: _onCapture,
      );
    }

    Widget screen = switch (_route) {
      AppRoute.daily => DailyScreen(
          instance:     _instance,
          artwork:      _artwork,
          todayZone:    _todayZone,
          hasDoneToday: _hasDoneToday,
          onCapture:    () => _nav(AppRoute.camera),
          onSettings:   () => _nav(AppRoute.settings),
          onReveal:     () => _nav(AppRoute.reveal),
        ),
      AppRoute.confirm => ConfirmScreen(
          artwork:     _artwork,
          todayZone:   _todayZone,
          matchResult: _lastCapture!,
          onDone:      _onDone,
          onViewGroup: () => _nav(AppRoute.group),
        ),
      AppRoute.artwork => ArtworkScreen(
          artwork:      _artwork,
          instanceCode: _instance.code,
          month:        _instance.month,
        ),
      AppRoute.group => GroupScreen(
          instance:    _instance,
          todayZone:   _todayZone,
          allInstances: SessionManager.instance.all.asMap().entries.map((e) {
            final idx    = e.key;
            final saved  = e.value;
            final isCurr = idx == SessionManager.instance.currentIdx;
            // For non-current instances we show stub players (real API would fetch them)
            return GroupInstanceData(
              instance:  isCurr ? _instance : _stubInstance(saved.pseudo).copyWith(
                  code: saved.code, name: saved.name),
              todayZone: _todayZone,
              isCurrent: isCurr,
              isSolo:    saved.isSolo,
              isOnline:  !saved.isSolo && saved.token != null,
              isCreator: saved.isCreator,
            );
          }).toList(),
        ),
      AppRoute.profile => ProfileScreen(
          me:             _instance.players.firstWhere((p) => p.isMe,
              orElse: () => _instance.players.first),
          instance:       _instance,
          myContributions: _artwork.zones.values.where((z) =>
              z.isFilled && z.contribution!.playerPseudo == _pseudo).toList(),
          onRenamed: (newPseudo) => setState(() {
            _pseudo = newPseudo;
            // Update players list locally
            _instance = Instance(
              code: _instance.code, name: _instance.name,
              artworkId: _instance.artworkId, year: _instance.year,
              month: _instance.month, dayNumber: _instance.dayNumber,
              daysInMonth: _instance.daysInMonth,
              players: _instance.players.map((p) =>
                p.isMe ? Player(id: p.id, pseudo: newPseudo,
                    avatarPigment: p.avatarPigment, isMe: true,
                    hasContributedToday: p.hasContributedToday,
                    todayZoneId: p.todayZoneId)
                : p).toList(),
            );
          }),
        ),
      AppRoute.reveal => RevealScreen(
          artwork:    _artwork,
          onShare:    () {},
          onContinue: () => _nav(AppRoute.daily),
        ),
      AppRoute.settings => SettingsScreen(
          isDark: ref.watch(themeModeProvider) == ThemeMode.dark,
          onThemeChanged: (v) => ref.read(themeModeProvider.notifier).state =
              v ? ThemeMode.dark : ThemeMode.light,
          instances:      SessionManager.instance.all,
          currentIdx:     SessionManager.instance.currentIdx,
          onSwitchInstance: _switchInstance,
          onLeaveInstance:  _leaveInstance,
          onAddInstance:    () => _nav(AppRoute.onboarding),
          onDeleteData: () async {
            for (int i = SessionManager.instance.all.length - 1; i >= 0; i--) {
              await SessionManager.instance.leave(i);
            }
            await clearSoloData();
            final client = await ApiClient.get();
            await client.clearSession();
            if (mounted) setState(() { _route = AppRoute.onboarding; _isSolo = false; });
          },
        ),
      _ => const SizedBox.shrink(),
    };

    return Stack(
      children: [
        screen,
        if (_showTabBar)
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: MdaTabBar(
              active: _activeTab,
              onTap: (t) => _nav(switch (t) {
                MdaTab.today   => AppRoute.daily,
                MdaTab.artwork => AppRoute.artwork,
                MdaTab.group   => AppRoute.group,
                MdaTab.profile => AppRoute.profile,
              }),
            ),
          ),
        if (_apiError != null)
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => setState(() => _apiError = null),
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade800,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_apiError!,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Stub data ─────────────────────────────────────────────────────────────────

Artwork _stubArtwork() {
  const cols = 14, rows = 18;
  final contrib = ZoneContribution(
    playerPseudo: 'Camille', playerAvatar: 'sienna', contributedAt: DateTime(2026, 6, 2));
  final zones = <String, Zone>{
    'skyDeep': Zone(id: 'skyDeep', pigment: ZoneColor.fromLegacyPigment('ultramarine'), cellCount: 56,
        contribution: ZoneContribution(playerPseudo: 'Naomi',   playerAvatar: 'ultramarine', contributedAt: DateTime(2026,6,2))),
    'sky':     Zone(id: 'sky',     pigment: ZoneColor.fromLegacyPigment('cobalt'),      cellCount: 72,
        contribution: ZoneContribution(playerPseudo: 'Lucas',   playerAvatar: 'cobalt',      contributedAt: DateTime(2026,6,5))),
    'halo':    Zone(id: 'halo',    pigment: ZoneColor.fromLegacyPigment('ochre'),       cellCount: 24,
        contribution: ZoneContribution(playerPseudo: 'Inès',    playerAvatar: 'ochre',       contributedAt: DateTime(2026,6,7))),
    'sun':     Zone(id: 'sun',     pigment: ZoneColor.fromLegacyPigment('saffron'),     cellCount: 12, contribution: contrib),
    'hills':   Zone(id: 'hills',   pigment: ZoneColor.fromLegacyPigment('viridian'),    cellCount: 42,
        contribution: ZoneContribution(playerPseudo: 'Théo',    playerAvatar: 'viridian',    contributedAt: DateTime(2026,6,11))),
    'field':   Zone(id: 'field',   pigment: ZoneColor.fromLegacyPigment('olive'),       cellCount: 40),
    'earth':   Zone(id: 'earth',   pigment: ZoneColor.fromLegacyPigment('sienna'),      cellCount: 40, isToday: true),
    'soil':    Zone(id: 'soil',    pigment: ZoneColor.fromLegacyPigment('vermillion'),  cellCount: 54),
  };
  final cells = <MosaicCell>[];
  int i = 0;
  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      final String z;
      if (r < 9) {
        final dx = c - 9.3, dy = (r - 3.4) * 1.15;
        final d  = _sqrt(dx * dx + dy * dy);
        z = d < 2.1 ? 'sun' : d < 3.3 ? 'halo' : r < 3 ? 'skyDeep' : 'sky';
      } else if (r < 11) { z = 'hills'; }
      else if (r < 13)   { z = 'field'; }
      else if (r < 15)   { z = 'earth'; }
      else               { z = 'soil'; }
      cells.add(MosaicCell(index: i++, col: c, row: r, zoneId: z));
    }
  }
  return Artwork(id: 'jun26', cols: cols, rows: rows, cells: cells, zones: zones);
}

Instance _stubInstance(String pseudo) => Instance(
  code: 'DEMO', name: 'Démo locale', artworkId: 'jun26', year: 2026, month: 6,
  players: [
    Player(id: 'me', pseudo: pseudo, avatarPigment: 'sienna', isMe: true, hasContributedToday: false),
    Player(id: 'p2', pseudo: 'Lucas',   avatarPigment: 'cobalt',      hasContributedToday: true),
    Player(id: 'p3', pseudo: 'Inès',    avatarPigment: 'viridian',    hasContributedToday: true),
    Player(id: 'p4', pseudo: 'Naomi',   avatarPigment: 'ultramarine', hasContributedToday: false),
  ],
  dayNumber: 1, daysInMonth: 30,
);

double _sqrt(double x) {
  if (x <= 0) return 0;
  double r = x / 2;
  for (int i = 0; i < 20; i++) r = (r + x / r) / 2;
  return r;
}
