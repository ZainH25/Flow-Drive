import 'package:flutter/material.dart';

import '../../modules/auth/view/login_view.dart';
import '../../modules/dashboard/view/dashboard_view.dart';
import '../../modules/onboarding/view/onboarding_view.dart';
import '../../modules/splash/view/splash_view.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _fadeRoute(const SplashView(), settings);
      case AppRoutes.login:
        return _slideRoute(const LoginView(), settings);
      case AppRoutes.onboarding:
        return _slideRoute(const OnboardingView(), settings);
      case AppRoutes.dashboard:
        return _fadeRoute(const DashboardView(), settings);
      default:
        return _fadeRoute(const SplashView(), settings);
    }
  }

  static PageRouteBuilder<dynamic> _fadeRoute(
    Widget page,
    RouteSettings settings,
  ) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  static PageRouteBuilder<dynamic> _slideRoute(
    Widget page,
    RouteSettings settings,
  ) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 450),
    );
  }
}
