import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/services/local_storage_service.dart';
import '../../dashboard/model/picked_file_item.dart';
import '../../dashboard/service/quick_actions_service.dart';
import '../service/android_storage_permission.dart';
import '../service/ios_folder_picker.dart';
import '../service/ios_media_browser_service.dart';
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
    if (isAtRoot && pickedExtras.isNotEmpty) {
      final merged = <String, PickedFileItem>{};
      for (final file in [...pickedExtras, ...currentFiles]) {
        merged[fileKey(file)] = file;
      }
      return merged.values.toList()
        ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    }
    return currentFiles.toList();
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

    final initialFolder = _initialFolderFromArgs(args);
    if (initialFolder != null) {
      openAtPath(initialFolder.path, name: initialFolder.name);
    } else {
      loadRoot();
    }
  }

  ({String path, String name})? _initialFolderFromArgs(dynamic args) {
    if (args is! Map) return null;
    final path = args['initialFolderPath']?.toString();
    if (path == null || path.isEmpty) return null;
    final name = args['initialFolderName']?.toString();
    return (
      path: path,
      name: (name != null && name.isNotEmpty)
          ? name
          : LocalFileBrowserService.displayNameForPath(path),
    );
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

  /// Open a specific folder path in the local storage browser (e.g. from File Map).
  Future<void> openAtPath(String path, {String? name}) async {
    isLoading.value = true;
    storagePermissionDenied.value = false;
    try {
      breadcrumbs.clear();

      if (GetPlatform.isAndroid) {
        final granted = await AndroidStoragePermission.ensure();
        storagePermissionDenied.value = !granted;
      }

      systemLocations.assignAll(await LocalFileBrowserService.discoverSystemLocations());
      if (GetPlatform.isIOS) {
        await _appendSavedIosFolderLocation();
      }

      final folder = LocalFileFolder(
        name: (name != null && name.isNotEmpty)
            ? name
            : LocalFileBrowserService.displayNameForPath(path),
        path: path,
        icon: Icons.folder_rounded,
      );

      if (!systemLocations.any((l) => l.path == folder.path)) {
        systemLocations.insert(0, folder);
      }

      _rootFolder = folder;
      await _openPath(folder, resetBreadcrumbs: true);
    } finally {
      isLoading.value = false;
    }
  }

  /// Same path on every platform: discover locations → open root → show
  /// folders/files on screen (no auto picker).
  Future<void> loadRoot() async {
    isLoading.value = true;
    storagePermissionDenied.value = false;
    try {
      breadcrumbs.clear();

      if (GetPlatform.isAndroid) {
        final granted = await AndroidStoragePermission.ensure();
        storagePermissionDenied.value = !granted;
      }

      systemLocations.assignAll(await LocalFileBrowserService.discoverSystemLocations());

      // Optional: last Files-app import as an extra Location chip (iOS only).
      if (GetPlatform.isIOS) {
        await _appendSavedIosFolderLocation();
      }

      final path = await LocalFileBrowserService.defaultBrowsePath();
      if (path == null) return;

      _rootFolder = LocalFileFolder(
        name: LocalFileBrowserService.rootDisplayName(path),
        path: path,
        icon: Icons.folder_rounded,
      );
      await _openPath(_rootFolder!, resetBreadcrumbs: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _appendSavedIosFolderLocation() async {
    if (!Get.isRegistered<LocalStorageService>()) return;
    final storage = Get.find<LocalStorageService>();
    final savedPath = storage.iosSendFolderPath;
    final savedName = storage.iosSendFolderName;
    if (savedPath == null || savedPath.isEmpty) return;
    if (!await Directory(savedPath).exists()) return;
    if (systemLocations.any((l) => l.path == savedPath)) return;

    systemLocations.add(
      LocalFileFolder(
        name: (savedName != null && savedName.isNotEmpty) ? savedName : 'Imported',
        path: savedPath,
        icon: Icons.folder_shared_rounded,
      ),
    );
  }

  /// Optional: import another folder from the Files app into Locations.
  Future<void> pickFolderToBrowse() async {
    if (isPicking.value) return;
    isPicking.value = true;
    try {
      final picked = await IosFolderPicker.pickFolder();
      if (picked == null) return;

      isLoading.value = true;
      final folder = LocalFileFolder(
        name: picked.name,
        path: picked.path,
        icon: Icons.folder_shared_rounded,
      );

      if (!systemLocations.any((l) => l.path == folder.path)) {
        systemLocations.add(folder);
      }

      if (Get.isRegistered<LocalStorageService>()) {
        await Get.find<LocalStorageService>().setIosSendFolder(
          path: picked.path,
          name: picked.name,
        );
      }

      breadcrumbs.clear();
      _rootFolder = folder;
      await _openPath(folder, resetBreadcrumbs: true);
    } on MissingPluginException {
      Get.snackbar(
        'Folder picker unavailable',
        'Fully stop the app and run again (not hot reload).',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Cannot open folder',
        e is Exception ? e.toString() : 'Could not open that folder.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
      isPicking.value = false;
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
      if (picked.isEmpty) return;

      for (final file in picked) {
        _addPickedExtra(file);
        _selectFile(file);
      }
      pickedExtras.refresh();
      selectedFiles.refresh();
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

    _continueToDeviceRadar();
  }

  Future<void> _continueToDeviceRadar() async {
    isLoading.value = true;
    try {
      final resolved = GetPlatform.isIOS
          ? await IosMediaBrowserService.resolveAll(selectedFiles.toList())
          : selectedFiles.toList();

      if (resolved.isEmpty) {
        Get.snackbar(
          'Cannot send files',
          'Could not prepare the selected files. Try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      Get.toNamed(AppRoutes.deviceRadar, arguments: resolved);
    } finally {
      isLoading.value = false;
    }
  }
}
