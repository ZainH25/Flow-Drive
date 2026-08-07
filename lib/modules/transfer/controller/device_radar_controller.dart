import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';

import '../../auth/controller/auth_controller.dart';
import '../../dashboard/model/picked_file_item.dart';
import '../../../core/routing/app_routes.dart';
import '../model/transfer_device.dart';
import '../service/local_file_browser_service.dart';

class DeviceRadarController extends GetxController {
  final files = <PickedFileItem>[].obs;
  final filter = DeviceFilter.all.obs;
  final isSending = false.obs;
  final sendProgress = 0.0.obs;
  final sendingFileName = ''.obs;
  final sendingDestination = ''.obs;
  final sendingFileCount = 1.obs;

  late final TransferDevice hostDevice;
  late final List<TransferDevice> allPeers;

  Timer? _sendTimer;

  List<TransferDevice> get visibleDevices =>
      TransferDevice.filtered(filter.value, allPeers);

  String get userEmail => Get.find<AuthController>().user.value?.email ?? '';

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is List<PickedFileItem>) {
      files.assignAll(args);
    }

    final hostName = Platform.isIOS
        ? 'This iPhone'
        : Platform.isAndroid
            ? 'This Phone'
            : 'My Laptop';

    hostDevice = TransferDevice.host(deviceName: hostName);
    allPeers = TransferDevice.buildPeers();
  }

  @override
  void onClose() {
    _sendTimer?.cancel();
    super.onClose();
  }

  void setFilter(DeviceFilter value) => filter.value = value;

  Future<void> onFilesDroppedOnDevice(
    TransferDevice device,
    List<PickedFileItem> droppedFiles,
  ) async {
    if (!device.isOnline || device.isHost || isSending.value) return;
    if (droppedFiles.isEmpty) return;

    isSending.value = true;
    sendProgress.value = 0;
    sendingFileCount.value = droppedFiles.length;
    sendingFileName.value = droppedFiles.length == 1
        ? droppedFiles.first.name
        : '${droppedFiles.length} files';
    sendingDestination.value = device.name;

    _sendTimer?.cancel();
    _sendTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      sendProgress.value += 0.08;
      if (sendProgress.value >= 1) {
        timer.cancel();
        _completeTransfer(droppedFiles, device);
      }
    });
  }

  void _completeTransfer(List<PickedFileItem> droppedFiles, TransferDevice device) {
    isSending.value = false;
    sendProgress.value = 0;

    final result = TransferResult(
      destinationName: device.name,
      destinationIcon: device.icon,
      files: droppedFiles
          .map(
            (f) => TransferredFileDetail(
              fileName: f.name,
              fileSizeLabel: f.sizeLabel,
              icon: LocalFileBrowserService.iconFor(f),
              extension: f.extension,
            ),
          )
          .toList(),
    );

    Get.offNamed(AppRoutes.transferComplete, arguments: result);
  }

  void cancelSending() {
    _sendTimer?.cancel();
    isSending.value = false;
    sendProgress.value = 0;
  }
}
