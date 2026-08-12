import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../dashboard/model/picked_file_item.dart';
import 'local_browse_models.dart';

/// Virtual browse paths for iPhone media (Photos / Videos) shown like Android folders.
class IosMediaPaths {
  IosMediaPaths._();

  static const root = 'flowdrive://ios/root';
  static const photos = 'flowdrive://ios/photos';
  static const videos = 'flowdrive://ios/videos';

  static bool isVirtual(String path) => path.startsWith('flowdrive://ios/');

  static bool isAssetRef(String? path) =>
      path != null && path.startsWith('asset://');

  static String? assetIdFromPath(String path) {
    if (!path.startsWith('asset://')) return null;
    return path.substring('asset://'.length);
  }
}

/// Lists camera-roll images/videos so Send Files can show real media on iOS.
class IosMediaBrowserService {
  IosMediaBrowserService._();

  static const _maxPhotos = 400;
  static const _maxVideos = 200;
  static const _maxRecents = 80;

  static Future<bool> ensurePermission() async {
    final state = await PhotoManager.requestPermissionExtend();
    if (state == PermissionState.authorized || state == PermissionState.limited) {
      return true;
    }
    return false;
  }

  static Future<LocalBrowseResult> explore(String path) async {
    if (path == IosMediaPaths.root) {
      return _exploreRoot();
    }
    if (path == IosMediaPaths.photos) {
      final ok = await ensurePermission();
      if (!ok) return const LocalBrowseResult(folders: [], files: []);
      final files = await _listAssets(RequestType.image, _maxPhotos);
      return LocalBrowseResult(folders: const [], files: files);
    }
    if (path == IosMediaPaths.videos) {
      final ok = await ensurePermission();
      if (!ok) return const LocalBrowseResult(folders: [], files: []);
      final files = await _listAssets(RequestType.video, _maxVideos);
      return LocalBrowseResult(folders: const [], files: files);
    }
    return const LocalBrowseResult(folders: [], files: []);
  }

  static Future<LocalBrowseResult> _exploreRoot() async {
    final folders = <LocalFileFolder>[
      const LocalFileFolder(
        name: 'Photos',
        path: IosMediaPaths.photos,
        icon: Icons.photo_library_rounded,
      ),
      const LocalFileFolder(
        name: 'Videos',
        path: IosMediaPaths.videos,
        icon: Icons.movie_outlined,
      ),
    ];

    try {
      final docs = await getApplicationDocumentsDirectory();
      folders.add(
        LocalFileFolder(
          name: 'Documents',
          path: docs.path,
          icon: Icons.description_outlined,
        ),
      );
    } catch (_) {}

    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) {
        folders.add(
          LocalFileFolder(
            name: 'Downloads',
            path: downloads.path,
            icon: Icons.download_rounded,
          ),
        );
      }
    } catch (_) {}

    // Previously imported Files-app folders (PDFs, etc.).
    try {
      final docs = await getApplicationDocumentsDirectory();
      final graphMap = Directory('${docs.parent.path}/Library/Caches/GraphMap');
      if (await graphMap.exists()) {
        for (final uuidDir in graphMap.listSync(followLinks: false).whereType<Directory>()) {
          for (final folder in uuidDir.listSync(followLinks: false).whereType<Directory>()) {
            final name = folder.path.split(Platform.pathSeparator).last;
            folders.add(
              LocalFileFolder(
                name: name,
                path: folder.path,
                icon: Icons.folder_shared_rounded,
              ),
            );
          }
        }
      }
    } catch (_) {}

    // Show recent photos/videos immediately in the Files grid (like Android root files).
    var files = <PickedFileItem>[];
    if (await ensurePermission()) {
      files = await _listAssets(RequestType.common, _maxRecents);
    }

    return LocalBrowseResult(folders: folders, files: files);
  }

  static Future<List<PickedFileItem>> _listAssets(RequestType type, int limit) async {
    try {
      final albums = await PhotoManager.getAssetPathList(
        type: type,
        onlyAll: true,
      );
      if (albums.isEmpty) return [];

      final album = albums.first;
      final total = await album.assetCountAsync;
      if (total <= 0) return [];

      final end = math.min(limit, total);
      final assets = await album.getAssetListRange(start: 0, end: end);
      final items = <PickedFileItem>[];

      for (final asset in assets) {
        final ext = _extensionFor(asset);
        final title = (asset.title != null && asset.title!.trim().isNotEmpty)
            ? asset.title!.trim()
            : '${asset.type == AssetType.video ? 'VID' : 'IMG'}_${asset.id}.$ext';

        items.add(
          PickedFileItem(
            name: title.contains('.') ? title : '$title.$ext',
            path: 'asset://${asset.id}',
            size: null,
            extension: ext,
            addedAt: asset.createDateTime,
          ),
        );
      }
      return items;
    } catch (_) {
      return [];
    }
  }

  static String _extensionFor(AssetEntity asset) {
    final title = asset.title;
    if (title != null) {
      final dot = title.lastIndexOf('.');
      if (dot != -1 && dot < title.length - 1) {
        return title.substring(dot + 1).toLowerCase();
      }
    }
    switch (asset.type) {
      case AssetType.video:
        return 'mp4';
      case AssetType.audio:
        return 'm4a';
      case AssetType.image:
      case AssetType.other:
        return 'jpg';
    }
  }

  /// Turns an `asset://` library item into a real file path for preview / send.
  static Future<PickedFileItem?> resolveIfNeeded(PickedFileItem item) async {
    final path = item.path;
    if (path == null || path.isEmpty) return item;
    if (!IosMediaPaths.isAssetRef(path)) return item;

    final id = IosMediaPaths.assetIdFromPath(path);
    if (id == null || id.isEmpty) return null;

    final entity = await AssetEntity.fromId(id);
    if (entity == null) return null;

    final file = (await entity.originFile) ?? (await entity.file);
    if (file == null) return null;

    final name = item.name;
    final ext = item.extension ?? _extensionFor(entity);
    return PickedFileItem(
      name: name,
      path: file.path,
      size: await file.length(),
      extension: ext,
      addedAt: item.addedAt,
    );
  }

  static Future<List<PickedFileItem>> resolveAll(List<PickedFileItem> items) async {
    final out = <PickedFileItem>[];
    for (final item in items) {
      final resolved = await resolveIfNeeded(item);
      if (resolved != null && resolved.path != null && resolved.path!.isNotEmpty) {
        out.add(resolved);
      }
    }
    return out;
  }
}
