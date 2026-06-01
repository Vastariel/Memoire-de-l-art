import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// One entry per joined instance, persisted across app relaunches.
class SavedInstance {
  final String code;
  final String name;     // user-defined label
  final String pseudo;
  final String avatarPigment;
  final String? token;     // null = demo/offline
  final bool isSolo;       // true = no server, fully local
  final bool isCreator;    // true = this user created the instance

  const SavedInstance({
    required this.code,
    required this.name,
    required this.pseudo,
    required this.avatarPigment,
    this.token,
    this.isSolo = false,
    this.isCreator = false,
  });

  Map<String, dynamic> toJson() => {
    'code': code, 'name': name, 'pseudo': pseudo,
    'avatarPigment': avatarPigment,
    if (token != null) 'token': token,
    if (isSolo) 'isSolo': true,
    if (isCreator) 'isCreator': true,
  };

  factory SavedInstance.fromJson(Map<String, dynamic> j) => SavedInstance(
    code:           j['code']          as String,
    name:           j['name']          as String? ?? j['code'] as String,
    pseudo:         j['pseudo']        as String? ?? 'Toi',
    avatarPigment:  j['avatarPigment'] as String? ?? 'sienna',
    token:          j['token']         as String?,
    isSolo:         j['isSolo']        as bool? ?? false,
    isCreator:      j['isCreator']     as bool? ?? false,
  );
}

class SessionManager {
  SessionManager._();
  static final SessionManager instance = SessionManager._();

  static const _keyInstances = 'instances_v2';
  static const _keyCurrent   = 'current_instance_idx';

  List<SavedInstance> _instances = [];
  int _currentIdx = 0;

  List<SavedInstance> get all     => List.unmodifiable(_instances);
  int                 get currentIdx => _currentIdx;
  SavedInstance?      get current  =>
      _instances.isEmpty ? null : _instances[_currentIdx.clamp(0, _instances.length - 1)];
  bool                get hasSession => _instances.isNotEmpty;

  // ── Load ───────────────────────────────────────────────────────

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_keyInstances);
    if (raw != null) {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _instances  = list.map(SavedInstance.fromJson).toList();
    }
    _currentIdx = prefs.getInt(_keyCurrent) ?? 0;
    if (_currentIdx >= _instances.length) _currentIdx = 0;
  }

  // ── Add / replace ──────────────────────────────────────────────

  Future<void> addOrUpdate(SavedInstance inst) async {
    final idx = _instances.indexWhere((i) => i.code == inst.code);
    if (idx >= 0) {
      _instances[idx] = inst;
      if (_currentIdx == idx) _currentIdx = idx; // keep current
    } else {
      _instances.add(inst);
      _currentIdx = _instances.length - 1; // switch to new
    }
    await _save();
  }

  // ── Switch ─────────────────────────────────────────────────────

  Future<void> switchTo(int idx) async {
    if (idx < 0 || idx >= _instances.length) return;
    _currentIdx = idx;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCurrent, _currentIdx);
  }

  // ── Leave ──────────────────────────────────────────────────────

  Future<void> leave(int idx) async {
    if (idx < 0 || idx >= _instances.length) return;
    _instances.removeAt(idx);
    _currentIdx = (_currentIdx >= _instances.length
        ? _instances.length - 1
        : _currentIdx).clamp(0, _instances.isEmpty ? 0 : _instances.length - 1);
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyInstances, jsonEncode(_instances.map((i) => i.toJson()).toList()));
    await prefs.setInt(_keyCurrent, _currentIdx);
  }
}
