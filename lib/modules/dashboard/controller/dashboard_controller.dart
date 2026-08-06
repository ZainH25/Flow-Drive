import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashboardController extends GetxController {
  final currentIndex = 0.obs;

  static const tabs = <DashboardTab>[
    DashboardTab(
      label: 'Home',
      icon: Icons.home_rounded,
      activeIcon: Icons.home_filled,
    ),
    DashboardTab(
      label: 'Canvas',
      icon: Icons.hub_outlined,
      activeIcon: Icons.hub_rounded,
    ),
    DashboardTab(
      label: 'Activity',
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
    ),
    DashboardTab(
      label: 'Explore',
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
    ),
    DashboardTab(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  void setIndex(int index) {
    if (index == currentIndex.value) return;
    currentIndex.value = index;
  }
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
