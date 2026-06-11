# Connexion Google / Apple — guide de configuration

> **État actuel (Phase 1)** : l'app tourne avec un **bypass dev** — les boutons
> « Continuer avec Apple / Google » avancent dans l'onboarding sans vraie
> connexion, et « Continuer (dev, sans compte) » entre directement. Aucun
> identifiant n'est nécessaire pour cliquer dans le prototype.
>
> Ce guide explique, **en clair**, ce qu'il faudra créer pour activer la vraie
> connexion. Rien à faire tant que tu n'es pas prêt à tester sur un téléphone.
## Ce qu'est un « identifiant » ici
Pour qu'un téléphone puisse dire à Google/Apple « connecte cet utilisateur »,
il faut une **clé d'application** délivrée gratuitement par un tableau de bord.
On la dépose dans un fichier de config du projet. C'est tout.

## Le plus simple : Firebase Authentication
Firebase (Google, gratuit) gère **à la fois Google et Apple** et nous donne un
jeton vérifiable. Le backend, lui, **ne change pas** : il échange ce jeton
contre son JWT habituel via `POST /auth/{google|apple}` (Phase 2).

### Étapes (≈ 20 min, quand tu voudras)
1. Va sur https://console.firebase.google.com → **Créer un projet** « memoire-de-lart ».
2. **Authentication → Sign-in method** → active **Google** (1 clic) et **Apple**.
3. Ajoute une app **Android** : renseigne le package `com.example.memoire_de_lart`
   (ou le tien) → télécharge **`google-services.json`** → dépose-le dans
   `mobile/android/app/`.
4. (iOS) Ajoute une app **iOS** → télécharge **`GoogleService-Info.plist`** →
   dépose-le dans `mobile/ios/Runner/`.
5. Lance, depuis `mobile/` : `flutterfire configure` (génère `lib/firebase_options.dart`).

### « Continuer avec Apple »
Apple Sign-In exige un **compte Apple Developer** (99 $/an) **et** un appareil ou
simulateur **iOS**. Google fonctionne sans rien de tout ça → on teste Google
d'abord, Apple ensuite.

## Côté code (Phase 2, déjà prévu)
Le seam est en place dans `lib/providers/auth_provider.dart` :
- `AuthService` est l'interface ; `MockAuthService` (actuel) renvoie un faux compte.
- Créer `FirebaseAuthService implements AuthService` (avec `firebase_auth`,
  `google_sign_in`, `sign_in_with_apple`), puis remplacer dans
  `authServiceProvider` :
  ```dart
  final authServiceProvider = Provider<AuthService>((ref) => FirebaseAuthService());
  ```
- Ajouter au `pubspec.yaml` : `firebase_core`, `firebase_auth`, `google_sign_in`,
  `sign_in_with_apple` (à faire **seulement** une fois `google-services.json`
  présent, sinon le build Android échoue).
- Dans `main()`, ajouter `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);`.

Rien d'autre à toucher : l'UI d'onboarding et le reste de l'app sont déjà câblés.
