import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _defaultBaseUrl = 'https://mda.vastariel.fr';

class ApiClient {
  ApiClient._({required FlutterSecureStorage storage, required String baseUrl})
      : _storage = storage,
        _dio     = _buildDio(baseUrl, storage);

  final FlutterSecureStorage _storage;
  final Dio _dio;

  static ApiClient? _instance;

  static Future<ApiClient> get() async {
    if (_instance != null) return _instance!;
    const storage = FlutterSecureStorage();
    final prefs   = await SharedPreferences.getInstance();
    final base    = prefs.getString('custom_server_url') ?? _defaultBaseUrl;
    _instance     = ApiClient._(storage: storage, baseUrl: base);
    return _instance!;
  }

  // Call after updating custom server URL
  static void reset() => _instance = null;

  // Test reachability — returns true if the server responds with 200
  static Future<bool> testConnection(String url) async {
    try {
      final base = url.trim().isEmpty ? _defaultBaseUrl : url.trim();
      final dio = Dio(BaseOptions(
        baseUrl: base,
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 6),
      ));
      final res = await dio.get<dynamic>('/health');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Dio _buildDio(String base, FlutterSecureStorage storage) {
    final dio = Dio(BaseOptions(
      baseUrl:        base,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (opts, handler) async {
        final token = await storage.read(key: 'jwt_token');
        if (token != null) opts.headers['Authorization'] = 'Bearer $token';
        handler.next(opts);
      },
    ));
    return dio;
  }

  // ── Auth ──────────────────────────────────────────────────────

  Future<JoinResult> createInstance({String? pseudo, String? name, String? fcmToken}) async {
    final res = await _dio.post<Map<String, dynamic>>('/api/v1/instances', data: {
      if (pseudo   != null) 'pseudo':   pseudo,
      if (name     != null) 'name':     name,
      if (fcmToken != null) 'fcmToken': fcmToken,
    });
    return _handleJoin(res.data!);
  }

  Future<JoinResult> joinInstance(String code, {String? pseudo, String? fcmToken}) async {
    final res = await _dio.post<Map<String, dynamic>>('/api/v1/instances/join', data: {
      'code':  code,
      if (pseudo   != null) 'pseudo':   pseudo,
      if (fcmToken != null) 'fcmToken': fcmToken,
    });
    return _handleJoin(res.data!);
  }

  JoinResult _handleJoin(Map<String, dynamic> data) {
    final token = data['token'] as String;
    return JoinResult(token: token, instance: data['instance'] as Map<String, dynamic>);
  }

  // ── Instance state ────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchInstanceState() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/v1/instances/me');
    return res.data!['instance'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> fetchGroupFeed(String code) async {
    final res = await _dio.get<Map<String, dynamic>>('/api/v1/instances/$code/feed');
    return (res.data!['contributions'] as List).cast<Map<String, dynamic>>();
  }

  // ── Photos ────────────────────────────────────────────────────

  Future<PhotoSubmitResult> submitPhoto({
    required String photoPath,
    required String zoneId,
  }) async {
    final formData = FormData.fromMap({
      'zoneId': zoneId,
      'file':   await MultipartFile.fromFile(photoPath, filename: 'photo.jpg'),
    });
    final res = await _dio.post<Map<String, dynamic>>('/api/v1/photos/submit', data: formData);
    final d = res.data!;
    return PhotoSubmitResult(
      photoUrl: d['photoUrl'] as String,
      delta:    (d['match']['delta'] as num).toDouble(),
      verdict:  d['match']['verdict'] as String,
      mode:     d['match']['mode'] as String,
    );
  }

  // ── Player ────────────────────────────────────────────────────

  Future<String?> fetchHint() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/v1/artworks/current/hint');
    final hint = res.data!['hint'];
    if (hint == null) return null;
    return hint['text'] as String?;
  }

  Future<void> updatePlayer({
    String? pseudo,
    int?    notifHour,
    int?    notifMinute,
    String? fcmToken,
    String? customServerUrl,
  }) async {
    await _dio.patch('/api/v1/players/me', data: {
      if (pseudo          != null) 'pseudo':          pseudo,
      if (notifHour       != null) 'notifHour':       notifHour,
      if (notifMinute     != null) 'notifMinute':     notifMinute,
      if (fcmToken        != null) 'fcmToken':        fcmToken,
      if (customServerUrl != null) 'customServerUrl': customServerUrl,
    });
  }

  Future<void> deleteAccount() => _dio.delete('/api/v1/players/me');

  Future<List<Map<String, dynamic>>> fetchHistory() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/v1/players/me/history');
    return (res.data!['artworks'] as List).cast<Map<String, dynamic>>();
  }

  // ── Session persistence ────────────────────────────────────────

  Future<void> saveSession(String token) =>
      _storage.write(key: 'jwt_token', value: token);

  Future<String?> loadToken() => _storage.read(key: 'jwt_token');

  Future<void> clearSession() => _storage.delete(key: 'jwt_token');
}

class JoinResult {
  final String token;
  final Map<String, dynamic> instance;
  const JoinResult({required this.token, required this.instance});
}

class PhotoSubmitResult {
  final String photoUrl;
  final double delta;
  final String verdict;
  final String mode;
  const PhotoSubmitResult({
    required this.photoUrl,
    required this.delta,
    required this.verdict,
    required this.mode,
  });
}
