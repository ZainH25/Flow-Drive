import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashboardController extends GetxController {
  final currentIndex = 0.obs;

  static const tabs = <DashboardTab>[
    DashboardTab(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    DashboardTab(
      label: 'Files',
      icon: Icons.folder_outlined,
      activeIcon: Icons.folder_rounded,
    ),
    DashboardTab(
      label: 'Transfers',
      icon: Icons.swap_horiz_outlined,
      activeIcon: Icons.swap_horiz_rounded,
    ),
    DashboardTab(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  /// Bottom bar slot index (0–4) with FAB at slot 2.
  int get navBarIndex => switch (currentIndex.value) {
        0 => 0,
        1 => 1,
        2 => 3,
        3 => 4,
        _ => 0,
      };

  void setNavBarIndex(int navIndex) {
    if (navIndex == 2) return;
    currentIndex.value = switch (navIndex) {
      0 => 0,
      1 => 1,
      3 => 2,
      4 => 3,
      _ => currentIndex.value,
    };
  }

  void setIndex(int index) {
    if (index == currentIndex.value) return;
    currentIndex.value = index;
  }

  void goHome() => currentIndex.value = 0;
}

class DashboardTab {
  const DashboardTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}
