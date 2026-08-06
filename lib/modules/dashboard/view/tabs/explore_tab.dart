import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(20),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: const [
        _ExploreTile(
          title: 'Routes',
          icon: Icons.map_rounded,
          color: AppColors.primary,
        ),
        _ExploreTile(
          title: 'Places',
          icon: Icons.place_rounded,
          color: AppColors.accent,
        ),
        _ExploreTile(
          title: 'Community',
          icon: Icons.groups_rounded,
          color: AppColors.primaryLight,
        ),
        _ExploreTile(
          title: 'Tips',
          icon: Icons.lightbulb_rounded,
          color: Color(0xFF7E57C2),
        ),
      ],
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
