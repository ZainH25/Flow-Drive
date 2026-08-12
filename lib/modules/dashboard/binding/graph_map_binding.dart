import 'package:get/get.dart';

import '../controller/graph_map_controller.dart';

class GraphMapBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(GraphMapController.new, fenix: true);
  }
}
