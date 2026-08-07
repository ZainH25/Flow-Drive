import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../controller/dashboard_controller.dart';
import 'tabs/files_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/transfers_tab.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  static const _tabs = <Widget>[
    HomeTab(),
    FilesTab(),
    TransfersTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final index = controller.currentIndex.value;

      if (Responsive.isDesktop) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(DashboardController.tabs[index].label),
            actions: [
              IconButton(onPressed: _showQuickSend, icon: const Icon(Icons.add_rounded)),
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
              Expanded(child: IndexedStack(index: index, children: _tabs)),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showQuickSend,
            backgroundColor: AppColors.brandIndigo,
            child: const Icon(Icons.add_rounded, color: Colors.white),
          ),
        );
      }

      return Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(index: index, children: _tabs),
        floatingActionButton: FloatingActionButton(
          onPressed: _showQuickSend,
          elevation: 4,
          backgroundColor: AppColors.brandIndigo,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _DashboardBottomBar(
          selectedIndex: controller.navBarIndex,
          onTap: controller.setNavBarIndex,
        ),
      );
    });
  }

  void _showQuickSend() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Quick Send',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Send files instantly to a connected device.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.upload_file_rounded, color: AppColors.brandIndigo),
              title: const Text('Send a file'),
              onTap: () => Get.back(),
            ),
            ListTile(
              leading: const Icon(Icons.devices_rounded, color: AppColors.brandIndigo),
              title: const Text('Add device'),
              onTap: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardBottomBar extends StatelessWidget {
  const _DashboardBottomBar({
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.surface,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 53,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
          _NavItem(
            label: 'Home',
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            isSelected: selectedIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            label: 'Files',
            icon: Icons.folder_outlined,
            activeIcon: Icons.folder_rounded,
            isSelected: selectedIndex == 1,
            onTap: () => onTap(1),
          ),
          const SizedBox(width: 48),
          _NavItem(
            label: 'Transfers',
            icon: Icons.swap_horiz_outlined,
            activeIcon: Icons.swap_horiz_rounded,
            isSelected: selectedIndex == 3,
            onTap: () => onTap(3),
          ),
          _NavItem(
            label: 'Profile',
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            isSelected: selectedIndex == 4,
            onTap: () => onTap(4),
          ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.brandIndigo : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? activeIcon : icon, color: color, size: 21),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                height: 1.1,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
