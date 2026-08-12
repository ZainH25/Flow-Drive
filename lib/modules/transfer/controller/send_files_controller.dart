import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../dashboard/model/picked_file_item.dart';
import '../../dashboard/service/quick_actions_service.dart';
import '../../../core/routing/app_routes.dart';
import '../service/android_storage_permission.dart';
import '../service/local_file_browser_service.dart';

class SendFilesController extends GetxController {
  final folders = <LocalFileFolder>[].obs;
  final currentFiles = <PickedFileItem>[].obs;
  final systemLocations = <LocalFileFolder>[].obs;
  final pickedExtras = <PickedFileItem>[].obs;
  final selectedFiles = <PickedFileItem>[].obs;
  final isLoading = false.obs;
  final isPicking = false.obs;
  final currentFolderName = 'My Files'.obs;
  final breadcrumbs = <LocalFileFolder>[].obs;
  final storagePermissionDenied = false.obs;

  LocalFileFolder? _rootFolder;

  bool get isAtRoot => breadcrumbs.isEmpty;

  List<PickedFileItem> get visibleFiles {
    if (GetPlatform.isIOS) {
      return pickedExtras.toList()
        ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    }
    if (isAtRoot && pickedExtras.isNotEmpty) {
      final merged = <String, PickedFileItem>{};
      for (final file in [...pickedExtras, ...currentFiles]) {
        merged[fileKey(file)] = file;
      }
      return merged.values.toList()
        ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    }
    return currentFiles;
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is List<PickedFileItem> && args.isNotEmpty) {
      for (final file in args) {
        _addPickedExtra(file);
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

  void _addPickedExtra(PickedFileItem file) {
    if (!pickedExtras.any((f) => fileKey(f) == fileKey(file))) {
      pickedExtras.add(file);
    }
  }

  Future<void> loadRoot() async {
    isLoading.value = true;
    storagePermissionDenied.value = false;
    try {
      breadcrumbs.clear();

      // iOS: Files app content is only available via the system picker (sandbox).
      // Do not surface app-container folders (Documents / Library / etc.).
      if (GetPlatform.isIOS) {
        systemLocations.clear();
        folders.clear();
        currentFiles.clear();
        currentFolderName.value = 'Files';
        _rootFolder = null;
        return;
      }

      if (GetPlatform.isAndroid) {
        final granted = await AndroidStoragePermission.ensure();
        storagePermissionDenied.value = !granted;
      }

      systemLocations.assignAll(await LocalFileBrowserService.discoverSystemLocations());

      final path = await LocalFileBrowserService.defaultBrowsePath();
      if (path == null) return;

      _rootFolder = LocalFileFolder(
        name: LocalFileBrowserService.displayNameForPath(path),
        path: path,
        icon: Icons.folder_rounded,
      );

      await _openPath(_rootFolder!, resetBreadcrumbs: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> openFolder(LocalFileFolder folder) async {
    if (breadcrumbs.isEmpty && _rootFolder != null) {
      breadcrumbs.add(_rootFolder!);
    }
    await _navigateToFolder(folder, addToBreadcrumbs: true);
  }

  Future<void> openSystemLocation(LocalFileFolder location) async {
    isLoading.value = true;
    try {
      breadcrumbs.clear();
      _rootFolder = location;
      await _openPath(location, resetBreadcrumbs: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _openPath(LocalFileFolder folder, {required bool resetBreadcrumbs}) async {
    final result = await LocalFileBrowserService.explore(folder.path);
    folders.assignAll(result.folders);
    currentFiles.assignAll(result.files);
    currentFolderName.value = folder.name;
    if (resetBreadcrumbs) breadcrumbs.clear();
  }

  Future<void> _navigateToFolder(
    LocalFileFolder folder, {
    required bool addToBreadcrumbs,
  }) async {
    isLoading.value = true;
    try {
      await _openPath(folder, resetBreadcrumbs: false);
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
      if (_rootFolder != null) {
        await _openPath(_rootFolder!, resetBreadcrumbs: true);
      } else {
        await loadRoot();
      }
    } else {
      await _navigateToFolder(breadcrumbs.last, addToBreadcrumbs: false);
    }
  }

  Future<void> pickFilesFromDevice() async {
    if (isPicking.value) return;
    isPicking.value = true;
    try {
      if (GetPlatform.isAndroid) {
        await AndroidStoragePermission.ensure();
      }
      final picked = await QuickActionsService.pickFilesToSend();
      for (final file in picked) {
        _addPickedExtra(file);
        _selectFile(file);
      }
    } on FilePickerException catch (e) {
      Get.snackbar(
        'Cannot open files',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isPicking.value = false;
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
