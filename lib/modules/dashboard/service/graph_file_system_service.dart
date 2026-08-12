import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../../transfer/service/android_storage_permission.dart';
import '../../transfer/service/local_file_browser_service.dart';
import '../model/file_graph_node.dart';

class GraphFileSystemService {
  Future<void> initialize() async {
    if (Platform.isAndroid) {
      await AndroidStoragePermission.ensure();
    }
  }

  Future<List<FileGraphNode>> getRoots() async {
    final path = await LocalFileBrowserService.defaultBrowsePath();
    if (path == null) return [];

    return [
      FileGraphNode(
        id: path,
        name: LocalFileBrowserService.displayNameForPath(path),
        type: GraphNodeType.folder,
        path: path,
      ),
    ];
  }

  Future<FileGraphNode?> pickAndGrantRoot() async {
    final path = await FilePicker.getDirectoryPath();
    if (path == null) return null;

    return FileGraphNode(
      id: path,
      name: LocalFileBrowserService.displayNameForPath(path),
      type: GraphNodeType.folder,
      path: path,
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
