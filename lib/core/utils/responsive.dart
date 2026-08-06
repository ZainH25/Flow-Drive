import 'package:flutter/material.dart';

class Responsive {
  Responsive._();

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  static double height(BuildContext context) => MediaQuery.sizeOf(context).height;

  static bool isDesktop(BuildContext context) => width(context) >= 900;

  static bool isTablet(BuildContext context) =>
      width(context) >= 600 && width(context) < 900;

  static EdgeInsets pagePadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 32);
    }
    if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    }
    return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
  }

  static double authCardWidth(BuildContext context) {
    final w = width(context);
    if (isDesktop(context)) return 480;
    if (isTablet(context)) return 440;
    return w.clamp(280, 420);
  }

  static double contentMaxWidth(BuildContext context) {
    if (isDesktop(context)) return 1100;
    if (isTablet(context)) return 760;
    return double.infinity;
  }
}
