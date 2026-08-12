import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Requests the Android permissions needed to list all file types on device storage.
class AndroidStoragePermission {
  AndroidStoragePermission._();

  static Future<bool> ensure() async {
    if (!Platform.isAndroid) return true;

    final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;

    if (sdk >= 33) {
      // Photos / videos / audio (Android 13+)
      final media = await [
        Permission.photos,
        Permission.videos,
        Permission.audio,
      ].request();

      final mediaOk = media.values.any((s) => s.isGranted || s.isLimited);

      // All-files access so PDFs, docs, zips, etc. also appear in folders.
      final manage = await Permission.manageExternalStorage.request();
      if (manage.isGranted) return true;

      // Still allow browsing media folders if media permission was granted.
      return mediaOk;
    }

    if (sdk >= 30) {
      final manage = await Permission.manageExternalStorage.request();
      if (manage.isGranted) return true;

      final storage = await Permission.storage.request();
      return storage.isGranted;
    }

    final storage = await Permission.storage.request();
    return storage.isGranted;
  }
}
