import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../dashboard/model/picked_file_item.dart';
import '../../transfer/view/widgets/file_preview.dart';
import '../model/file_graph_node.dart';
import '../service/file_map_filesystem_service.dart';

class FileMapConstants {
  FileMapConstants._();

  static const maxChildren = 12;
  static const maxTotalFolders = 220;
  static const nodeRadius = 22.0;
  static const rootRadius = 24.0;
  static const levelGap = 84.0;
  static const siblingGap = 76.0;
  static const bottomMargin = 56.0;
  static const topPadding = 56.0;
}

class FileMapController extends GetxController {
  final FileMapFileSystemService fs = FileMapFileSystemService();

  final ready = false.obs;
  final error = RxnString();
  final mapping = false.obs;
  final mappedCount = 0.obs;
  final nodes = <String, GraphLayoutNode>{}.obs;
  final rootId = RxnString();
  final focusedId = RxnString();
  final statusMsg = RxnString();
  final openedItemLabel = RxnString();
  final canvasSize = const Size(360, 640).obs;

  /// Previous map roots after "Make root" — used by the root back button.
  final rootHistory = <FileGraphNode>[].obs;

  final childrenCache = <String, List<FileGraphNode>>{};
  int _folderCount = 0;
  int _seedGeneration = 0;

  bool get canStepBackRoot => rootHistory.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  Future<void> retryBootstrap() => _bootstrap();

  Future<void> _bootstrap() async {
    try {
      await fs.initialize();
      final roots = await fs.getRoots();
      if (roots.isEmpty) {
        ready.value = true;
        return;
      }
      await seedRoot(roots.first, pushHistory: false);
    } catch (e) {
      error.value = e is Exception ? e.toString() : 'Failed to load file access.';
    } finally {
      ready.value = true;
    }
  }

  Future<void> crawlTree(FileGraphNode node) async {
    if (_folderCount >= FileMapConstants.maxTotalFolders) return;
    _folderCount += 1;

    List<FileGraphNode> kids = [];
    try {
      kids = (await fs.listChildren(node.id))
          .take(FileMapConstants.maxChildren)
          .toList();
    } catch (_) {
      kids = [];
    }

    childrenCache[node.id] = kids;
    mappedCount.value += 1;

    for (final folder in kids.where((k) => k.isFolder)) {
      await crawlTree(folder);
    }
  }

  Map<String, GraphLayoutNode> buildFullTree(FileGraphNode rootNode) {
    final map = <String, GraphLayoutNode>{
      rootNode.id: GraphLayoutNode(
        node: rootNode,
        parentId: null,
        level: 0,
      ),
    };

    void visit(String id, int level) {
      final cached = childrenCache[id];
      if (cached == null) return;

      final childIds = cached.map((c) => c.id).toList();
      final existing = map[id];
      if (existing != null) {
        existing
          ..loaded = true
          ..childIds = childIds
          ..childCount = cached.length;
      }

      for (final childNode in cached) {
        map[childNode.id] = GraphLayoutNode(
          node: childNode,
          parentId: id,
          level: level + 1,
        );
        if (childNode.isFolder) visit(childNode.id, level + 1);
      }
    }

    visit(rootNode.id, 0);
    return map;
  }

  Size layoutFullTree(Map<String, GraphLayoutNode> map, String root) {
    final screen = Get.size;
    final maxLevel = map.values.fold<int>(0, (m, n) => m > n.level ? m : n.level);
    final perLevel = <int, int>{};
    for (final n in map.values) {
      perLevel[n.level] = (perLevel[n.level] ?? 0) + 1;
    }
    final widestLevel = perLevel.values.isEmpty ? 1 : perLevel.values.reduce((a, b) => a > b ? a : b);

    final canvasW = screen.width > widestLevel * FileMapConstants.siblingGap + 40
        ? screen.width
        : widestLevel * FileMapConstants.siblingGap + 40;
    final canvasH = screen.height * 0.6 >
            FileMapConstants.bottomMargin +
                maxLevel * FileMapConstants.levelGap +
                FileMapConstants.topPadding
        ? screen.height * 0.6
        : FileMapConstants.bottomMargin +
            maxLevel * FileMapConstants.levelGap +
            FileMapConstants.topPadding;

    void assign(String id, double xMin, double xMax) {
      final n = map[id];
      if (n == null) return;
      n
        ..x = (xMin + xMax) / 2
        ..y = canvasH - FileMapConstants.bottomMargin - n.level * FileMapConstants.levelGap;

      final kids = n.childIds;
      if (kids.isEmpty) return;

      final span = xMax - xMin;
      final seg = span / kids.length < FileMapConstants.siblingGap
          ? FileMapConstants.siblingGap
          : span / kids.length;
      final totalWidth = seg * kids.length;
      final start = n.x - totalWidth / 2;
      for (var i = 0; i < kids.length; i++) {
        assign(kids[i], start + i * seg, start + (i + 1) * seg);
      }
    }

    assign(root, 0, canvasW);
    return Size(canvasW, canvasH);
  }

