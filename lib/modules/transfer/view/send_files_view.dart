import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../dashboard/model/picked_file_item.dart';
import '../controller/send_files_controller.dart';
import '../service/local_file_browser_service.dart';

class SendFilesView extends GetView<SendFilesController> {
  const SendFilesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedCount = controller.selectedFiles.length;
      final hasSelection = selectedCount > 0;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(controller.currentFolderName.value),
          leading: IconButton(
            icon: Icon(
              controller.breadcrumbs.isEmpty
                  ? Icons.arrow_back_rounded
                  : Icons.arrow_back_ios_new_rounded,
            ),
            onPressed: () {
              if (controller.breadcrumbs.isEmpty) {
                Get.back();
              } else {
                controller.goBack();
              }
            },
          ),
        ),
        body: Column(
          children: [
            if (hasSelection) _SelectedFilesBar(controller: controller),
            if (controller.breadcrumbs.isNotEmpty) _BreadcrumbBar(controller: controller),
            Expanded(child: _BrowserBody(controller: controller)),
            _BottomActions(
              selectedCount: selectedCount,
              hasSelection: hasSelection,
              onAddFiles: controller.pickFilesFromDevice,
              onContinue: controller.continueToDeviceRadar,
            ),
          ],
        ),
      );
    });
  }
}

class _SelectedFilesBar extends StatelessWidget {
  const _SelectedFilesBar({required this.controller});

  final SendFilesController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.brandIndigo.withValues(alpha: 0.08),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${controller.selectedFiles.length} selected',
            style: TextStyle(
              fontSize: Responsive.sp(12),
              fontWeight: FontWeight.w700,
              color: AppColors.brandIndigo,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: controller.selectedFiles.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final file = controller.selectedFiles[index];
                return InputChip(
                  label: Text(
                    file.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: Responsive.sp(11)),
                  ),
                  deleteIcon: const Icon(Icons.close_rounded, size: 16),
                  onDeleted: () => controller.removeFromSelection(file),
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.brandIndigo),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BreadcrumbBar extends StatelessWidget {
  const _BreadcrumbBar({required this.controller});

  final SendFilesController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        'My Files / ${controller.breadcrumbs.map((f) => f.name).join(' / ')}',
        style: TextStyle(
          fontSize: Responsive.sp(12),
          color: AppColors.textSecondary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _BrowserBody extends StatelessWidget {
  const _BrowserBody({required this.controller});

  final SendFilesController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    final folders = controller.folders;
    final files = controller.visibleFiles;
    final isAtRoot = controller.isAtRoot;

    if (folders.isEmpty && files.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_open_rounded, size: 48, color: AppColors.textHint),
              const SizedBox(height: 12),
              Text(
                isAtRoot
                    ? 'No local files found yet'
                    : 'No files in this folder',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: Responsive.sp(15),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                Platform.isIOS
                    ? 'Tap Browse Files to open the Files app, iCloud Drive, and other locations.'
                    : 'Tap Add Files to pick files from your device.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: Responsive.sp(13)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: Responsive.pagePadding.copyWith(bottom: 16),
      children: [
        if (isAtRoot) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.infoBannerFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.infoBannerBorder),
            ),
            child: Row(
              children: [
                Icon(
                  Platform.isAndroid
                      ? Icons.folder_copy_rounded
                      : Platform.isIOS
                          ? Icons.phone_iphone_rounded
                          : Platform.isMacOS
                              ? Icons.laptop_mac_rounded
                              : Icons.computer_rounded,
                  color: AppColors.brandIndigo,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocalFileBrowserService.platformLabel,
                        style: TextStyle(
                          fontSize: Responsive.sp(15),
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        Platform.isIOS
                            ? 'Browse app folders below, or open the Files app for iCloud & more'
                            : 'Browse folders and files on this device',
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
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: controller.pickFilesFromDevice,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandIndigo,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.folder_open_rounded, color: Colors.white),
              label: Text(
                Platform.isIOS ? 'Browse Files App' : 'Browse All Files',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (folders.isNotEmpty) ...[
          Text(
            'Folders',
            style: TextStyle(
              fontSize: Responsive.sp(16),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.35,
            ),
            itemCount: folders.length,
            itemBuilder: (context, index) => _FolderTile(
              folder: folders[index],
              onTap: () => controller.openFolder(folders[index]),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (files.isNotEmpty) ...[
          Text(
            isAtRoot ? 'Recents' : 'Files',
            style: TextStyle(
              fontSize: Responsive.sp(16),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.82,
            ),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return _FileGridTile(
                file: file,
                isSelected: controller.isSelected(file),
                onTap: () => controller.toggleSelection(file),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _FolderTile extends StatelessWidget {
  const _FolderTile({required this.folder, required this.onTap});

  final LocalFileFolder folder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brandIndigo.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(folder.icon, color: AppColors.brandIndigo),
              ),
              const Spacer(),
              Text(
                folder.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: Responsive.sp(13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileGridTile extends StatelessWidget {
  const _FileGridTile({
    required this.file,
    required this.isSelected,
    required this.onTap,
  });

  final PickedFileItem file;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isImage = LocalFileBrowserService.isImage(file);
    final path = file.path;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.brandIndigo : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: isImage && path != null && File(path).existsSync()
                          ? Image.file(File(path), fit: BoxFit.cover)
                          : Container(
                              color: AppColors.brandIndigo.withValues(alpha: 0.08),
                              child: Icon(
                                LocalFileBrowserService.iconFor(file),
                                color: AppColors.brandIndigo,
                                size: 32,
                              ),
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: Responsive.sp(11),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          file.sizeLabel,
                          style: TextStyle(
                            fontSize: Responsive.sp(10),
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isSelected)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.brandIndigo,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.selectedCount,
    required this.hasSelection,
    required this.onAddFiles,
    required this.onContinue,
  });

  final int selectedCount;
  final bool hasSelection;
  final VoidCallback onAddFiles;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAddFiles,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandIndigo,
                  side: const BorderSide(color: AppColors.brandIndigo),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Files', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            if (hasSelection) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onContinue,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandIndigo,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Send $selectedCount file${selectedCount == 1 ? '' : 's'} to device',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
