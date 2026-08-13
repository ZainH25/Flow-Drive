import 'package:get/get.dart';

import '../../gesture_shapes/controller/gesture_shapes_controller.dart';
import '../controller/file_map_controller.dart';

class FileMapBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(FileMapController.new, fenix: true);
    Get.lazyPut(GestureShapesController.new, fenix: true);
  }
}
