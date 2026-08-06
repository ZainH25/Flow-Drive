import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';

class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth(context)),
        child: GridView.count(
          crossAxisCount: Responsive.isDesktop(context) ? 4 : 2,
          padding: Responsive.pagePadding(context),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: const [
            _ExploreTile(
              title: 'Devices',
              icon: Icons.devices_rounded,
              color: AppColors.primary,
            ),
            _ExploreTile(
              title: 'Shared Files',
              icon: Icons.folder_shared_rounded,
              color: AppColors.accent,
            ),
            _ExploreTile(
              title: 'Nearby',
              icon: Icons.wifi_tethering_rounded,
              color: AppColors.primaryLight,
            ),
            _ExploreTile(
              title: 'Quick Send',
              icon: Icons.send_rounded,
              color: AppColors.purple,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreTile extends StatelessWidget {
  const _ExploreTile({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
