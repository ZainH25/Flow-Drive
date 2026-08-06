import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../model/onboarding_item.dart';

class OnboardingController extends GetxController {
  OnboardingController() {
    pages = const [
      OnboardingItem(
        title: 'Instant Cross-Device Transfer',
        description:
            'Send and retrieve files rapidly across Windows, iOS, and Android without digging through folders.',
        icon: Icons.devices_rounded,
        gradientColors: AppColors.onboardingGradientsPage1,
      ),
      OnboardingItem(
        title: 'Spatial Canvas',
        description:
            'Files and target devices appear as floating nodes — route data visually across your connected systems.',
        icon: Icons.hub_outlined,
        gradientColors: AppColors.onboardingGradientsPage2,
      ),
      OnboardingItem(
        title: 'Gesture-Driven Flow',
        description:
            'Drag between nodes, pinch, and swipe to transfer files frictionlessly with spatial gestures.',
        icon: Icons.touch_app_rounded,
        gradientColors: AppColors.onboardingGradientsPage3,
      ),
    ];
  }

  late final List<OnboardingItem> pages;
  final pageController = PageController();
  final currentPage = 0.obs;

  bool get isLastPage => currentPage.value == pages.length - 1;

  void onPageChanged(int index) => currentPage.value = index;

  void nextPage() {
    if (isLastPage) return;
    pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
