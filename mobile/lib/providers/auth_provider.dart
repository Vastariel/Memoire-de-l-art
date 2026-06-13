// auth_provider.dart — authentication state, wired to the live API with a
// graceful offline fallback (keeps the prototype & tests working without network).
//
// Real OAuth (Google/Apple via Firebase) drops in later: pass the provider's
// ID token to ApiClient.auth('google'|'apple', token: idToken). For now, every
// path authenticates via /auth/dev (ALLOW_DEV_LOGIN=true on the server).

import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import 'api_provider.dart';

enum AuthProvider { google, apple, dev }

class AuthState {
  final bool signedIn;
  final String pseudo;
  final bool online; // true if authenticated against the live API
  const AuthState({this.signedIn = false, this.pseudo = 'Camille', this.online = false});

  AuthState copyWith({bool? signedIn, String? pseudo, bool? online}) => AuthState(
        signedIn: signedIn ?? this.signedIn,
        pseudo: pseudo ?? this.pseudo,
        online: online ?? this.online,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._api, this._useApi) : super(const AuthState());
  final ApiClient _api;
  final bool _useApi;

  /// Onboarding "Continuer avec …" — records the pseudo; the real sign-in
  /// happens on completeOnboarding (we have the pseudo + consent by then).
  void startProvider(AuthProvider provider) {}

  void setPseudo(String pseudo) =>
      state = state.copyWith(pseudo: pseudo.trim().isEmpty ? 'Toi' : pseudo.trim());

  /// Rename the signed-in user — updates local state and persists via PATCH /me.
  Future<void> updatePseudo(String pseudo) async {
    final p = pseudo.trim().isEmpty ? 'Toi' : pseudo.trim();
    state = state.copyWith(pseudo: p);
    if (_useApi && online) {
      try {
        await _api.updateMe(pseudo: p);
      } catch (_) {/* keep optimistic local pseudo */}
    }
  }

  /// RGPD erasure — delete the account server-side, then reset to signed-out.
  Future<void> deleteAccount() async {
    if (_useApi && online) {
      try {
        await _api.deleteAccount();
      } catch (_) {/* fall through — still clear local session */}
    }
    try {
      await _api.clearToken();
    } catch (_) {}
    state = const AuthState();
  }

  bool get online => state.online;

  /// Finish onboarding (join/create) — authenticate, with offline fallback.
  Future<void> completeOnboarding({String? pseudo, bool consent = true}) async {
    final p = (pseudo != null && pseudo.trim().isNotEmpty) ? pseudo.trim() : state.pseudo;
    if (_useApi) {
      try {
        final user = await _api.auth('dev', token: p, pseudo: p, consent: consent);
        state = state.copyWith(signedIn: true, online: true, pseudo: (user['pseudo'] as String?) ?? p);
        return;
      } catch (_) {/* fall through to local */}
    }
    state = state.copyWith(signedIn: true, online: false, pseudo: p);
  }

  /// Dev bypass — enter the app immediately (guest), still tries the live API.
  Future<void> signInDev() async {
    if (_useApi) {
      try {
        final user = await _api.auth('dev', token: 'guest', pseudo: 'Invité', consent: true);
        state = state.copyWith(signedIn: true, online: true, pseudo: (user['pseudo'] as String?) ?? 'Invité');
        return;
      } catch (_) {/* offline */}
    }
    state = state.copyWith(signedIn: true, online: false);
  }

  /// Skip login (test) — distinct-but-stable dev account per device, then join
  /// the shared "test" atelier so uploads have an instance. Returns true online.
  Future<bool> signInTest() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('mda.devToken');
    if (token == null) {
      token = 'test-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(99999)}';
      await prefs.setString('mda.devToken', token);
    }
    var pseudo = prefs.getString('mda.devPseudo') ?? 'Testeur ${Random().nextInt(900) + 100}';
    await prefs.setString('mda.devPseudo', pseudo);

    if (_useApi) {
      try {
        final user = await _api.auth('dev', token: token, pseudo: pseudo, consent: true);
        pseudo = (user['pseudo'] as String?) ?? pseudo;
        await _api.joinTestInstance();
        state = state.copyWith(signedIn: true, online: true, pseudo: pseudo);
        return true;
      } catch (_) {/* fall through to offline */}
    }
    state = state.copyWith(signedIn: true, online: false, pseudo: pseudo);
    return false;
  }

  /// Restore a saved session on launch.
  Future<void> tryRestore() async {
    if (!_useApi) return;
    try {
      if (await _api.loadToken()) {
        final me = await _api.me();
        final u = me['user'] as Map<String, dynamic>?;
        state = state.copyWith(signedIn: true, online: true, pseudo: (u?['pseudo'] as String?) ?? state.pseudo);
      }
    } catch (_) {/* stay signed out */}
  }

  Future<void> signOut() async {
    try {
      await _api.clearToken();
    } catch (_) {}
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(apiClientProvider), ref.read(useApiProvider)),
);
