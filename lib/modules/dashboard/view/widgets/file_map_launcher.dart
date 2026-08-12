import 'package:get/get.dart';

import '../../binding/graph_map_binding.dart';
import '../file_map_screen.dart';

/// Opens the graph file map from the dashboard FAB.
class FileMapLauncher {
  FileMapLauncher._();

  static void open() {
    Get.to(
      () => const FileMapScreen(),
      binding: GraphMapBinding(),
      fullscreenDialog: true,
    );
  }
}