  Future<void> seedRoot(
    FileGraphNode rootNode, {
    bool pushHistory = false,
  }) async {
    if (pushHistory) {
      final currentId = rootId.value;
      if (currentId != null) {
        final current = nodes[currentId];
        if (current != null) {
          rootHistory.add(
            FileGraphNode(
              id: current.node.id,
              name: current.node.name,
              type: current.node.type,
              path: current.node.path,
            ),
          );
        }
      }
    }

    final myGen = ++_seedGeneration;
    nodes.clear();
    rootId.value = rootNode.id;
    focusedId.value = rootNode.id;
    childrenCache.clear();
    _folderCount = 0;
    mappedCount.value = 0;
    mapping.value = true;
    statusMsg.value = null;

    await crawlTree(rootNode);
    if (_seedGeneration != myGen) return;

    final full = buildFullTree(rootNode);
    final size = layoutFullTree(full, rootNode.id);
    canvasSize.value = size;
    nodes.assignAll(full);
    mapping.value = false;
    rootHistory.refresh();

    if (_folderCount >= FileMapConstants.maxTotalFolders) {
      statusMsg.value =
          'Mapped the first ${FileMapConstants.maxTotalFolders} folders — deeper ones load on first swipe there.';
    } else if (full.length <= 1) {
      statusMsg.value = GetPlatform.isIOS
          ? 'No files found in this folder. Tap the folder+ icon and pick files from the Files app.'
          : 'No files found in this folder.';
    }
  }

  Future<void> lazyLoadFolder(String id) async {
    final target = nodes[id];
    final root = rootId.value;
    if (target == null || !target.node.isFolder || target.loaded || target.loading || root == null) {
      return;
    }

    nodes[id] = GraphLayoutNode(
      node: target.node,
      parentId: target.parentId,
      level: target.level,
      x: target.x,
      y: target.y,
      loaded: target.loaded,
      loading: true,
      childIds: target.childIds,
      childCount: target.childCount,
    );
    nodes.refresh();

    try {
      final kids = (await fs.listChildren(id)).take(FileMapConstants.maxChildren).toList();
      childrenCache[id] = kids;

      final next = Map<String, GraphLayoutNode>.from(nodes);
      final childIds = <String>[];
      for (final childNode in kids) {
        childIds.add(childNode.id);
        next[childNode.id] = GraphLayoutNode(
          node: childNode,
          parentId: id,
          level: target.level + 1,
        );
      }

      next[id] = GraphLayoutNode(
        node: target.node,
        parentId: target.parentId,
        level: target.level,
        x: target.x,
        y: target.y,
        loaded: true,
        loading: false,
        childIds: childIds,
        childCount: kids.length,
      );

      final size = layoutFullTree(next, root);
      canvasSize.value = size;
      nodes.assignAll(next);

      statusMsg.value = kids.isEmpty ? '"${target.node.name}" is empty.' : null;
    } catch (e) {
      final current = nodes[id];
      if (current != null) {
        nodes[id] = GraphLayoutNode(
          node: current.node,
          parentId: current.parentId,
          level: current.level,
          x: current.x,
          y: current.y,
          loaded: current.loaded,
          loading: false,
          childIds: current.childIds,
          childCount: current.childCount,
        );
        nodes.refresh();
      }
      statusMsg.value = e is Exception ? e.toString() : 'Could not open that folder.';
    }
  }

