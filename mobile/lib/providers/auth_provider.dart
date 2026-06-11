// auth_provider.dart — état d'authentification (Phase 1 : bypass dev).
//
// La vraie OAuth (Google/Apple via Firebase Auth) se branche ici en
// implémentant [AuthService] avec FirebaseAuthService et en l'injectant à la
// place de [MockAuthService]. Voir mobile/AUTH_SETUP.md. Le backend conserve
// son JWT : le client échange l'ID token contre le JWT via POST /auth/{provider}.

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthProvider { google, apple, dev }

/// Abstraction d'authentification. Phase 1 renvoie un faux compte.
abstract class AuthService {
  Future<String> signIn(AuthProvider provider); // renvoie un identifiant compte
}

class MockAuthService implements AuthService {
  @override
  Future<String> signIn(AuthProvider provider) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return 'mock-${provider.name}-account';
  }
}

class AuthState {
  final bool signedIn;
  final String pseudo;
  final String? accountId;
  const AuthState({this.signedIn = false, this.pseudo = 'Camille', this.accountId});

  AuthState copyWith({bool? signedIn, String? pseudo, String? accountId}) => AuthState(
        signedIn: signedIn ?? this.signedIn,
        pseudo: pseudo ?? this.pseudo,
        accountId: accountId ?? this.accountId,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._service) : super(const AuthState());
  final AuthService _service;

  /// Étape « Continuer avec … » de l'onboarding. En Phase 1, prépare le compte
  /// sans bloquer la suite du parcours (saisie pseudo, instance).
  Future<void> startProvider(AuthProvider provider) async {
    final id = await _service.signIn(provider);
    state = state.copyWith(accountId: id);
  }

  void setPseudo(String pseudo) =>
      state = state.copyWith(pseudo: pseudo.trim().isEmpty ? 'Toi' : pseudo.trim());

  /// Termine l'onboarding (rejoindre/créer) — connecte l'utilisateur.
  void completeOnboarding({String? pseudo}) {
    state = state.copyWith(
      signedIn: true,
      pseudo: (pseudo != null && pseudo.trim().isNotEmpty) ? pseudo.trim() : state.pseudo,
    );
  }

  /// Bypass dev : entre directement dans l'app sans compte.
  void signInDev() => state = state.copyWith(signedIn: true, accountId: 'dev');

  void signOut() => state = const AuthState();
}

final authServiceProvider = Provider<AuthService>((ref) => MockAuthService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authServiceProvider)),
);
