import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

// Notification channel IDs
const _channelId   = 'daily_reminder';
const _channelName = 'Rappel quotidien';
const _notifId     = 0;

// SharedPreferences keys
const _prefHour   = 'notif_hour';
const _prefMin    = 'notif_minute';
const _prefEnabled = 'notif_enabled';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Init ─────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin  = DarwinInitializationSettings(
      requestAlertPermission:  false,
      requestBadgePermission:  false,
      requestSoundPermission:  false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: darwin),
    );
    _initialized = true;
  }

  // ── Permission ────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(alert: true, sound: true);
      return granted ?? false;
    }
    return false;
  }

  // ── Schedule ──────────────────────────────────────────────────

  // Schedule a daily notification at [hour]:[minute].
  // Cancels any existing notification first.
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    String? pigmentLabel,
  }) async {
    await _plugin.cancel(_notifId);

    final body = pigmentLabel != null
        ? 'Ta couleur du jour t\'attend — $pigmentLabel'
        : 'Ta contribution du jour t\'attend.';

    final now       = tz.TZDateTime.now(tz.local);
    var scheduled   = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _notifId,
      'Mémoire de l\'art',
      body,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Rappel quotidien pour ta contribution artistique',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          enableVibration: false,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    await _savePrefs(hour: hour, minute: minute, enabled: true);
  }

  Future<void> cancel() async {
    await _plugin.cancel(_notifId);
    await _savePrefs(enabled: false);
  }

  // ── Persistence ───────────────────────────────────────────────

  Future<void> _savePrefs({int? hour, int? minute, bool? enabled}) async {
    final prefs = await SharedPreferences.getInstance();
    if (hour    != null) await prefs.setInt(_prefHour,    hour);
    if (minute  != null) await prefs.setInt(_prefMin,     minute);
    if (enabled != null) await prefs.setBool(_prefEnabled, enabled);
  }

  Future<({int hour, int minute, bool enabled})> loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      hour:    prefs.getInt(_prefHour)    ?? 8,
      minute:  prefs.getInt(_prefMin)     ?? 30,
      enabled: prefs.getBool(_prefEnabled) ?? true,
    );
  }

  // ── Reschedule on launch ──────────────────────────────────────
  // Call this on app start to re-arm the notification if it was set.
  Future<void> rescheduleIfNeeded() async {
    final p = await loadPrefs();
    if (!p.enabled) return;
    final pending = await _plugin.pendingNotificationRequests();
    if (pending.any((n) => n.id == _notifId)) return; // already armed
    await scheduleDailyReminder(hour: p.hour, minute: p.minute);
  }
}

// ── TimeOfDay helpers ──────────────────────────────────────────

extension NotifTimeOfDay on TimeOfDay {
  String toHHMM() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
