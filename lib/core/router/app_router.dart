import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/calories/presentation/calories_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/weight/presentation/weight_screen.dart';
import '../constants/app_spacing.dart';
import '../utils/reduce_motion.dart';
import '../widgets/skeleton_box.dart';
import 'app_shell_scaffold.dart';

part 'app_router.g.dart';

abstract final class AppRoutes {
  static const String boot = '/boot';
  static const String home = '/';
  static const String weight = '/weight';
  static const String calories = '/calories';
  static const String profile = '/profile';
  static const String onboarding = '/onboarding';
}

/// Transisi halaman standar ScaleUp: slide lembut + fade (menghormati reduce motion).
CustomTransitionPage<T> buildScaleUpTransitionPage<T>({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    transitionDuration: AppSpacing.animNormal,
    reverseTransitionDuration: AppSpacing.animFast,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MotionUtils.shouldReduceMotion(context)) {
        return child;
      }
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _RouterRefreshNotifier extends ChangeNotifier {
  void trigger() => notifyListeners();
}

class _BootLoadingScreen extends StatelessWidget {
  const _BootLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SizedBox(height: AppSpacing.lg),
              SkeletonBox(width: 180, height: 28),
              SizedBox(height: AppSpacing.lg),
              SkeletonBox(height: 160),
              SizedBox(height: AppSpacing.md),
              SkeletonBox(height: 130),
            ],
          ),
        ),
      ),
    );
  }
}

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final refreshNotifier = _RouterRefreshNotifier();
  ref.onDispose(refreshNotifier.dispose);

  ref.listen<AsyncValue<bool>>(onboardingCompletedProvider, (_, _) {
    refreshNotifier.trigger();
  });

  return GoRouter(
    initialLocation: AppRoutes.boot,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final onboardingState = ref.read(onboardingCompletedProvider);
      final loc = state.matchedLocation;

      if (onboardingState.isLoading) {
        return loc == AppRoutes.boot ? null : AppRoutes.boot;
      }

      final isComplete = onboardingState.value ?? false;
      if (!isComplete) {
        return loc == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }

      if (loc == AppRoutes.boot || loc == AppRoutes.onboarding) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.boot,
        builder: (context, state) => const _BootLoadingScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => buildScaleUpTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
        ),
      ),
      StatefulShellRoute(
        builder: (context, state, navigationShell) => navigationShell,
        navigatorContainerBuilder: (context, navigationShell, children) {
          return AppShellScaffold(
            navigationShell: navigationShell,
            children: children,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.weight,
                builder: (context, state) => const WeightScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.calories,
                builder: (context, state) => const CaloriesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
