import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../dashboard/model/picked_file_item.dart';
import '../controller/send_files_controller.dart';
import '../service/ios_media_browser_service.dart';
import '../service/local_file_browser_service.dart';
import 'widgets/file_preview.dart';

class SendFilesView extends GetView<SendFilesController> {
  const SendFilesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Obx(() => Text(controller.currentFolderName.value)),
        leading: Obx(() {
          return IconButton(
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
          );
        }),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth),
          child: Column(
            children: [
              Obx(() {
                if (controller.selectedFiles.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _SelectedFilesBar(controller: controller);
              }),
              Obx(() {
                if (controller.breadcrumbs.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _BreadcrumbBar(controller: controller);
              }),
              Expanded(child: _BrowserBody(controller: controller)),
              Obx(() {
                return _BottomActions(
                  selectedCount: controller.selectedFiles.length,
                  hasSelection: controller.selectedFiles.isNotEmpty,
                  isPicking: controller.isPicking.value,
                  browseLabel: 'Add Files',
                  onBrowse: controller.pickFilesFromDevice,
                  onContinue: controller.continueToDeviceRadar,
                );
              }),
            ],
          ),
        ),
      ),
    );
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
          Obx(() {
            return Text(
              '${controller.selectedFiles.length} selected',
              style: TextStyle(
                fontSize: Responsive.sp(12),
                fontWeight: FontWeight.w700,
                color: AppColors.brandIndigo,
              ),
            );
          }),
          const SizedBox(height: 8),
          Obx(() {
            return SizedBox(
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
            );
          }),
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
    return Obx(() {
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
    });
  }
}

class _BrowserBody extends StatelessWidget {
  const _BrowserBody({required this.controller});

  final SendFilesController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return _FolderBrowserBody(controller: controller);
    });
  }
}

class _FolderBrowserBody extends StatelessWidget {
  const _FolderBrowserBody({required this.controller});

  final SendFilesController controller;

