// config.dart — runtime configuration.

class AppConfig {
  /// Base URL of the deployed v2 API.
  static const String apiBaseUrl = 'https://mda.vastariel.fr';

  /// When true, the app talks to [apiBaseUrl]; when false it runs on the
  /// in-memory mock data (offline prototype). Can be overridden at build time:
  /// flutter run --dart-define=USE_API=false
  static const bool useApi = bool.fromEnvironment('USE_API', defaultValue: true);
}
