import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../dashboard/model/picked_file_item.dart';

class LocalFileFolder {
  const LocalFileFolder({
    required this.name,
    required this.path,
    required this.icon,
  });

  final String name;
  final String path;
  final IconData icon;
}

class LocalBrowseResult {
  const LocalBrowseResult({
    required this.folders,
    required this.files,
  });

  final List<LocalFileFolder> folders;
  final List<PickedFileItem> files;
}

class LocalFileBrowserService {
  LocalFileBrowserService._();

  static const _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'heic',
    'heif',
    'bmp',
    'svg',
    'tif',
    'tiff',
  };
  static const _videoExtensions = {
    'mp4',
    'mov',
    'avi',
    'mkv',
    'm4v',
    'webm',
    '3gp',
    'wmv',
    'flv',
  };
  static const _audioExtensions = {
    'mp3',
    'wav',
    'aac',
    'm4a',
    'flac',
    'ogg',
    'wma',
  };
  static const _docExtensions = {
    'pdf',
    'doc',
    'docx',
    'txt',
    'rtf',
    'xls',
    'xlsx',
    'csv',
    'ppt',
    'pptx',
    'json',
    'xml',
    'html',
    'md',
  };

  static String get platformLabel {
    if (Platform.isAndroid) return 'Android File Manager';
    if (Platform.isIOS) return 'Files on iPhone';
    if (Platform.isMacOS) return 'Finder';
    if (Platform.isWindows) return 'File Explorer';
    if (Platform.isLinux) return 'Files';
    return 'File Manager';
  }

  /// Resolves the real user home (not the macOS app-sandbox container).
  static String? realUserHomePath() {
    if (Platform.isMacOS) {
      final user = Platform.environment['USER'];
      if (user != null && user.isNotEmpty) {
        final userHome = '/Users/$user';
        if (Directory(userHome).existsSync()) return userHome;
      }
    }

    if (Platform.isWindows) {
      return Platform.environment['USERPROFILE'];
    }

    if (Platform.isLinux) {
      return Platform.environment['HOME'];
    }

    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty && !isAppSandboxPath(home)) {
      return home;
    }

    return null;
  }

  static bool isAppSandboxPath(String path) {
    return path.contains('${Platform.pathSeparator}Containers${Platform.pathSeparator}') ||
        path.contains('${Platform.pathSeparator}.app${Platform.pathSeparator}');
  }

  /// Default folder opened when the browser loads (user home / primary storage).
  static Future<String?> defaultBrowsePath() async {
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      return realUserHomePath();
    }
    if (Platform.isAndroid) {
      const primary = '/storage/emulated/0';
      if (Directory(primary).existsSync()) return primary;
      final external = await getExternalStorageDirectory();
      return external?.path;
    }
    if (Platform.isIOS) {
      return (await getApplicationDocumentsDirectory()).path;
    }
    return (await getApplicationDocumentsDirectory()).path;
  }

  /// Dynamically discovers storage locations on this device (volumes, drives, etc.).
  static Future<List<LocalFileFolder>> discoverSystemLocations() async {
    if (Platform.isMacOS) return _discoverMacLocations();
    if (Platform.isWindows) return _discoverWindowsDrives();
    if (Platform.isLinux) return _discoverLinuxLocations();
    if (Platform.isAndroid) return _discoverAndroidStorage();
    if (Platform.isIOS) return _discoverIosSandbox();
    return _discoverFallbackLocations();
  }

  static Future<List<LocalFileFolder>> _discoverMacLocations() async {
    final locations = <LocalFileFolder>[];
    final seen = <String>{};

    void addLocation(String path, String name, IconData icon) {
      if (seen.contains(path)) return;
      if (isAppSandboxPath(path)) return;
      final dir = Directory(path);
      if (!dir.existsSync()) return;
      seen.add(path);
      locations.add(LocalFileFolder(name: name, path: path, icon: icon));
    }

    final home = realUserHomePath();
    if (home != null && home.isNotEmpty) {
      addLocation(home, _userLabelFromPath(home), Icons.home_rounded);
    }

    try {
      for (final entry in Directory('/Volumes').listSync(followLinks: false)) {
        if (entry is! Directory) continue;
        final name = entry.path.split('/').last;
        if (name.startsWith('.')) continue;
        addLocation(entry.path, name, Icons.storage_rounded);
      }
    } catch (_) {}

    return locations;
  }

  static Future<List<LocalFileFolder>> _discoverWindowsDrives() async {
    final drives = <LocalFileFolder>[];

    for (var code = 65; code <= 90; code++) {
      final letter = String.fromCharCode(code);
      final path = '$letter:\\';
      if (Directory(path).existsSync()) {
        drives.add(
          LocalFileFolder(
            name: '$letter:',
            path: path,
            icon: Icons.storage_rounded,
          ),
        );
      }
    }

    final profile = Platform.environment['USERPROFILE'];
    if (profile != null &&
        profile.isNotEmpty &&
        !drives.any((d) => profile.startsWith(d.path))) {
      drives.insert(
        0,
        LocalFileFolder(
          name: _userLabelFromPath(profile),
          path: profile,
          icon: Icons.home_rounded,
        ),
      );
    }

    return drives;
  }

  static Future<List<LocalFileFolder>> _discoverLinuxLocations() async {
    final locations = <LocalFileFolder>[];
    final seen = <String>{};

    void addLocation(String path, String name, IconData icon) {
      if (seen.contains(path)) return;
      if (!Directory(path).existsSync()) return;
      seen.add(path);
      locations.add(LocalFileFolder(name: name, path: path, icon: icon));
    }

    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      addLocation(home, _userLabelFromPath(home), Icons.home_rounded);
    }

    for (final root in ['/media', '/mnt']) {
      try {
        for (final entry in Directory(root).listSync(followLinks: false)) {
          if (entry is Directory) {
            final name = entry.path.split(Platform.pathSeparator).last;
            if (!name.startsWith('.')) {
              addLocation(entry.path, name, Icons.usb_rounded);
            }
          }
        }
      } catch (_) {}
    }

    return locations;
  }

  static Future<List<LocalFileFolder>> _discoverAndroidStorage() async {
    final locations = <LocalFileFolder>[];
    final seen = <String>{};

    void add(String path, String name, IconData icon) {
      if (seen.contains(path)) return;
      final dir = Directory(path);
      if (!dir.existsSync()) return;
      seen.add(path);
      locations.add(LocalFileFolder(name: name, path: path, icon: icon));
    }

    const primary = '/storage/emulated/0';
    add(primary, 'Internal Storage', Icons.sd_storage_rounded);
    add('$primary/Download', 'Downloads', Icons.download_rounded);
    add('$primary/DCIM', 'Camera', Icons.photo_camera_rounded);
    add('$primary/Pictures', 'Pictures', Icons.image_outlined);
    add('$primary/Documents', 'Documents', Icons.description_outlined);
    add('$primary/Movies', 'Movies', Icons.movie_outlined);
    add('$primary/Music', 'Music', Icons.music_note_rounded);

    // Removable / secondary volumes (skip "emulated" / "self").
    try {
      final storageRoot = Directory('/storage');
      if (storageRoot.existsSync()) {
        for (final entry in storageRoot.listSync(followLinks: false)) {
          if (entry is! Directory) continue;
          final name = entry.path.split(Platform.pathSeparator).last;
          if (name.startsWith('.') ||
              name == 'emulated' ||
              name == 'self' ||
              name == 'sdcard0') {
            continue;
          }
          add(entry.path, name, Icons.usb_rounded);
        }
      }
    } catch (_) {}

    return locations;
  }

  static Future<List<LocalFileFolder>> _discoverIosSandbox() async {
    final locations = <LocalFileFolder>[];
    final seen = <String>{};

    Future<void> addDir(Future<Directory> dirFuture, String label, IconData icon) async {
      try {
        final dir = await dirFuture;
        if (seen.add(dir.path)) {
          locations.add(LocalFileFolder(name: label, path: dir.path, icon: icon));
        }
      } catch (_) {}
    }

    await addDir(getApplicationDocumentsDirectory(), 'Documents', Icons.description_outlined);
    await addDir(getLibraryDirectory(), 'Library', Icons.folder_rounded);
    await addDir(getTemporaryDirectory(), 'Temporary', Icons.schedule_rounded);

    final downloads = await getDownloadsDirectory();
    if (downloads != null && seen.add(downloads.path)) {
      locations.add(
        LocalFileFolder(
          name: 'Downloads',
          path: downloads.path,
          icon: Icons.download_rounded,
        ),
      );
    }

    return locations;
  }

  static Future<List<LocalFileFolder>> _discoverFallbackLocations() async {
    final docs = await getApplicationDocumentsDirectory();
    return [
      LocalFileFolder(
        name: displayNameForPath(docs.path),
        path: docs.path,
        icon: Icons.folder_rounded,
      ),
    ];
  }

  static String displayNameForPath(String path) {
    final normalized = path.replaceAll(RegExp(r'[\\/]+$'), '');
    if (normalized.isEmpty) return path;

    final home = realUserHomePath() ??
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'];
    if (home != null && normalized == home.replaceAll(RegExp(r'[\\/]+$'), '')) {
      return _userLabelFromPath(normalized);
    }

    if (Platform.isWindows && RegExp(r'^[A-Za-z]:$').hasMatch(normalized)) {
      return normalized.toUpperCase();
    }

    return normalized.split(Platform.pathSeparator).last;
  }

  static String _userLabelFromPath(String path) {
    final segment = path.split(Platform.pathSeparator).where((s) => s.isNotEmpty).lastOrNull;
    return segment ?? 'Home';
  }

  static IconData iconForFolderName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('download')) return Icons.download_rounded;
    if (lower.contains('document')) return Icons.description_outlined;
    if (lower.contains('desktop')) return Icons.desktop_mac_rounded;
    if (lower.contains('picture') || lower.contains('photo')) return Icons.image_outlined;
    if (lower.contains('movie') || lower.contains('video')) return Icons.movie_outlined;
    if (lower.contains('music')) return Icons.music_note_rounded;
    return Icons.folder_rounded;
  }

  static Future<LocalBrowseResult> explore(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      return const LocalBrowseResult(folders: [], files: []);
    }

    final folders = <LocalFileFolder>[];
    final files = <PickedFileItem>[];

    List<FileSystemEntity> entries;
    try {
      entries = await dir.list(followLinks: false).toList();
    } catch (_) {
      return const LocalBrowseResult(folders: [], files: []);
    }

    entries.sort((a, b) {
      final aIsDir = a is Directory;
      final bIsDir = b is Directory;
      if (aIsDir != bIsDir) return aIsDir ? -1 : 1;
      return a.path.toLowerCase().compareTo(b.path.toLowerCase());
    });

    for (final entry in entries) {
      final name = entry.path.split(Platform.pathSeparator).last;
      if (name.startsWith('.')) continue;

      try {
        if (entry is Directory) {
          if (isAppSandboxPath(entry.path)) continue;
          folders.add(
            LocalFileFolder(
              name: name,
              path: entry.path,
              icon: iconForFolderName(name),
            ),
          );
          continue;
        }

        if (entry is File) {
          files.add(_fileFromPath(entry));
        }
      } catch (_) {
        // Skip inaccessible entries without wiping the whole listing.
      }
    }

    return LocalBrowseResult(folders: folders, files: files);
  }

  /// Fast metadata for grid listing — avoids blocking sync stat calls per file.
  static PickedFileItem _fileFromPath(File file) {
    final name = file.path.split(Platform.pathSeparator).last;
    final dot = name.lastIndexOf('.');
    final ext = dot == -1 ? null : name.substring(dot + 1).toLowerCase();

    return PickedFileItem(
      name: name,
      path: file.path,
      size: null,
      extension: ext,
      addedAt: DateTime.now(),
    );
  }

  static bool isImage(PickedFileItem file) =>
      _imageExtensions.contains(file.extension?.toLowerCase());

  static bool isVideo(PickedFileItem file) =>
      _videoExtensions.contains(file.extension?.toLowerCase());

  static IconData iconFor(PickedFileItem file) {
    final ext = file.extension?.toLowerCase();
    if (_imageExtensions.contains(ext)) return Icons.image_rounded;
    if (_videoExtensions.contains(ext)) return Icons.videocam_rounded;
    if (_audioExtensions.contains(ext)) return Icons.audiotrack_rounded;
    if (_docExtensions.contains(ext)) return Icons.description_rounded;
    if (ext == 'zip' || ext == 'rar' || ext == '7z') return Icons.folder_zip_rounded;
    if (ext == 'apk') return Icons.android_rounded;
    return Icons.insert_drive_file_rounded;
  }
}