  static const _folderGrid = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 0.95,
  );

  static const _fileGrid = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 0.85,
  );

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final folders = controller.folders.toList();
      final files = controller.visibleFiles;
      final isAtRoot = controller.isAtRoot;

      return CustomScrollView(
        key: ValueKey('${controller.currentFolderName.value}-${files.length}-${folders.length}'),
        slivers: [
          SliverPadding(
            padding: Responsive.pagePadding.copyWith(bottom: 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (Platform.isAndroid && controller.storagePermissionDenied.value)
                  _AndroidPermissionBanner(controller: controller),
                if (isAtRoot) ...[
                  _PlatformInfoBanner(),
                  const SizedBox(height: 12),
                  _ChooseMoreFilesButton(controller: controller),
                  if (Platform.isIOS) ...[
                    const SizedBox(height: 10),
                    _ImportFolderButton(controller: controller),
                  ],
                  const SizedBox(height: 20),
                ],
                if (isAtRoot && controller.systemLocations.isNotEmpty) ...[
                  Text(
                    'Locations',
                    style: TextStyle(
                      fontSize: Responsive.sp(16),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LocationChips(controller: controller),
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
                ],
              ]),
            ),
          ),
          if (folders.isNotEmpty)
            SliverPadding(
              padding: Responsive.pagePadding.copyWith(top: 0, bottom: 0),
              sliver: SliverGrid(
                gridDelegate: _folderGrid,
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _FolderTile(
                    folder: folders[index],
                    onTap: () => controller.openFolder(folders[index]),
                  ),
                  childCount: folders.length,
                ),
              ),
            ),
          if (folders.isNotEmpty)
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          if (files.isNotEmpty)
            SliverPadding(
              padding: Responsive.pagePadding.copyWith(top: 0, bottom: 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    'Files',
                    style: TextStyle(
                      fontSize: Responsive.sp(16),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap to select · Long press to preview',
                    style: TextStyle(
                      fontSize: Responsive.sp(12),
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
          if (files.isNotEmpty)
            SliverPadding(
              padding: Responsive.pagePadding.copyWith(top: 0, bottom: 16),
              sliver: SliverGrid(
                gridDelegate: _fileGrid,
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final file = files[index];
                    return _FileGridTile(
                      key: ValueKey(file.path ?? file.name),
                      file: file,
                      onTap: () => controller.toggleSelection(file),
                      onLongPress: () => FilePreview.show(context, file),
                    );
                  },
                  childCount: files.length,
                ),
              ),
            ),
          if (files.isEmpty && folders.isEmpty)
            SliverPadding(
              padding: Responsive.pagePadding,
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      'No files found in this location.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: Responsive.sp(14),
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _AndroidPermissionBanner extends StatelessWidget {
  const _AndroidPermissionBanner({required this.controller});

  final SendFilesController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Storage access needed',
            style: TextStyle(
              fontSize: Responsive.sp(14),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Allow Files and media / All files access so images, PDFs, videos, and other files can be listed.',
            style: TextStyle(
              fontSize: Responsive.sp(12),
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              FilledButton(
                onPressed: () async {
                  await openAppSettings();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandIndigo,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                child: const Text('Open Settings'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: controller.loadRoot,
                child: const Text('Retry'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlatformInfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
            size: 24,
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
                  Platform.isAndroid
                      ? 'Browse Internal Storage folders to send any file type (images, PDF, video, and more).'
                      : Platform.isIOS
                          ? 'Browse On My iPhone folders to send any file type (images, PDF, video, and more).'
                          : Platform.isMacOS
                              ? 'Browsing your Mac folders and files directly from the system.'
                              : Platform.isWindows
                                  ? 'Browsing your PC folders and files directly from the system.'
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
    );
  }
}

class _ChooseMoreFilesButton extends StatelessWidget {
  const _ChooseMoreFilesButton({required this.controller});

  final SendFilesController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: controller.isPicking.value ? null : controller.pickFilesFromDevice,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandIndigo,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: controller.isPicking.value
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.folder_open_rounded, color: Colors.white),
          label: const Text(
            'Choose More Files',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    });
  }
}

class _ImportFolderButton extends StatelessWidget {
  const _ImportFolderButton({required this.controller});

  final SendFilesController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: controller.isPicking.value ? null : controller.pickFolderToBrowse,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.brandIndigo,
            side: const BorderSide(color: AppColors.brandIndigo),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.create_new_folder_outlined),
          label: const Text(
            'Import Folder from Files',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    });
  }
}

class _LocationChips extends StatelessWidget {
  const _LocationChips({required this.controller});

  final SendFilesController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: controller.systemLocations.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final location = controller.systemLocations[index];
          final isCurrent = controller.currentFolderName.value == location.name;
          return ActionChip(
            avatar: Icon(location.icon, size: 18, color: AppColors.brandIndigo),
            label: Text(location.name),
            backgroundColor: isCurrent
                ? AppColors.brandIndigo.withValues(alpha: 0.12)
                : AppColors.surface,
            side: BorderSide(
              color: isCurrent ? AppColors.brandIndigo : AppColors.border,
            ),
            onPressed: isCurrent ? null : () => controller.openSystemLocation(location),
          );
        },
      ),
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
          padding: const EdgeInsets.all(12),
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
                child: Icon(folder.icon, color: AppColors.brandIndigo, size: 22),
              ),
              const Spacer(),
              Text(
                folder.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: Responsive.sp(13),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileGridTile extends GetView<SendFilesController> {
  const _FileGridTile({
    super.key,
    required this.file,
    required this.onTap,
    required this.onLongPress,
  });

  final PickedFileItem file;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final isImage = LocalFileBrowserService.isImage(file);
    final isVideo = LocalFileBrowserService.isVideo(file);
    final path = file.path;
    final isAsset = IosMediaPaths.isAssetRef(path);
    final assetId = path == null ? null : IosMediaPaths.assetIdFromPath(path);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: isAsset && assetId != null
                          ? _AssetThumbnail(assetId: assetId, showVideoBadge: isVideo)
                          : isImage && path != null && path.isNotEmpty
                              ? _LazyImageThumbnail(path: path)
                              : Container(
                                  color: AppColors.brandIndigo.withValues(alpha: 0.08),
                                  child: Icon(
                                    LocalFileBrowserService.iconFor(file),
                                    color: AppColors.brandIndigo,
                                    size: 30,
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
                            fontSize: Responsive.sp(12),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (file.size != null)
                          Text(
                            file.sizeLabel,
                            style: TextStyle(
                              fontSize: Responsive.sp(11),
                              color: AppColors.textSecondary,
                            ),
                          )
                        else if (isVideo)
                          Text(
                            'Video',
                            style: TextStyle(
                              fontSize: Responsive.sp(11),
                              color: AppColors.textSecondary,
                            ),
                          )
                        else if (isImage || isAsset)
                          Text(
                            'Image',
                            style: TextStyle(
                              fontSize: Responsive.sp(11),
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: Obx(() {
                final isSelected = controller.isSelected(file);
                return IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.brandIndigo : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                );
              }),
            ),
            Obx(() {
              if (!controller.isSelected(file)) return const SizedBox.shrink();
              return const Positioned(
                top: 6,
                right: 6,
                child: _SelectedBadge(),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SelectedBadge extends StatelessWidget {
  const _SelectedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: AppColors.brandIndigo,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
    );
  }
}

/// Decodes a small thumbnail without blocking taps on other tiles.
class _LazyImageThumbnail extends StatelessWidget {
  const _LazyImageThumbnail({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      cacheWidth: 120,
      cacheHeight: 120,
      filterQuality: FilterQuality.low,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return ColoredBox(
          color: AppColors.brandIndigo.withValues(alpha: 0.08),
          child: const Center(
            child: Icon(Icons.image_rounded, color: AppColors.brandIndigo, size: 28),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => ColoredBox(
        color: AppColors.brandIndigo.withValues(alpha: 0.08),
        child: const Center(
          child: Icon(Icons.broken_image_outlined, color: AppColors.brandIndigo, size: 28),
        ),
      ),
    );
  }
}

class _AssetThumbnail extends StatelessWidget {
  const _AssetThumbnail({
    required this.assetId,
    this.showVideoBadge = false,
  });

  final String assetId;
  final bool showVideoBadge;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AssetEntity?>(
      future: AssetEntity.fromId(assetId),
      builder: (context, snapshot) {
        final entity = snapshot.data;
        if (entity == null) {
          return ColoredBox(
            color: AppColors.brandIndigo.withValues(alpha: 0.08),
            child: const Center(
              child: Icon(Icons.image_rounded, color: AppColors.brandIndigo, size: 28),
            ),
          );
        }

        return FutureBuilder(
          future: entity.thumbnailDataWithSize(const ThumbnailSize.square(200)),
          builder: (context, thumbSnap) {
            final bytes = thumbSnap.data;
            return Stack(
              fit: StackFit.expand,
              children: [
                if (bytes != null)
                  Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.low,
                  )
                else
                  ColoredBox(
                    color: AppColors.brandIndigo.withValues(alpha: 0.08),
                    child: const Center(
                      child: Icon(Icons.image_rounded, color: AppColors.brandIndigo, size: 28),
                    ),
                  ),
                if (showVideoBadge)
                  const Positioned(
                    left: 6,
                    bottom: 6,
                    child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 22),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.selectedCount,
    required this.hasSelection,
    required this.isPicking,
    required this.browseLabel,
    required this.onBrowse,
    required this.onContinue,
  });

  final int selectedCount;
  final bool hasSelection;
  final bool isPicking;
  final String browseLabel;
  final VoidCallback onBrowse;
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
                onPressed: isPicking ? null : onBrowse,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandIndigo,
                  side: const BorderSide(color: AppColors.brandIndigo),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  browseLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
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
