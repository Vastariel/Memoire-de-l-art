// api_client.dart — thin dio client for the v2 API, with JWT persistence.

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';

class ApiClient {
  ApiClient({Dio? dio, FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: '${AppConfig.apiBaseUrl}/api/v1',
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 25),
            )) {
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
      final t = _token ??= await _storage.read(key: _kToken);
      if (t != null && t.isNotEmpty) options.headers['authorization'] = 'Bearer $t';
      handler.next(options);
    }));
  }

  final Dio _dio;
  final FlutterSecureStorage _storage;
  static const _kToken = 'mda.jwt';
  String? _token;

  bool get hasToken => _token != null && _token!.isNotEmpty;

  Future<void> _saveToken(String token) async {
    _token = token;
    await _storage.write(key: _kToken, value: token);
  }

  Future<void> clearToken() async {
    _token = null;
    await _storage.delete(key: _kToken);
  }

  Future<bool> loadToken() async {
    _token = await _storage.read(key: _kToken);
    return hasToken;
  }

  // ── Auth ──────────────────────────────────────────────────────
  /// provider: 'google' | 'apple' | 'dev'. Returns the user map; stores the JWT.
  Future<Map<String, dynamic>> auth(
    String provider, {
    String token = '',
    String? pseudo,
    String? locale,
    bool? consent,
  }) async {
    final res = await _dio.post('/auth/$provider', data: {
      'token': token,
      if (pseudo != null) 'pseudo': pseudo,
      if (locale != null) 'locale': locale,
      if (consent != null) 'consent': consent,
    });
    final data = res.data as Map<String, dynamic>;
    await _saveToken(data['token'] as String);
    return data['user'] as Map<String, dynamic>;
  }

  // ── Reads ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> weeksCurrent({String lang = 'fr'}) async =>
      (await _dio.get('/weeks/current', queryParameters: {'lang': lang})).data as Map<String, dynamic>;

  Future<Map<String, dynamic>> daysToday() async => (await _dio.get('/days/today')).data as Map<String, dynamic>;

  Future<List<dynamic>> instancesMine() async =>
      ((await _dio.get('/instances/mine')).data as Map<String, dynamic>)['instances'] as List<dynamic>;

  Future<Map<String, dynamic>> instanceArtwork(String id) async =>
      (await _dio.get('/instances/$id/artwork')).data as Map<String, dynamic>;

  Future<List<dynamic>> leaderboard(String id) async =>
      ((await _dio.get('/instances/$id/leaderboard')).data as Map<String, dynamic>)['leaderboard'] as List<dynamic>;

  Future<Map<String, dynamic>> me({String lang = 'fr'}) async => (await _dio.get('/me')).data as Map<String, dynamic>;

  Future<Map<String, dynamic>> updateMe({
    String? pseudo,
    String? locale,
    int? notifHour,
    int? notifMinute,
    String? fcmToken,
  }) async {
    final body = <String, dynamic>{
      if (pseudo != null) 'pseudo': pseudo,
      if (locale != null) 'locale': locale,
      if (notifHour != null) 'notifHour': notifHour,
      if (notifMinute != null) 'notifMinute': notifMinute,
      if (fcmToken != null) 'fcmToken': fcmToken,
    };
    return ((await _dio.patch('/me', data: body)).data as Map<String, dynamic>)['user'] as Map<String, dynamic>;
  }

  /// RGPD — full account export (JSON). Returned as a decoded map.
  Future<Map<String, dynamic>> exportData() async =>
      (await _dio.get('/me/export')).data as Map<String, dynamic>;

  /// RGPD — erase the account (cascade-deletes photos & contributions).
  Future<void> deleteAccount() async {
    await _dio.delete('/me');
  }

  Future<List<dynamic>> collection({String lang = 'fr'}) async =>
      ((await _dio.get('/me/collection', queryParameters: {'lang': lang})).data as Map<String, dynamic>)['collection']
          as List<dynamic>;

  // ── Writes ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> createInstance({String? name, required String mode, bool solo = false}) async =>
      ((await _dio.post('/instances', data: {'name': name, 'mode': mode, 'solo': solo})).data
          as Map<String, dynamic>)['instance'] as Map<String, dynamic>;

  Future<Map<String, dynamic>> joinInstance(String code) async =>
      ((await _dio.post('/instances/join', data: {'code': code})).data as Map<String, dynamic>)['instance']
          as Map<String, dynamic>;

  Future<void> claim(String instanceId, String variantKey) async {
    await _dio.post('/claims', data: {'instanceId': instanceId, 'variantKey': variantKey});
  }

  Future<List<dynamic>> claims(String instanceId) async =>
      ((await _dio.get('/claims', queryParameters: {'instanceId': instanceId})).data as Map<String, dynamic>)['claims']
          as List<dynamic>;

  Future<Map<String, dynamic>> submitPhoto({
    required String filePath,
    required int day,
    required String variantKey,
    bool shared = true,
    String? separateInstanceId,
    bool catchup = false,
  }) async {
    final form = FormData.fromMap({
      'day': '$day',
      'variantKey': variantKey,
      'shared': '$shared',
      if (separateInstanceId != null) 'separateInstanceId': separateInstanceId,
      'file': await MultipartFile.fromFile(filePath, filename: 'photo.jpg'),
    });
    final res = await _dio.post(catchup ? '/photos/catchup' : '/photos', data: form);
    return (res.data as Map<String, dynamic>)['result'] as Map<String, dynamic>;
  }

  Future<void> placeGuess(String titleGuess) async {
    await _dio.post('/guesses', data: {'titleGuess': titleGuess});
  }

  /// Current week's bet for the signed-in user (null if none).
  Future<Map<String, dynamic>?> myGuess() async =>
      ((await _dio.get('/guesses/mine')).data as Map<String, dynamic>)['guess'] as Map<String, dynamic>?;

  Future<List<dynamic>> guessOptions() async =>
      ((await _dio.get('/guesses/options')).data as Map<String, dynamic>)['options'] as List<dynamic>;

  Future<void> reactToContribution(String contributionId, String stamp) async {
    await _dio.post('/contributions/$contributionId/reactions', data: {'stamp': stamp});
  }
}
