import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

import '../../transfer/service/android_storage_permission.dart';
import '../../transfer/service/ios_folder_picker.dart';
import '../../transfer/service/local_file_browser_service.dart';
import '../model/file_graph_node.dart';

class FileMapFileSystemService {
  static const _storageChannel = MethodChannel('flow_drive/device_storage');

  Future<void> initialize() async {
    if (Platform.isAndroid) {
      await AndroidStoragePermission.ensure();
    }
  }

  /// No auto-root — every platform starts with "Choose folder" so the user
  /// picks what to map (Android / iOS / Windows / macOS).
  Future<List<FileGraphNode>> getRoots() async => [];

  Future<FileGraphNode?> pickAndGrantRoot() async {
    if (Platform.isIOS) {
      return _pickIosFolder();
    }

    if (Platform.isAndroid) {
      await AndroidStoragePermission.ensure();
    }

    final path = await FilePicker.getDirectoryPath(
      dialogTitle: 'Choose folder to map',
    );
    if (path == null) return null;

    return FileGraphNode(
      id: path,
      name: LocalFileBrowserService.displayNameForPath(path),
      type: GraphNodeType.folder,
      path: path,
    );
  }

  /// Open [path] in the system file manager or default app (Finder / Explorer / Files).
  /// Works for files and folders. Does not change the File Map.
  Future<void> revealInSystemFileManager(String path) async {
    final entity = FileSystemEntity.typeSync(path);
    if (entity == FileSystemEntityType.notFound) {
      throw Exception('That path is no longer available on disk.');
    }

    if (Platform.isMacOS) {
      final result = await Process.run('open', [path]);
      if (result.exitCode != 0) {
        throw Exception(
          (result.stderr.toString().trim().isNotEmpty)
              ? result.stderr.toString().trim()
              : 'Could not open that path in Finder.',
        );
      }
      return;
    }

    if (Platform.isWindows) {
      final dir = Directory(path);
      if (await dir.exists()) {
        await Process.run('explorer', [path]);
      } else {
        await Process.run('explorer', ['/select,', path]);
      }
      return;
    }

    if (Platform.isLinux) {
      final result = await Process.run('xdg-open', [path]);
      if (result.exitCode != 0) {
        throw Exception(
          (result.stderr.toString().trim().isNotEmpty)
              ? result.stderr.toString().trim()
              : 'Could not open that path in the file manager.',
        );
      }
      return;
    }

    // iPhone / Android — native Files / Documents UI.
    if (Platform.isAndroid) {
      await AndroidStoragePermission.ensure();
    }

    try {
      await _storageChannel.invokeMethod<void>('revealPath', {'path': path});
    } on MissingPluginException {
      throw Exception(
        'Path reveal is not ready. Fully stop the app and run again (not hot reload).',
      );
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Could not open that path in Files.');
    }
  }

  Future<FileGraphNode?> _pickIosFolder() async {
    final picked = await IosFolderPicker.pickFolder();
    if (picked == null) return null;
    return FileGraphNode(
      id: picked.path,
      name: picked.name,
      type: GraphNodeType.folder,
      path: picked.path,
    );
  }

  Future<List<FileGraphNode>> listChildren(String folderId) async {
    final result = await LocalFileBrowserService.explore(folderId);
    final nodes = <FileGraphNode>[];

    for (final folder in result.folders) {
      nodes.add(
        FileGraphNode(
          id: folder.path,
          name: folder.name,
          type: GraphNodeType.folder,
          path: folder.path,
        ),
      );
    }

    for (final file in result.files) {
      final path = file.path;
      if (path == null || path.isEmpty) continue;
      nodes.add(
        FileGraphNode(
          id: path,
          name: file.name,
          type: GraphNodeType.file,
          path: path,
        ),
      );
    }

    return nodes;
  }
}
