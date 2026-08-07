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

  static const _imageExtensions = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'bmp'};
  static const _videoExtensions = {'mp4', 'mov', 'avi', 'mkv', 'm4v'};
  static const _docExtensions = {'pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx'};

  static String get platformLabel {
    if (Platform.isAndroid) return 'Android File Manager';
    if (Platform.isIOS) return 'Files on iPhone';
    if (Platform.isMacOS) return 'Finder';
    if (Platform.isWindows) return 'File Explorer';
    return 'File Manager';
  }

  static Future<List<LocalFileFolder>> getRootFolders() async {
    if (Platform.isAndroid) return _androidRoots();
    if (Platform.isIOS) return _iosRoots();
    if (Platform.isMacOS) return _macosRoots();
    if (Platform.isWindows) return _windowsRoots();
    return _fallbackRoots();
  }

  static Future<List<LocalFileFolder>> _androidRoots() async {
    const base = '/storage/emulated/0';
    final folders = _foldersFromPaths([
      ('Internal Storage', base, Icons.sd_storage_rounded),
      ('Downloads', '$base/Download', Icons.download_rounded),
      ('DCIM', '$base/DCIM', Icons.photo_camera_rounded),
      ('Pictures', '$base/Pictures', Icons.image_outlined),
      ('Documents', '$base/Documents', Icons.description_outlined),
      ('Movies', '$base/Movies', Icons.movie_outlined),
      ('Music', '$base/Music', Icons.music_note_rounded),
    ]);

    final appDocs = await getApplicationDocumentsDirectory();
    folders.add(
      LocalFileFolder(
        name: 'App Documents',
        path: appDocs.path,
        icon: Icons.folder_special_rounded,
      ),
    );

    return folders;
  }

  static Future<List<LocalFileFolder>> _iosRoots() async {
    final docs = await getApplicationDocumentsDirectory();
    final library = await getLibraryDirectory();
    final downloads = await getDownloadsDirectory();
    final tmp = await getTemporaryDirectory();

    final folders = <LocalFileFolder>[
      LocalFileFolder(
        name: 'On My iPhone',
        path: docs.path,
        icon: Icons.phone_iphone_rounded,
      ),
      LocalFileFolder(
        name: 'Library',
        path: library.path,
        icon: Icons.folder_rounded,
      ),
      LocalFileFolder(
        name: 'Temporary',
        path: tmp.path,
        icon: Icons.schedule_rounded,
      ),
    ];

    if (downloads != null) {
      folders.add(
        LocalFileFolder(
          name: 'Downloads',
          path: downloads.path,
          icon: Icons.download_rounded,
        ),
      );
    }

    return folders;
  }

  /// Scans accessible directories and returns files sorted by modified date.
  static Future<List<PickedFileItem>> loadRecentFiles({int limit = 60}) async {
    final roots = <String>[];

    try {
      if (Platform.isAndroid) {
        roots.addAll([
          '/storage/emulated/0/Download',
          '/storage/emulated/0/DCIM',
          '/storage/emulated/0/Pictures',
          '/storage/emulated/0/Documents',
        ]);
        final docs = await getApplicationDocumentsDirectory();
        roots.add(docs.path);
      } else if (Platform.isIOS) {
        final docs = await getApplicationDocumentsDirectory();
        final library = await getLibraryDirectory();
        final downloads = await getDownloadsDirectory();
        roots.addAll([docs.path, library.path, if (downloads != null) downloads.path]);
      } else if (Platform.isMacOS) {
        final home = Platform.environment['HOME'] ?? '';
        if (home.isNotEmpty) {
          roots.addAll([
            '$home/Downloads',
            '$home/Documents',
            '$home/Desktop',
            '$home/Pictures',
          ]);
        }
      } else if (Platform.isWindows) {
        final user = Platform.environment['USERPROFILE'] ?? '';
        if (user.isNotEmpty) {
          roots.addAll([
            '$user\\Downloads',
            '$user\\Documents',
            '$user\\Desktop',
            '$user\\Pictures',
          ]);
        }
      } else {
        final docs = await getApplicationDocumentsDirectory();
        roots.add(docs.path);
      }
    } catch (_) {
      return [];
    }

    final collected = <String, PickedFileItem>{};
    for (final root in roots) {
      final dir = Directory(root);
      if (!dir.existsSync()) continue;
      for (final file in _scanFiles(dir, maxDepth: 4)) {
        collected[file.path ?? file.name] = file;
      }
    }

    final sorted = collected.values.toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));

    return sorted.take(limit).toList();
  }

  static List<PickedFileItem> _scanFiles(Directory dir, {required int maxDepth}) {
    if (maxDepth <= 0) return [];

    final files = <PickedFileItem>[];
    try {
      for (final entry in dir.listSync(followLinks: false)) {
        if (entry is File) {
          final name = entry.path.split(Platform.pathSeparator).last;
          if (!name.startsWith('.')) {
            files.add(_fileFromPath(entry));
          }
        } else if (entry is Directory) {
          final name = entry.path.split(Platform.pathSeparator).last;
          if (!name.startsWith('.')) {
            files.addAll(_scanFiles(entry, maxDepth: maxDepth - 1));
          }
        }
      }
    } catch (_) {
      return files;
    }
    return files;
  }

  static List<LocalFileFolder> _macosRoots() {
    final home = Platform.environment['HOME'] ?? '';
    if (home.isEmpty) return [];

    return _foldersFromPaths([
      ('Macintosh HD', home, Icons.laptop_mac_rounded),
      ('Documents', '$home/Documents', Icons.description_outlined),
      ('Downloads', '$home/Downloads', Icons.download_rounded),
      ('Desktop', '$home/Desktop', Icons.desktop_mac_rounded),
      ('Pictures', '$home/Pictures', Icons.image_outlined),
      ('Movies', '$home/Movies', Icons.movie_outlined),
      ('Music', '$home/Music', Icons.music_note_rounded),
    ]);
  }

  static List<LocalFileFolder> _windowsRoots() {
    final user = Platform.environment['USERPROFILE'] ?? '';
    if (user.isEmpty) return [];

    return _foldersFromPaths([
      ('This PC', user, Icons.computer_rounded),
      ('Documents', '$user\\Documents', Icons.description_outlined),
      ('Downloads', '$user\\Downloads', Icons.download_rounded),
      ('Desktop', '$user\\Desktop', Icons.desktop_windows_rounded),
      ('Pictures', '$user\\Pictures', Icons.image_outlined),
      ('Videos', '$user\\Videos', Icons.movie_outlined),
      ('Music', '$user\\Music', Icons.music_note_rounded),
    ]);
  }

  static Future<List<LocalFileFolder>> _fallbackRoots() async {
    final docs = await getApplicationDocumentsDirectory();
    final downloads = await getDownloadsDirectory();

    final folders = <LocalFileFolder>[
      LocalFileFolder(
        name: 'Documents',
        path: docs.path,
        icon: Icons.description_outlined,
      ),
    ];

    if (downloads != null) {
      folders.add(
        LocalFileFolder(
          name: 'Downloads',
          path: downloads.path,
          icon: Icons.download_rounded,
        ),
      );
    }

    return folders;
  }

  static List<LocalFileFolder> _foldersFromPaths(
    List<(String, String, IconData)> entries,
  ) {
    final folders = <LocalFileFolder>[];
    final seen = <String>{};

    for (final entry in entries) {
      final path = entry.$2;
      if (seen.contains(path)) continue;
      final dir = Directory(path);
      if (!dir.existsSync()) continue;
      seen.add(path);
      folders.add(LocalFileFolder(name: entry.$1, path: path, icon: entry.$3));
    }

    return folders;
  }

  static Future<LocalBrowseResult> explore(String path) async {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      return const LocalBrowseResult(folders: [], files: []);
    }

    final folders = <LocalFileFolder>[];
    final files = <PickedFileItem>[];

    try {
      final entries = dir.listSync(followLinks: false)
        ..sort((a, b) {
          final aIsDir = a is Directory;
          final bIsDir = b is Directory;
          if (aIsDir != bIsDir) return aIsDir ? -1 : 1;
          return a.path.toLowerCase().compareTo(b.path.toLowerCase());
        });

      for (final entry in entries) {
        final name = entry.path.split(Platform.pathSeparator).last;
        if (name.startsWith('.')) continue;

        if (entry is Directory) {
          folders.add(
            LocalFileFolder(
              name: name,
              path: entry.path,
              icon: Icons.folder_rounded,
            ),
          );
        } else if (entry is File) {
          files.add(_fileFromPath(entry));
        }
      }
    } catch (_) {
      return const LocalBrowseResult(folders: [], files: []);
    }

    return LocalBrowseResult(folders: folders, files: files);
  }

  static PickedFileItem _fileFromPath(File file) {
    final name = file.path.split(Platform.pathSeparator).last;
    final dot = name.lastIndexOf('.');
    final ext = dot == -1 ? null : name.substring(dot + 1).toLowerCase();

    return PickedFileItem(
      name: name,
      path: file.path,
      size: file.lengthSync(),
      extension: ext,
      addedAt: DateTime.fromMillisecondsSinceEpoch(
        file.lastModifiedSync().millisecondsSinceEpoch,
      ),
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
    if (_docExtensions.contains(ext)) return Icons.description_rounded;
    if (ext == 'zip' || ext == 'rar') return Icons.folder_zip_rounded;
    return Icons.insert_drive_file_rounded;
  }
}
