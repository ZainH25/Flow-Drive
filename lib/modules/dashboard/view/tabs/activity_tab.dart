import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';

class ActivityTab extends StatelessWidget {
  const ActivityTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth),
        child: ListView(
          padding: Responsive.pagePadding,
          children: [
            Text(
              'Recent Transfers',
              style: TextStyle(
                fontSize: Responsive.sp(18),
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  tileColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Responsive.radius(14)),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.history_rounded, color: AppColors.primary),
                  ),
                  title: Text('Transfer ${i + 1}'),
                  subtitle: const Text('No transfers yet — connect a device'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
