import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../model/picked_file_item.dart';

class QuickActionSheets {
  QuickActionSheets._();

  static Future<void> showSendFiles(
    RxList<PickedFileItem> files, {
    String title = 'Send files',
  }) {
    return Get.bottomSheet(
      Obx(
        () => _FileListSheet(
          title: title,
          subtitle: 'Select a device to send these files',
          files: files.toList(),
          emptyMessage: 'No files selected',
          primaryActionLabel: 'Send to device',
          onPrimaryAction: () {
            Get.back();
            Get.snackbar(
              'Ready to send',
              '${files.length} file(s) queued for transfer',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppColors.brandIndigo,
              colorText: Colors.white,
              margin: const EdgeInsets.all(16),
              borderRadius: 12,
            );
          },
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  static Future<void> showReceivedFiles(RxList<PickedFileItem> files) {
    return Get.bottomSheet(
      Obx(
        () => _FileListSheet(
          title: 'Received files',
          subtitle: 'Files shared with you from other devices',
          files: files.toList(),
          emptyMessage:
              'No files received yet.\nKeep this open while someone sends to you.',
          primaryActionLabel: 'Close',
          onPrimaryAction: Get.back,
          showPrimaryOnlyWhenNotEmpty: false,
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  static Future<void> showBrowseFiles(RxList<PickedFileItem> files) {
    return Get.bottomSheet(
      _FileListSheet(
        title: 'Browse files',
        subtitle: 'Files from your local storage',
        files: files.toList(),
        emptyMessage: 'No files browsed',
        primaryActionLabel: 'Close',
        onPrimaryAction: Get.back,
        showPrimaryOnlyWhenNotEmpty: false,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _FileListSheet extends StatelessWidget {
  const _FileListSheet({
    required this.title,
    required this.subtitle,
    required this.files,
    required this.emptyMessage,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.showPrimaryOnlyWhenNotEmpty = true,
  });

  final String title;
  final String subtitle;
  final List<PickedFileItem> files;
  final String emptyMessage;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final bool showPrimaryOnlyWhenNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: TextStyle(
                fontSize: Responsive.sp(18),
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: Responsive.sp(13),
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: files.isEmpty
                ? _EmptyFilesState(message: emptyMessage)
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: files.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => _FileRow(file: files[index]),
                  ),
          ),
          if (!showPrimaryOnlyWhenNotEmpty || files.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onPrimaryAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandIndigo,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(primaryActionLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({required this.file});

  final PickedFileItem file;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.brandIndigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _iconForExtension(file.extension),
              color: AppColors.brandIndigo,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Responsive.sp(14),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  file.sizeLabel,
                  style: TextStyle(
                    fontSize: Responsive.sp(12),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForExtension(String? ext) {
    final value = ext?.toLowerCase();
    return switch (value) {
      'jpg' || 'jpeg' || 'png' || 'gif' || 'webp' => Icons.image_rounded,
      'mp4' || 'mov' || 'avi' => Icons.videocam_rounded,
      'mp3' || 'wav' => Icons.audiotrack_rounded,
      'pdf' => Icons.picture_as_pdf_rounded,
      'zip' || 'rar' => Icons.folder_zip_rounded,
      _ => Icons.insert_drive_file_rounded,
    };
  }
}

class _EmptyFilesState extends StatelessWidget {
  const _EmptyFilesState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 48,
              color: AppColors.textHint.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.sp(14),
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
