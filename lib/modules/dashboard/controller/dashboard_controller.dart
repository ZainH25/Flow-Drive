import 'package:flutter/material.dart';

class DashboardController extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  static const List<DashboardTab> tabs = [
    DashboardTab(
      label: 'Home',
      icon: Icons.home_rounded,
      activeIcon: Icons.home_filled,
    ),
    DashboardTab(
      label: 'Drive',
      icon: Icons.directions_car_outlined,
      activeIcon: Icons.directions_car_rounded,
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
    if (index == _currentIndex) return;
    _currentIndex = index;
    notifyListeners();
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
