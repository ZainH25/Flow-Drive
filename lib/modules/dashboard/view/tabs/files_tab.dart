import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';

class FilesTab extends StatelessWidget {
  const FilesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      padding: Responsive.pagePadding.copyWith(bottom: 100),
      children: [
        for (final folder in const [
          ('Documents', Icons.description_outlined, '24 files'),
          ('Images', Icons.image_outlined, '128 files'),
          ('Downloads', Icons.download_rounded, '12 files'),
        ])
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(Responsive.radius(16)),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.brandIndigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(folder.$2, color: AppColors.brandIndigo),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folder.$1,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: Responsive.sp(15),
                        ),
                      ),
                      Text(
                        folder.$3,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: Responsive.sp(13),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
      ],
    );

    if (Responsive.isDesktop) {
      return ColoredBox(
        color: AppColors.background,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth),
            child: content,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Files')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth),
          child: content,
        ),
      ),
    );
  }
}
