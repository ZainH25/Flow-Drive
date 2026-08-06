import 'package:flutter/material.dart';

import '../model/onboarding_item.dart';

class OnboardingController extends ChangeNotifier {
  OnboardingController() {
    _pages = const [
      OnboardingItem(
        title: 'Track Every Trip',
        description:
            'Monitor your drives in real time with smart route insights and live updates.',
        icon: Icons.route_rounded,
        gradientColors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
      ),
      OnboardingItem(
        title: 'Stay Connected',
        description:
            'Sync seamlessly with AWS cloud services and access your data anywhere.',
        icon: Icons.cloud_sync_rounded,
        gradientColors: [Color(0xFF1565C0), Color(0xFF00BFA5)],
      ),
      OnboardingItem(
        title: 'Drive with Confidence',
        description:
            'Personalized dashboard, activity history, and secure Cognito authentication.',
        icon: Icons.verified_user_rounded,
        gradientColors: [Color(0xFF002171), Color(0xFF0D47A1)],
      ),
    ];
  }

  late final List<OnboardingItem> _pages;
  final pageController = PageController();
  int _currentPage = 0;

  List<OnboardingItem> get pages => _pages;
  int get currentPage => _currentPage;
  bool get isLastPage => _currentPage == _pages.length - 1;

  void onPageChanged(int index) {
    _currentPage = index;
    notifyListeners();
  }

  void nextPage() {
    if (isLastPage) return;
    pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void disposeController() {
    pageController.dispose();
  }
}
