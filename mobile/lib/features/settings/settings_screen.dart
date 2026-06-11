// settings_screen.dart — Réglages : thème, langue, notifications, RGPD.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/colors.dart';
import '../../theme/palette.dart';
import '../../theme/theme.dart';
import '../../theme/typography.dart';
import '../../widgets/mda_icon.dart';
import '../../widgets/primitives.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _reminder = true;
  bool _reveal = true;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final s = ref.watch(settingsProvider);
    final isDark = s.themeMode == ThemeMode.dark;
    final lang = s.locale.languageCode;

    return Scaffold(
      backgroundColor: context.paper,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TopBar(title: t.settings, leading: IconTapButton('back', color: context.fg1, onTap: () => context.pop())),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              children: [
                Overline(t.appearance),
                const SizedBox(height: 8),
                Row(children: [
                  _choice(t.themeLight, 'sun', !isDark, () => ref.read(settingsProvider.notifier).setTheme(ThemeMode.light)),
                  const SizedBox(width: 9),
                  _choice(t.themeDark, 'star', isDark, () => ref.read(settingsProvider.notifier).setTheme(ThemeMode.dark)),
                ]),
                const SizedBox(height: 9),
                Row(children: [
                  _choice('Français', null, lang == 'fr', () => ref.read(settingsProvider.notifier).setLocale('fr')),
                  const SizedBox(width: 9),
                  _choice('English', null, lang == 'en', () => ref.read(settingsProvider.notifier).setLocale('en')),
                ]),
                const SizedBox(height: 18),
                Container(height: 1, color: context.line),
                const SizedBox(height: 12),
                Overline(t.notifications),
                _ToggleRow(label: t.dailyReminder, hint: t.dailyReminderHint, value: _reminder, onChanged: (v) => setState(() => _reminder = v)),
                Container(height: 1, color: context.line),
                _ToggleRow(label: t.revealRanking, hint: t.revealRankingHint, value: _reveal, onChanged: (v) => setState(() => _reveal = v)),
                const SizedBox(height: 14),
                Container(height: 1, color: context.line),
                const SizedBox(height: 12),
                Overline(t.privacyGdpr),
                const SizedBox(height: 10),
                _linkRow(context, 'shield', t.privacyPolicy),
                const SizedBox(height: 9),
                _linkRow(context, 'download', t.exportData),
                const SizedBox(height: 9),
                _linkRow(context, 'trash', t.deleteAccount, danger: true),
                const SizedBox(height: 22),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      ref.read(authProvider.notifier).signOut();
                      context.go('/onboarding');
                    },
                    child: Text(t.signOut, style: MdaType.sans(size: 13.5, weight: FontWeight.w600, color: context.fg3)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _choice(String label, String? icon, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: selected ? MdaColors.clay100 : context.surface,
            borderRadius: MdaRadius.bMd,
            border: Border.all(color: selected ? context.accent : context.line, width: 1.5),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[
              MdaIcon(icon, size: 17, color: selected ? MdaColors.clay600 : context.fg1),
              const SizedBox(width: 8),
            ],
            Text(label, style: MdaType.sans(size: 14, weight: FontWeight.w600, color: selected ? MdaColors.clay600 : context.fg1)),
          ]),
        ),
      ),
    );
  }

  Widget _linkRow(BuildContext context, String icon, String label, {bool danger = false}) {
    final col = danger ? MdaColors.error : context.fg1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(color: context.surface, borderRadius: MdaRadius.bMd, border: Border.all(color: context.line)),
      child: Row(children: [
        MdaIcon(icon, size: 18, color: danger ? MdaColors.error : context.fg2),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: MdaType.sans(size: 14.5, weight: FontWeight.w600, color: col))),
        MdaIcon('right', size: 17, color: context.fg3),
      ]),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String hint;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.label, required this.hint, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: MdaType.sans(size: 15, weight: FontWeight.w600, color: context.fg1)),
            Text(hint, style: MdaType.sans(size: 12.5, color: context.fg2)),
          ]),
        ),
        Switch(value: value, onChanged: onChanged, activeThumbColor: context.accent),
      ]),
    );
  }
}
