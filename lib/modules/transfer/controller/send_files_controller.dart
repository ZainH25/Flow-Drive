import 'package:get/get.dart';

import '../../dashboard/model/picked_file_item.dart';
import '../../dashboard/service/quick_actions_service.dart';
import '../../../core/routing/app_routes.dart';
import '../service/local_file_browser_service.dart';

class SendFilesController extends GetxController {
  final folders = <LocalFileFolder>[].obs;
  final currentFiles = <PickedFileItem>[].obs;
  final recentFiles = <PickedFileItem>[].obs;
  final addedFiles = <PickedFileItem>[].obs;
  final selectedFiles = <PickedFileItem>[].obs;
  final isLoading = false.obs;
  final currentFolderName = 'My Files'.obs;
  final breadcrumbs = <LocalFileFolder>[].obs;

  bool get isAtRoot => breadcrumbs.isEmpty;

  List<PickedFileItem> get visibleFiles {
    if (isAtRoot) {
      final merged = <String, PickedFileItem>{};
      for (final file in [...addedFiles, ...recentFiles, ...currentFiles]) {
        merged[fileKey(file)] = file;
      }
      return merged.values.toList();
    }
    return currentFiles;
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is List<PickedFileItem> && args.isNotEmpty) {
      for (final file in args) {
        _selectFile(file);
      }
    }
    loadRoot();
  }

  String fileKey(PickedFileItem file) => '${file.path ?? ''}|${file.name}';

  bool isSelected(PickedFileItem file) =>
      selectedFiles.any((f) => fileKey(f) == fileKey(file));

  void toggleSelection(PickedFileItem file) {
    final key = fileKey(file);
    final index = selectedFiles.indexWhere((f) => fileKey(f) == key);
    if (index >= 0) {
      selectedFiles.removeAt(index);
    } else {
      selectedFiles.add(file);
    }
  }

  void _selectFile(PickedFileItem file) {
    if (!isSelected(file)) {
      selectedFiles.add(file);
    }
  }

  void removeFromSelection(PickedFileItem file) {
    selectedFiles.removeWhere((f) => fileKey(f) == fileKey(file));
  }

  Future<void> loadRoot() async {
    isLoading.value = true;
    try {
      folders.assignAll(await LocalFileBrowserService.getRootFolders());
      currentFiles.clear();
      breadcrumbs.clear();
      currentFolderName.value = 'My Files';
      recentFiles.assignAll(await LocalFileBrowserService.loadRecentFiles());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> openFolder(LocalFileFolder folder) async {
    await _navigateToFolder(folder, addToBreadcrumbs: true);
  }

  Future<void> _navigateToFolder(
    LocalFileFolder folder, {
    required bool addToBreadcrumbs,
  }) async {
    isLoading.value = true;
    try {
      final result = await LocalFileBrowserService.explore(folder.path);
      folders.assignAll(result.folders);
      currentFiles.assignAll(result.files);
      currentFolderName.value = folder.name;
      if (addToBreadcrumbs) breadcrumbs.add(folder);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> goBack() async {
    if (breadcrumbs.isEmpty) {
      Get.back();
      return;
    }
    breadcrumbs.removeLast();
    if (breadcrumbs.isEmpty) {
      await loadRoot();
    } else {
      await _navigateToFolder(breadcrumbs.last, addToBreadcrumbs: false);
    }
  }

  Future<void> pickFilesFromDevice() async {
    final picked = await QuickActionsService.pickFilesToSend();
    for (final file in picked) {
      final key = fileKey(file);
      if (!addedFiles.any((f) => fileKey(f) == key)) {
        addedFiles.add(file);
      }
      _selectFile(file);
    }
  }

  void continueToDeviceRadar() {
    if (selectedFiles.isEmpty) {
      Get.snackbar(
        'No files selected',
        'Select at least one file to send',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.toNamed(AppRoutes.deviceRadar, arguments: selectedFiles.toList());
  }
}