  void openFolder(String id) {
    final target = nodes[id];
    if (target == null || !target.node.isFolder) return;

    focusedId.value = id;
    statusMsg.value = null;

    if (!target.loaded) {
      lazyLoadFolder(id);
    } else {
      focusedId.refresh();
    }
  }

  void goBack() {
    final currentId = focusedId.value;
    if (currentId == null) return;
    final current = nodes[currentId];
    if (current?.parentId != null) openFolder(current!.parentId!);
  }

  /// Step back to the previous map root after one or more "Make root" actions.
  Future<void> stepBackRoot() async {
    if (rootHistory.isEmpty) return;
    final previous = rootHistory.removeLast();
    rootHistory.refresh();
    await seedRoot(previous, pushHistory: false);
  }

  List<({String id, String name})> breadcrumbChain() {
    final currentId = focusedId.value ?? rootId.value;
    if (currentId == null) return [];

    final parts = <({String id, String name})>[];
    GraphLayoutNode? cur = nodes[currentId];
    while (cur != null) {
      parts.insert(0, (id: cur.node.id, name: cur.node.name));
      cur = cur.parentId != null ? nodes[cur.parentId] : null;
    }
    return parts;
  }

  Future<void> grantAccess() async {
    error.value = null;
    try {
      final root = await fs.pickAndGrantRoot();
      if (root != null) {
        rootHistory.clear();
        rootHistory.refresh();
        await seedRoot(root, pushHistory: false);
      }
    } on MissingPluginException {
      error.value =
          'Folder picker is not ready. Stop the app fully and run again (full restart, not hot reload).';
    } catch (e) {
      error.value = e is Exception ? e.toString() : 'Could not grant folder access.';
    }
  }

  Future<void> makeFolderRoot(FileGraphNode folderNode) async {
    await seedRoot(folderNode, pushHistory: true);
  }

  void dismissOpenedItem() {
    openedItemLabel.value = null;
  }

  /// Just Open — reveal this path in Finder / system file manager.
  /// The File Map is left unchanged.
  Future<void> openFolderInLocalStorage(FileGraphNode folderNode) async {
    error.value = null;
    try {
      await fs.revealInSystemFileManager(folderNode.path);
      statusMsg.value = 'Opened “${folderNode.name}” in local storage.';
      openedItemLabel.value = folderNode.name;
    } catch (e) {
      Get.snackbar(
        'Cannot open folder',
        e is Exception ? e.toString() : 'Could not open that folder in Files.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Drag-release on a folder:
  /// - Just open → Finder / local storage at that path (map unchanged)
  /// - Make root → remount the map from that folder
  Future<void> offerMakeRootOrNavigate(String id, BuildContext context) async {
    final target = nodes[id];
    if (target == null || !target.node.isFolder || target.isRoot) return;

    final folderNode = FileGraphNode(
      id: target.node.id,
      name: target.node.name,
      type: target.node.type,
      path: target.node.path,
    );

    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('“${folderNode.name}”'),
          content: const Text(
            'Just open: show this folder in Files / local storage (map stays as-is).\n\n'
            'Make root: remount the File Map from this folder.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('open'),
              child: const Text('Just open'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop('root'),
              child: const Text('Make root'),
            ),
          ],
        );
      },
    );

    if (!context.mounted) return;

    if (choice == 'open') {
      await openFolderInLocalStorage(folderNode);
    } else if (choice == 'root') {
      await makeFolderRoot(folderNode);
    }
  }

  Future<void> openFile(String id, BuildContext context) async {
    final target = nodes[id];
    if (target == null || !target.node.isFile) return;

    final picked = PickedFileItem(
      name: target.node.name,
      path: target.node.path,
      size: null,
      extension: _extension(target.node.name),
      addedAt: DateTime.now(),
    );

    // Always open / preview — never send.
    if (!context.mounted) return;
    await FilePreview.show(context, picked);
  }

  /// Single-tap on a folder navigates into it. Files open via drag-release or double-tap.
  void commitSelection(String id, BuildContext context) {
    final target = nodes[id];
    if (target == null) return;

    if (target.node.isFolder) {
      openFolder(id);
    }
  }

  String? _extension(String name) {
    final dot = name.lastIndexOf('.');
    if (dot <= 0) return null;
    return name.substring(dot + 1).toLowerCase();
  }
}
