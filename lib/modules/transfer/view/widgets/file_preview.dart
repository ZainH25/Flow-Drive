import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../../dashboard/model/picked_file_item.dart';
import '../../service/ios_media_browser_service.dart';
import '../../service/local_file_browser_service.dart';

class FilePreview {
  FilePreview._();

  static Future<void> show(BuildContext context, PickedFileItem file) async {
    var item = file;
    if (IosMediaPaths.isAssetRef(item.path)) {
      final resolved = await IosMediaBrowserService.resolveIfNeeded(item);
      if (resolved == null) {
        Get.snackbar(
          'Cannot preview',
          'This file is no longer available on your device.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      item = resolved;
    }

    final path = item.path;
    if (path == null || path.isEmpty) {
      Get.snackbar(
        'Cannot preview',
        'This file is no longer available on your device.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Avoid blocking the UI thread with sync filesystem checks on large media.
    final exists = await File(path).exists();
    if (!exists) {
      Get.snackbar(
        'Cannot preview',
        'This file is no longer available on your device.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (LocalFileBrowserService.isImage(item)) {
      // Large photos can freeze if decoded full-size in-app — open externally when big.
      try {
        final size = await File(path).length();
        if (size > 8 * 1024 * 1024) {
          await _openWithSystemApp(path);
          return;
        }
      } catch (_) {}

      if (!context.mounted) return;
      await _showImagePreview(context, item, path);
      return;
    }

    // Videos / PDFs / other types: open with the system viewer (non-blocking).
    await _openWithSystemApp(path);
  }

  static Future<void> shareFile(String path, String name) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        text: name,
      ),
    );
  }

  static Future<void> _showImagePreview(
    BuildContext context,
    PickedFileItem file,
    String path,
  ) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (MediaQuery.sizeOf(context).width * dpr).round();

    return showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: Image.file(
                  File(path),
                  fit: BoxFit.contain,
                  cacheWidth: cacheWidth,
                  filterQuality: FilterQuality.medium,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        file.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => shareFile(path, file.name),
                      icon: const Icon(Icons.share_rounded, color: Colors.white),
                      tooltip: 'Share',
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _openWithSystemApp(String path) async {
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      Get.snackbar(
        'Cannot open file',
        result.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
