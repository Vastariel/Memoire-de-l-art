// notifications.dart — notifications locales (rappel quotidien + reveal du
// dimanche). Tout est best-effort : sur desktop/web/tests le plugin n'est pas
// disponible et chaque appel est silencieusement ignoré.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class LocalNotifs {
  LocalNotifs._();
  static final instance = LocalNotifs._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _idDaily = 1;
  static const _idReveal = 2;

  Future<bool> _init() async {
    if (_ready) return true;
    try {
      tzdata.initializeTimeZones();
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _plugin.initialize(settings);
      _ready = true;
      return true;
    } catch (_) {
      return false; // pas de plugin (tests/desktop) → no-op
    }
  }

  Future<void> requestPermission() async {
    if (!await _init()) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {}
  }

  /// Rappel quotidien à HH:mm (heure locale de l'appareil).
  Future<void> scheduleDaily(int hour, int minute, {required String title, required String body}) async {
    if (!await _init()) return;
    try {
      await _plugin.zonedSchedule(
        _idDaily,
        title,
        body,
        _next(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails('mda_daily', 'Rappel quotidien',
              channelDescription: 'Rappel de la photo du jour'),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  Future<void> cancelDaily() async {
    if (!await _init()) return;
    try {
      await _plugin.cancel(_idDaily);
    } catch (_) {}
  }

  /// Reveal : chaque dimanche à 20:00 locale.
  Future<void> scheduleSundayReveal({required String title, required String body}) async {
    if (!await _init()) return;
    try {
      await _plugin.zonedSchedule(
        _idReveal,
        title,
        body,
        _next(20, 0, weekday: DateTime.sunday),
        const NotificationDetails(
          android: AndroidNotificationDetails('mda_reveal', 'Reveal du dimanche',
              channelDescription: 'Révélation de l\'œuvre de la semaine'),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (_) {}
  }

  Future<void> cancelSundayReveal() async {
    if (!await _init()) return;
    try {
      await _plugin.cancel(_idReveal);
    } catch (_) {}
  }

  /// Prochaine occurrence de HH:mm (optionnellement un jour de semaine donné),
  /// convertie en instant absolu. NB : la répétition est ancrée en UTC, un
  /// changement d'heure été/hiver décale d'une heure jusqu'à replanification
  /// (au prochain lancement de l'app ou changement de réglage).
  tz.TZDateTime _next(int hour, int minute, {int? weekday}) {
    final now = DateTime.now();
    var dt = DateTime(now.year, now.month, now.day, hour, minute);
    while (dt.isBefore(now) || (weekday != null && dt.weekday != weekday)) {
      dt = dt.add(const Duration(days: 1));
    }
    return tz.TZDateTime.from(dt, tz.local);
  }
}
