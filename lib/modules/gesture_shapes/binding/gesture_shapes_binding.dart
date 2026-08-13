import 'package:get/get.dart';

import '../controller/gesture_shapes_controller.dart';

class GestureShapesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(GestureShapesController.new, fenix: true);
  }
}
