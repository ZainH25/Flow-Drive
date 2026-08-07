import 'package:get/get.dart';

import '../../dashboard/controller/dashboard_controller.dart';
import '../../../core/routing/app_routes.dart';
import '../model/transfer_device.dart';

class TransferCompleteController extends GetxController {
  TransferCompleteController({required this.result});

  final TransferResult result;

  void onDone() {
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().goHome();
    }
    Get.until((route) => route.settings.name == AppRoutes.dashboard);
  }

  void onSendAnother() {
    Get.offNamed(AppRoutes.sendFiles);
  }
}
