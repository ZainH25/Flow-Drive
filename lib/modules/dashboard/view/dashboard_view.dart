import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../controller/dashboard_controller.dart';
import 'tabs/files_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/transfers_tab.dart';
import 'widgets/file_map_launcher.dart';

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

      return Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(index: index, children: _tabs),
        floatingActionButton: FloatingActionButton(
          onPressed: FileMapLauncher.open,
          elevation: 4,
          backgroundColor: AppColors.brandIndigo,
          shape: const CircleBorder(),
          child: const Icon(Icons.hub_rounded, color: Colors.white, size: 28),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _DashboardBottomBar(
          selectedIndex: controller.navBarIndex,
          onTap: controller.setNavBarIndex,
        ),
      );
    });
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
            children: [
              Expanded(
                child: _NavItem(
                  label: 'Home',
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  isSelected: selectedIndex == 0,
                  onTap: () => onTap(0),
                ),
              ),
              Expanded(
                child: _NavItem(
                  label: 'Files',
                  icon: Icons.folder_outlined,
                  activeIcon: Icons.folder_rounded,
                  isSelected: selectedIndex == 1,
                  onTap: () => onTap(1),
                ),
              ),
              const SizedBox(width: 44),
              Expanded(
                child: _NavItem(
                  label: 'Transfers',
                  icon: Icons.swap_horiz_outlined,
                  activeIcon: Icons.swap_horiz_rounded,
                  isSelected: selectedIndex == 3,
                  onTap: () => onTap(3),
                ),
              ),
              Expanded(
                child: _NavItem(
                  label: 'Profile',
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  isSelected: selectedIndex == 4,
                  onTap: () => onTap(4),
                ),
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? activeIcon : icon, color: color, size: 21),
            const SizedBox(height: 1),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 9.5,
                  height: 1.1,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
