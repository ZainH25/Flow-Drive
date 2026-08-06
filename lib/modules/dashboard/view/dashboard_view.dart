import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controller/dashboard_controller.dart';
import 'tabs/activity_tab.dart';
import 'tabs/drive_tab.dart';
import 'tabs/explore_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/profile_tab.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  static const _tabs = <Widget>[
    HomeTab(),
    DriveTab(),
    ActivityTab(),
    ExploreTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DashboardController>();

    return Scaffold(
      body: IndexedStack(
        index: controller.currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: controller.currentIndex,
        onDestinationSelected: controller.setIndex,
        destinations: [
          for (final tab in DashboardController.tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.activeIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}
