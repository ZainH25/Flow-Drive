import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/responsive_page.dart';
import '../../auth/controller/auth_controller.dart';
import '../controller/onboarding_controller.dart';
import '../model/onboarding_item.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnboardingController());
    final auth = Get.find<AuthController>();

    Future<void> finish() async {
      await auth.completeOnboarding();
      auth.onLoginSuccess();
      Get.offAllNamed(AppRoutes.dashboard);
    }

    return ResponsivePage(
      appBar: AppBar(
        title: const Text('Getting Started'),
        actions: [TextButton(onPressed: finish, child: const Text('Skip'))],
      ),
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: controller.pageController,
              itemCount: controller.pages.length,
              onPageChanged: controller.onPageChanged,
              itemBuilder: (context, index) {
                return _OnboardingPage(item: controller.pages[index]);
              },
            ),
          ),
          Padding(
            padding: Responsive.pagePadding.copyWith(bottom: 32),
            child: Obx(
              () => Column(
                children: [
                  SmoothPageIndicator(
                    controller: controller.pageController,
                    count: controller.pages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: AppColors.brandIndigo,
                      dotColor: AppColors.border,
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                    ),
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: controller.isLastPage ? 'Get Started' : 'Continue',
                    icon: controller.isLastPage
                        ? Icons.rocket_launch_rounded
                        : Icons.arrow_forward_rounded,
                    onPressed: controller.isLastPage ? finish : controller.nextPage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.item});

  final OnboardingItem item;

  @override
  Widget build(BuildContext context) {
    final gradient = item.gradientColors ?? AppColors.onboardingGradientsPage1;

    return Padding(
      padding: Responsive.pagePadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            height: Responsive.isDesktop ? 320 : 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              borderRadius: BorderRadius.circular(Responsive.radius(32)),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.35),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                item.icon,
                size: Responsive.sp(100),
                color: AppColors.textOnPrimary.withValues(alpha: 0.95),
              ),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Responsive.sp(22),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            item.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Responsive.sp(16),
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
