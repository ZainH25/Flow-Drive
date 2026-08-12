import 'package:get/get.dart';

import '../../binding/file_map_binding.dart';
import '../file_map_view.dart';

/// Opens the graph file map from the dashboard FAB.
class FileMapLauncher {
  FileMapLauncher._();

  static void open() {
    Get.to(
      () => const FileMapView(),
      binding: FileMapBinding(),
      fullscreenDialog: true,
    );
  }
}
