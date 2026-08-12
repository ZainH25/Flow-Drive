import 'package:get/get.dart';

import '../controller/device_radar_controller.dart';
import '../controller/send_files_controller.dart';
import '../controller/transfer_complete_controller.dart';
import '../model/transfer_device.dart';

class SendBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(SendFilesController.new, fenix: true);
  }
}

class DeviceRadarBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(DeviceRadarController.new, fenix: true);
  }
}

class TransferCompleteBinding extends Bindings {
  @override
  void dependencies() {
    final result = Get.arguments as TransferResult;
    Get.lazyPut(() => TransferCompleteController(result: result));
  }
}
