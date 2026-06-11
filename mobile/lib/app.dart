// app.dart — racine MaterialApp.router (thème + locale + go_router).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'providers/settings_provider.dart';
import 'router.dart';
import 'theme/theme.dart';

class MdaApp extends ConsumerWidget {
  const MdaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Mémoire de l\'art',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: MdaTheme.light(),
      darkTheme: MdaTheme.dark(),
      locale: settings.locale,
      localizationsDelegates: const [
        L10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: L10n.supportedLocales,
      routerConfig: router,
    );
  }
}
