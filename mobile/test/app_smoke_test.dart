// app_smoke_test.dart — démarre l'app complète (router + providers) sans écran.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memoire_de_lart/app.dart';
import 'package:memoire_de_lart/providers/api_provider.dart';

// Keep the suite offline: never hit the live API.
final _offline = ProviderScope(
  overrides: [useApiProvider.overrideWithValue(false)],
  child: const MdaApp(),
);

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('l\'app démarre sur l\'onboarding (non connecté)', (tester) async {
    await tester.pumpWidget(_offline);
    await tester.pump(); // build
    await tester.pump(const Duration(milliseconds: 300)); // redirect + 1re frame

    // L'onboarding doit s'afficher (titre de l'app).
    expect(find.text('Mémoire de l\'art'), findsOneWidget);
    // Boutons OAuth + bypass dev présents.
    expect(find.text('Continuer avec Google'), findsOneWidget);
    expect(find.text('Continuer (dev, sans compte)'), findsOneWidget);
  });

  testWidgets('le bypass dev entre dans l\'app (onglet Aujourd\'hui)', (tester) async {
    await tester.pumpWidget(_offline);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Continuer (dev, sans compte)'));
    await tester.pump(); // action
    await tester.pump(const Duration(milliseconds: 400)); // navigation

    // La barre d'onglets v2 doit apparaître (5 onglets).
    expect(find.text('Aujourd\'hui'), findsWidgets);
    expect(find.text('Collection'), findsOneWidget);
  });

  testWidgets('navigation vers le détail d\'instance depuis le teaser', (tester) async {
    await tester.pumpWidget(_offline);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Continuer (dev, sans compte)'));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.scrollUntilVisible(
      find.text('Voir le classement de la semaine'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Voir le classement de la semaine'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Le détail d'instance (classement) doit s'afficher.
    expect(find.text('Classement hebdo'), findsOneWidget);
  });
}
