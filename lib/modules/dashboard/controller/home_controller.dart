import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/services/device_storage_service.dart';
import '../model/picked_file_item.dart';
import '../service/quick_actions_service.dart';
import '../view/widgets/quick_action_sheets.dart';

class HomeController extends GetxController {
  final isLoadingStorage = true.obs;
  final storagePercent = 0.0.obs;
  final storageUsedLabel = '--'.obs;
  final storageTotalLabel = '--'.obs;
  final storageFreeLabel = '--'.obs;
  final storageError = RxnString();

  final outgoingFiles = <PickedFileItem>[].obs;
  final receivedFiles = <PickedFileItem>[].obs;
  final browsedFiles = <PickedFileItem>[].obs;

  final devices = <HomeDevice>[
    const HomeDevice(
      name: 'My Laptop',
      icon: Icons.laptop_mac_rounded,
      iconColor: Color(0xFF4D49FF),
    ),
    const HomeDevice(
      name: 'Office PC',
      icon: Icons.desktop_windows_rounded,
      iconColor: Color(0xFF1976D2),
    ),
    const HomeDevice(
      name: 'Android Phone',
      icon: Icons.smartphone_rounded,
      iconColor: Color(0xFF00BFA5),
    ),
  ];

  final transfers = <HomeTransfer>[
    const HomeTransfer(
      name: 'Project_Proposal_v2.pdf',
      subtitle: '2.4 MB • To Android Phone',
      time: 'Just now',
      icon: Icons.picture_as_pdf_rounded,
      iconColor: Color(0xFFE53935),
      iconBg: Color(0xFFFFEBEE),
    ),
    const HomeTransfer(
      name: 'Design_Assets.zip',
      subtitle: '45.8 MB • From My Laptop',
      time: '2m ago',
      icon: Icons.folder_zip_rounded,
      iconColor: Color(0xFF7E57C2),
      iconBg: Color(0xFFF3E5F5),
    ),
    const HomeTransfer(
      name: 'Team_Photo.jpg',
      subtitle: '1.2 MB • To Office PC',
      time: '1h ago',
      icon: Icons.image_rounded,
      iconColor: Color(0xFF1976D2),
      iconBg: Color(0xFFE3F2FD),
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    loadDeviceStorage();
  }

  Future<void> loadDeviceStorage() async {
    isLoadingStorage.value = true;
    storageError.value = null;

    try {
      final info = await DeviceStorageService.fetch();
      if (info == null) {
        storageError.value = 'Unable to read device storage';
        return;
      }

      storagePercent.value = info.usedFraction;
      storageUsedLabel.value = info.usedFormatted;
      storageTotalLabel.value = info.totalFormatted;
      storageFreeLabel.value = info.freeFormatted;
    } catch (_) {
      // print("🔥 REAL STORAGE ERROR: $e");
      // print("🔥 STACK TRACE: $stackTrace");
      storageError.value = 'Unable to read device storage';
    } finally {
      isLoadingStorage.value = false;
    }
  }

  int get usedPercent => (storagePercent.value * 100).round().clamp(0, 100);

  Future<void> sendFiles() async {
    Get.toNamed(AppRoutes.sendFiles);
  }

  Future<void> receiveFiles() async {
    await QuickActionSheets.showReceivedFiles(receivedFiles);
  }

  Future<void> browseFiles() async {
    final files = await QuickActionsService.browseLocalFiles();
    if (files.isEmpty) return;

    browsedFiles.assignAll(files);
    await QuickActionSheets.showBrowseFiles(browsedFiles);
  }

  Future<void> scanImage() async {
    final image = await QuickActionsService.captureImage();
    if (image == null) return;

    Get.toNamed(AppRoutes.deviceRadar, arguments: [image]);
  }

  void addReceivedFile(PickedFileItem file) {
    receivedFiles.insert(0, file);
  }
}

class HomeDevice {
  const HomeDevice({
    required this.name,
    required this.icon,
    required this.iconColor,
    this.isOnline = true,
  });

  final String name;
  final IconData icon;
  final Color iconColor;
  final bool isOnline;
}

class HomeTransfer {
  const HomeTransfer({
    required this.name,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  final String name;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
}
