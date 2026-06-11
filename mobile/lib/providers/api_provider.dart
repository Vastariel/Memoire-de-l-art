// api_provider.dart — shared providers for the API layer.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config.dart';
import '../services/api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// Whether the app talks to the live API. Overridden to `false` in tests so the
/// suite stays offline (mock data path).
final useApiProvider = Provider<bool>((ref) => AppConfig.useApi);
