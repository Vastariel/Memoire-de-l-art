// router.dart — go_router : shell 5 onglets (indexedStack) + routes plein écran.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'theme/palette.dart';
import 'widgets/mda_tab_bar.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/today/today_screen.dart';
import 'features/today/variant_screen.dart';
import 'features/today/catchup_screen.dart';
import 'features/camera/camera_screen.dart';
import 'features/confirm/confirm_screen.dart';
import 'features/artwork/artwork_screen.dart';
import 'features/artwork/bet_screen.dart';
import 'features/instances/instances_screen.dart';
import 'features/instances/instance_detail_screen.dart';
import 'features/collection/collection_screen.dart';
import 'features/reveal/reveal_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/settings/settings_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<bool>(ref.read(authProvider).signedIn);
  ref.onDispose(refresh.dispose);
  ref.listen<AuthState>(authProvider, (_, next) => refresh.value = next.signedIn);

  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/today',
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = ref.read(authProvider).signedIn;
      final atOnboarding = state.matchedLocation == '/onboarding';
      if (!signedIn && !atOnboarding) return '/onboarding';
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/variant', builder: (_, __) => const VariantScreen()),
      GoRoute(path: '/catchup', builder: (_, __) => const CatchupScreen()),
      GoRoute(path: '/camera', builder: (_, __) => const CameraScreen()),
      GoRoute(path: '/confirm', builder: (_, __) => const ConfirmScreen()),
      GoRoute(path: '/bet', builder: (_, __) => const BetScreen()),
      GoRoute(path: '/reveal', builder: (_, __) => const RevealScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _ScaffoldWithTabBar(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/today', builder: (_, __) => const TodayScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/artwork', builder: (_, __) => const ArtworkScreen())]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/instances',
              builder: (_, __) => const InstancesScreen(),
              routes: [
                GoRoute(
                  path: 'instance/:id',
                  builder: (_, state) => InstanceDetailScreen(instanceId: state.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/collection', builder: (_, __) => const CollectionScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen())]),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class _ScaffoldWithTabBar extends StatelessWidget {
  final StatefulNavigationShell shell;
  const _ScaffoldWithTabBar({required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.paper,
      body: SafeArea(bottom: false, child: shell),
      bottomNavigationBar: MdaTabBar(
        activeIndex: shell.currentIndex,
        onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}
