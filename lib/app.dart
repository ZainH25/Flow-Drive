import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/bindings/initial_binding.dart';
import 'core/constants/app_constants.dart';
import 'core/routing/app_pages.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/responsive.dart';

class FlowDriveApp extends StatelessWidget {
  const FlowDriveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialBinding: InitialBinding(),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        Get.find<ResponsiveController>().updateMetrics(context);

        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(
              mq.textScaler.scale(1).clamp(0.85, 1.15),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
