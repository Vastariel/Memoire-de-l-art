import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/notification_service.dart';
import 'services/session_manager.dart';
import 'theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    NotificationService.instance.init(),
    SessionManager.instance.load(),
  ]);
  await NotificationService.instance.rescheduleIfNeeded();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: _Root()));
}

class _Root extends ConsumerWidget {
  const _Root();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark    = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);

    SystemChrome.setSystemUIOverlayStyle(isDark
        ? const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarBrightness: Brightness.dark,
            statusBarIconBrightness: Brightness.light,
          )
        : const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarBrightness: Brightness.light,
            statusBarIconBrightness: Brightness.dark,
          ));

    return MaterialApp(
      title: 'Mémoire de l\'art',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme:     MdaTheme.light(),
      darkTheme:  MdaTheme.dark(),
      home: const MdaApp(),
    );
  }
}

final themeModeProvider = StateProvider<ThemeMode>((_) => ThemeMode.light);
