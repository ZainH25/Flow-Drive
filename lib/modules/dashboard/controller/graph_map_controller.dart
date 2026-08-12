import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../transfer/view/widgets/file_preview.dart';
import '../model/file_graph_node.dart';
import '../model/picked_file_item.dart';
import '../service/graph_file_system_service.dart';

class GraphMapConstants {
  GraphMapConstants._();

  static const maxChildren = 3;
  static const maxTotalFolders = 220;
  static const nodeRadius = 15.0;
  static const rootRadius = 15.0;
  static const levelGap = 56.0;
  static const siblingGap = 46.0;
  static const bottomMargin = 40.0;
  static const topPadding = 40.0;
}

class GraphMapController extends GetxController {
  final GraphFileSystemService fs = GraphFileSystemService();

  final ready = false.obs;
  final error = RxnString();
  final mapping = false.obs;
  final mappedCount = 0.obs;
  final nodes = <String, GraphLayoutNode>{}.obs;
  final rootId = RxnString();
  final focusedId = RxnString();
  final statusMsg = RxnString();
  final canvasSize = const Size(360, 640).obs;

  final childrenCache = <String, List<FileGraphNode>>{};
  int _folderCount = 0;
  int _seedGeneration = 0;

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
      await seedRoot(roots.first);
    } catch (e) {
      error.value = e is Exception ? e.toString() : 'Failed to load file access.';
    } finally {
      ready.value = true;
    }
  }

  Future<void> crawlTree(FileGraphNode node) async {
    if (_folderCount >= GraphMapConstants.maxTotalFolders) return;
    _folderCount += 1;

    List<FileGraphNode> kids = [];
    try {
      kids = (await fs.listChildren(node.id))
          .take(GraphMapConstants.maxChildren)
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

    final canvasW = screen.width > widestLevel * GraphMapConstants.siblingGap + 40
        ? screen.width
        : widestLevel * GraphMapConstants.siblingGap + 40;
    final canvasH = screen.height * 0.6 > GraphMapConstants.bottomMargin + maxLevel * GraphMapConstants.levelGap + GraphMapConstants.topPadding
        ? screen.height * 0.6
        : GraphMapConstants.bottomMargin + maxLevel * GraphMapConstants.levelGap + GraphMapConstants.topPadding;

    void assign(String id, double xMin, double xMax) {
      final n = map[id];
      if (n == null) return;
      n
        ..x = (xMin + xMax) / 2
        ..y = canvasH - GraphMapConstants.bottomMargin - n.level * GraphMapConstants.levelGap;

      final kids = n.childIds;
      if (kids.isEmpty) return;

      final span = xMax - xMin;
      final seg = span / kids.length < GraphMapConstants.siblingGap
          ? GraphMapConstants.siblingGap
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

  Future<void> seedRoot(FileGraphNode rootNode) async {
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

    if (_folderCount >= GraphMapConstants.maxTotalFolders) {
      statusMsg.value =
          'Mapped the first ${GraphMapConstants.maxTotalFolders} folders — deeper ones load on first swipe there.';
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
      final kids = (await fs.listChildren(id)).take(GraphMapConstants.maxChildren).toList();
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
    focusedId.value = id;
    statusMsg.value = null;
    if (target != null && !target.loaded) {
      lazyLoadFolder(id);
    }
  }

  void goBack() {
    final currentId = focusedId.value;
    if (currentId == null) return;
    final current = nodes[currentId];
    if (current?.parentId != null) openFolder(current!.parentId!);
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
      if (root != null) await seedRoot(root);
    } catch (e) {
      error.value = e is Exception ? e.toString() : 'Could not grant folder access.';
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

  void commitSelection(String id, BuildContext context) {
    final target = nodes[id];
    if (target == null) return;

    if (target.node.isFolder) {
      openFolder(id);
      return;
    }

    openFile(id, context);
  }

  String? _extension(String name) {
    final dot = name.lastIndexOf('.');
    if (dot <= 0) return null;
    return name.substring(dot + 1).toLowerCase();
  }
}
