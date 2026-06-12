// settings_provider.dart — thème (clair/sombre), langue (FR/EN) et
// notifications, persistés localement et synchronisés au serveur (PATCH /me).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_provider.dart';

class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;
  final bool reminder; // rappel quotidien
  final bool reveal; // notification de révélation
  final int notifHour;
  final int notifMinute;
  const SettingsState({
    this.themeMode = ThemeMode.light,
    this.locale = const Locale('fr'),
    this.reminder = true,
    this.reveal = true,
    this.notifHour = 19,
    this.notifMinute = 0,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? reminder,
    bool? reveal,
    int? notifHour,
    int? notifMinute,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        locale: locale ?? this.locale,
        reminder: reminder ?? this.reminder,
        reveal: reveal ?? this.reveal,
        notifHour: notifHour ?? this.notifHour,
        notifMinute: notifMinute ?? this.notifMinute,
      );
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._ref) : super(const SettingsState()) {
    _load();
  }

  final Ref _ref;

  static const _kTheme = 'mda.theme';
  static const _kLocale = 'mda.locale';
  static const _kReminder = 'mda.notif.reminder';
  static const _kReveal = 'mda.notif.reveal';
  static const _kHour = 'mda.notif.hour';
  static const _kMinute = 'mda.notif.minute';

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final theme = p.getString(_kTheme);
      final loc = p.getString(_kLocale);
      state = state.copyWith(
        themeMode: theme == 'dark' ? ThemeMode.dark : ThemeMode.light,
        locale: loc == 'en' ? const Locale('en') : const Locale('fr'),
        reminder: p.getBool(_kReminder) ?? true,
        reveal: p.getBool(_kReveal) ?? true,
        notifHour: p.getInt(_kHour) ?? 19,
        notifMinute: p.getInt(_kMinute) ?? 0,
      );
    } catch (_) {/* prototype: best-effort */}
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kTheme, state.themeMode == ThemeMode.dark ? 'dark' : 'light');
      await p.setString(_kLocale, state.locale.languageCode);
      await p.setBool(_kReminder, state.reminder);
      await p.setBool(_kReveal, state.reveal);
      await p.setInt(_kHour, state.notifHour);
      await p.setInt(_kMinute, state.notifMinute);
    } catch (_) {}
  }

  /// Push the persisted preferences to the server (best-effort).
  void _sync({String? locale, int? notifHour, int? notifMinute}) {
    if (!_ref.read(useApiProvider)) return;
    _ref
        .read(apiClientProvider)
        .updateMe(locale: locale, notifHour: notifHour, notifMinute: notifMinute)
        .catchError((_) => <String, dynamic>{});
  }

  void setTheme(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _save();
  }

  void setLocale(String code) {
    state = state.copyWith(locale: Locale(code));
    _save();
    _sync(locale: code);
  }

  void setReminder(bool on) {
    state = state.copyWith(reminder: on);
    _save();
    // Backend has no "enabled" flag; only push the time when the reminder is on.
    if (on) _sync(notifHour: state.notifHour, notifMinute: state.notifMinute);
  }

  void setReveal(bool on) {
    state = state.copyWith(reveal: on);
    _save();
  }

  void setNotifTime(int hour, int minute) {
    state = state.copyWith(notifHour: hour, notifMinute: minute);
    _save();
    if (state.reminder) _sync(notifHour: hour, notifMinute: minute);
  }

  String get lang => state.locale.languageCode;
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) => SettingsNotifier(ref));

/// Code de langue courant ('fr' | 'en') — pratique pour les widgets/engine.
final langProvider = Provider<String>((ref) => ref.watch(settingsProvider).locale.languageCode);
