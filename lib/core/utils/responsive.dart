import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// GetX-aware responsive helpers — use [width] / [height] without BuildContext.
class Responsive {
  Responsive._();

  static double get width => Get.width;

  static double get height => Get.height;

  static double get textScale =>
      Get.mediaQuery.textScaler.scale(1).clamp(0.85, 1.15);

  static bool get isDesktop => width >= 900;

  static bool get isTablet => width >= 600 && width < 900;

  static bool get isMobile => width < 600;

  static EdgeInsets get pagePadding {
    if (isDesktop) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 32);
    }
    if (isTablet) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    }
    return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
  }

  static double get authCardWidth {
    if (isDesktop) return 480;
    if (isTablet) return 440;
    return width.clamp(280, 420);
  }

  static double get contentMaxWidth {
    if (isDesktop) return 1100;
    if (isTablet) return 760;
    return double.infinity;
  }

  static double sp(double size) => size * textScale;

  static double radius(double base) {
    if (isDesktop) return base + 4;
    if (isMobile) return base;
    return base + 2;
  }

  // Context-based aliases for widgets still using BuildContext.
  static EdgeInsets pagePaddingOf(BuildContext context) => pagePadding;

  static double authCardWidthOf(BuildContext context) => authCardWidth;

  static double contentMaxWidthOf(BuildContext context) => contentMaxWidth;

  static bool isDesktopOf(BuildContext context) => isDesktop;
}

class ResponsiveController extends GetxController {
  final screenWidth = 0.0.obs;
  final screenHeight = 0.0.obs;

  void updateMetrics(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    screenWidth.value = size.width;
    screenHeight.value = size.height;
  }

  bool get isDesktop => screenWidth.value >= 900;

  bool get isTablet => screenWidth.value >= 600 && screenWidth.value < 900;
}
