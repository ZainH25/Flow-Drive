import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../controller/home_controller.dart';

class TransfersTab extends StatelessWidget {
  const TransfersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();

    final content = ListView(
      padding: Responsive.pagePadding.copyWith(bottom: 100),
      children: [
        for (final transfer in home.transfers)
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
                    color: transfer.iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(transfer.icon, color: transfer.iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transfer.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: Responsive.sp(14),
                        ),
                      ),
                      Text(
                        transfer.subtitle,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: Responsive.sp(12),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  transfer.time,
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: Responsive.sp(12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Transfers')),
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
