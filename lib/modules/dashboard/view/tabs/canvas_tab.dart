import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';

class CanvasTab extends StatelessWidget {
  const CanvasTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth),
        child: Padding(
          padding: Responsive.pagePadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.hub_rounded,
                  size: 56,
                  color: AppColors.textOnPrimary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Spatial Canvas',
                style: TextStyle(
                  fontSize: Responsive.sp(22),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your node-based transfer canvas will live here. Drag files between devices, pinch to zoom, and route data with spatial gestures.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: Responsive.sp(15),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
