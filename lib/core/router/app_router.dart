import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/calories/presentation/calories_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/weight/presentation/weight_screen.dart';
import '../constants/app_spacing.dart';
import '../utils/reduce_motion.dart';
import 'app_shell_scaffold.dart';

part 'app_router.g.dart';

abstract final class AppRoutes {
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

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
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
