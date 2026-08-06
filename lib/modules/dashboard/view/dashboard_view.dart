import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../controller/dashboard_controller.dart';
import 'tabs/activity_tab.dart';
import 'tabs/canvas_tab.dart';
import 'tabs/explore_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/profile_tab.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  static const _tabs = <Widget>[
    HomeTab(),
    CanvasTab(),
    ActivityTab(),
    ExploreTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final index = controller.currentIndex.value;
      final tab = DashboardController.tabs[index];

      if (Responsive.isDesktop) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(tab.label),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: Responsive.sp(13),
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: index,
                onDestinationSelected: controller.setIndex,
                labelType: NavigationRailLabelType.all,
                destinations: [
                  for (final t in DashboardController.tabs)
                    NavigationRailDestination(
                      icon: Icon(t.icon),
                      selectedIcon: Icon(t.activeIcon),
                      label: Text(t.label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: IndexedStack(index: index, children: _tabs),
              ),
            ],
          ),
        );
      }

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(tab.label),
          centerTitle: false,
        ),
        body: IndexedStack(index: index, children: _tabs),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: controller.setIndex,
          destinations: [
            for (final t in DashboardController.tabs)
              NavigationDestination(
                icon: Icon(t.icon),
                selectedIcon: Icon(t.activeIcon),
                label: t.label,
              ),
          ],
        ),
      );
    });
  }
}
