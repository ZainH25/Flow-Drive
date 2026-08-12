import 'package:get/get.dart';

import '../controller/file_map_controller.dart';

class FileMapBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(FileMapController.new, fenix: true);
  }
}
