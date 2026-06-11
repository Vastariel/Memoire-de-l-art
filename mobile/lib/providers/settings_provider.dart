// settings_provider.dart — thème (clair/sombre) + langue (FR/EN), persistés.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;
  const SettingsState({this.themeMode = ThemeMode.light, this.locale = const Locale('fr')});

  SettingsState copyWith({ThemeMode? themeMode, Locale? locale}) =>
      SettingsState(themeMode: themeMode ?? this.themeMode, locale: locale ?? this.locale);
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  static const _kTheme = 'mda.theme';
  static const _kLocale = 'mda.locale';

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final theme = p.getString(_kTheme);
      final loc = p.getString(_kLocale);
      state = state.copyWith(
        themeMode: theme == 'dark' ? ThemeMode.dark : ThemeMode.light,
        locale: loc == 'en' ? const Locale('en') : const Locale('fr'),
      );
    } catch (_) {/* prototype: best-effort */}
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kTheme, state.themeMode == ThemeMode.dark ? 'dark' : 'light');
      await p.setString(_kLocale, state.locale.languageCode);
    } catch (_) {}
  }

  void setTheme(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _save();
  }

  void setLocale(String code) {
    state = state.copyWith(locale: Locale(code));
    _save();
  }

  String get lang => state.locale.languageCode;
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) => SettingsNotifier());

/// Code de langue courant ('fr' | 'en') — pratique pour les widgets/engine.
final langProvider = Provider<String>((ref) => ref.watch(settingsProvider).locale.languageCode);
