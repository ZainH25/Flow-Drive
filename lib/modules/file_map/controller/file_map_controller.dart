import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../dashboard/model/picked_file_item.dart';
import '../../transfer/view/widgets/file_preview.dart';
import '../model/file_graph_node.dart';
import '../service/file_map_filesystem_service.dart';

/// Map tab shows the full recursive tree; Voice tab reveals one folder level at a time.
enum FileMapDisplayMode { fullTree, singleLevel }

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

  final displayMode = FileMapDisplayMode.fullTree.obs;

  final childrenCache = <String, List<FileGraphNode>>{};
  final _knownNodes = <String, FileGraphNode>{};
  final _navigationStack = <String>[];

  int _folderCount = 0;
  int _seedGeneration = 0;

  bool get canStepBackRoot => rootHistory.isNotEmpty;
  bool get isSingleLevel => displayMode.value == FileMapDisplayMode.singleLevel;

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
    for (final child in kids) {
      _rememberNode(child);
    }

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
    _knownNodes.clear();
    _navigationStack.clear();
    _rememberNode(rootNode);
    _folderCount = 0;
    mappedCount.value = 0;
    mapping.value = true;
    statusMsg.value = null;

    if (displayMode.value == FileMapDisplayMode.singleLevel) {
      _navigationStack.add(rootNode.id);
      await _seedSingleLevel(rootNode.id, focusNode: rootNode);
      if (_seedGeneration != myGen) return;
      mapping.value = false;
      rootHistory.refresh();
      return;
    }

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

    if (displayMode.value == FileMapDisplayMode.singleLevel) {
      final stackIndex = _navigationStack.indexOf(id);
      if (stackIndex >= 0) {
        // Navigate back to an ancestor already on the path.
        _navigationStack.removeRange(stackIndex + 1, _navigationStack.length);
      } else {
        final parentId = target.parentId;
        final parentIndex = parentId != null ? _navigationStack.indexOf(parentId) : -1;
        if (parentIndex >= 0) {
          // Sibling switch or drill-down under a known parent — replace the tail
          // so the previous folder's projection is collapsed.
          _navigationStack.removeRange(parentIndex + 1, _navigationStack.length);
          _navigationStack.add(id);
        } else {
          _navigationStack.add(id);
        }
      }
      statusMsg.value = null;
      _seedSingleLevel(id, focusNode: target.node);
      return;
    }

    focusedId.value = id;
    statusMsg.value = null;

    if (!target.loaded) {
      lazyLoadFolder(id);
    } else {
      focusedId.refresh();
    }
  }

  void goBack() {
    if (displayMode.value == FileMapDisplayMode.singleLevel) {
      if (_navigationStack.length <= 1) return;
      _navigationStack.removeLast();
      final parentId = _navigationStack.last;
      statusMsg.value = null;
      _seedSingleLevel(parentId);
      return;
    }

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
    if (displayMode.value == FileMapDisplayMode.singleLevel && _navigationStack.isNotEmpty) {
      return _navigationStack.map((id) {
        final node = _knownNodes[id] ?? nodes[id]?.node;
        return (id: id, name: node?.name ?? '…');
      }).toList();
    }

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

  Future<void> setDisplayMode(FileMapDisplayMode mode) async {
    if (displayMode.value == mode) return;
    displayMode.value = mode;

    final root = rootId.value;
    if (root == null) return;

    if (mode == FileMapDisplayMode.singleLevel) {
      final focus = focusedId.value ?? root;
      _navigationStack
        ..clear()
        ..addAll(_pathFromRootTo(focus));
      if (_navigationStack.isEmpty) {
        _navigationStack.add(focus);
      }
      await _seedSingleLevel(_navigationStack.last);
      return;
    }

    _navigationStack.clear();
    final rootNode = _knownNodes[root] ?? nodes[root]?.node;
    if (rootNode != null) {
      await seedRoot(rootNode, pushHistory: false);
    }
  }

  void _rememberNode(FileGraphNode node) {
    _knownNodes[node.id] = node;
  }

  List<String> _pathFromRootTo(String focusId) {
    final root = rootId.value;
    if (root == null) return [focusId];

    final path = <String>[];
    GraphLayoutNode? cur = nodes[focusId];
    while (cur != null) {
      path.insert(0, cur.id);
      cur = cur.parentId != null ? nodes[cur.parentId] : null;
    }

    if (path.isNotEmpty && path.first == root) {
      return path;
    }
    return [focusId];
  }

  Future<List<FileGraphNode>> _loadChildren(String folderId) async {
    if (childrenCache.containsKey(folderId)) {
      return childrenCache[folderId]!;
    }
    final kids = (await fs.listChildren(folderId))
        .take(FileMapConstants.maxChildren)
        .toList();
    childrenCache[folderId] = kids;
    for (final child in kids) {
      _rememberNode(child);
    }
    return kids;
  }

  Future<void> _seedSingleLevel(
    String focusFolderId, {
    FileGraphNode? focusNode,
  }) async {
    focusNode ??= _knownNodes[focusFolderId] ?? nodes[focusFolderId]?.node;
    if (focusNode == null || !focusNode.isFolder) return;
    if (_navigationStack.isEmpty) {
      _navigationStack.add(focusFolderId);
    }

    _rememberNode(focusNode);
    mapping.value = true;

    try {
      for (final folderId in _navigationStack) {
        await _loadChildren(folderId);
      }
    } catch (e) {
      mapping.value = false;
      statusMsg.value = e is Exception ? e.toString() : 'Could not open that folder.';
      return;
    }

    final focusKids = childrenCache[focusFolderId] ?? [];
    final map = <String, GraphLayoutNode>{};
    final stackLen = _navigationStack.length;
    final mapRootId = _navigationStack.first;
    final rootNode = _knownNodes[mapRootId];
    if (rootNode == null || !rootNode.isFolder) {
      mapping.value = false;
      return;
    }

    final rootKids = childrenCache[mapRootId] ?? [];
    final rootChildIds = rootKids.map((c) => c.id).toList();

    // Map root always fans out one level of children.
    map[mapRootId] = GraphLayoutNode(
      node: rootNode,
      parentId: null,
      level: 0,
      loaded: true,
      childIds: rootChildIds,
      childCount: rootKids.length,
    );

    for (final child in rootKids) {
      map[child.id] = GraphLayoutNode(
        node: child,
        parentId: mapRootId,
        level: 1,
        loaded: child.isFile,
        childIds: const [],
      );
    }

    // Each folder on the navigation path projects exactly one level of children.
  // Deeper ancestors keep their level visible; only same-level siblings collapse.
    for (var i = 1; i < stackLen; i++) {
      final folderId = _navigationStack[i];
      final folderNode = _knownNodes[folderId];
      if (folderNode == null || !folderNode.isFolder) continue;

      final folderKids = childrenCache[folderId] ?? [];
      final folderChildIds = folderKids.map((c) => c.id).toList();
      final parentId = _navigationStack[i - 1];
      final projectionLevel = i + 1;

      map[folderId] = GraphLayoutNode(
        node: folderNode,
        parentId: parentId,
        level: i,
        loaded: true,
        childIds: folderChildIds,
        childCount: folderKids.length,
      );

      for (final child in folderKids) {
        map[child.id] = GraphLayoutNode(
          node: child,
          parentId: folderId,
          level: projectionLevel,
          loaded: child.isFile,
          childIds: const [],
        );
      }
    }

    final layoutRoot = mapRootId;
    final size = layoutFullTree(map, layoutRoot);
    canvasSize.value = size;
    nodes.assignAll(map);
    focusedId.value = focusFolderId;
    mapping.value = false;

    if (focusKids.isEmpty) {
      statusMsg.value = '"${focusNode.name}" is empty.';
    } else {
      statusMsg.value = null;
    }
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
