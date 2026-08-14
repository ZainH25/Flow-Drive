import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/widgets/opened_path_banner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../gesture_shapes/controller/gesture_shapes_controller.dart';
import '../../gesture_shapes/view/gesture_pad_body.dart';
import '../../transfer/view/widgets/file_preview.dart';
import '../controller/file_map_controller.dart';
import '../model/file_graph_node.dart';

/// Bottom tabs in File Map — Map, Gesture (draw to open), Voice (same map).
enum FileMapShellTab { map, gesture, voice }

/// Light graph map for fast file retrieval — opens files, never sends.
class FileMapView extends GetView<FileMapController> {
  const FileMapView({super.key});

  static const title = 'Fast Retrieval';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (controller.canStepBackRoot) {
          controller.stepBackRoot();
          return;
        }
        final root = controller.rootId.value;
        final focused = controller.focusedId.value;
        if (root != null && focused != null && focused != root) {
          controller.goBack();
        } else {
          Get.back();
        }
      },
      child: _FileMapRoot(controller: controller),
    );
  }
}

class _FileMapRoot extends StatefulWidget {
  const _FileMapRoot({required this.controller});

  final FileMapController controller;

  @override
  State<_FileMapRoot> createState() => _FileMapRootState();
}

class _FileMapRootState extends State<_FileMapRoot> {
  FileMapShellTab _tab = FileMapShellTab.map;

  @override
  Widget build(BuildContext context) {
    final isGesture = _tab == FileMapShellTab.gesture;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Obx(() {
          if (widget.controller.rootHistory.isNotEmpty) {
            return IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Previous root',
              onPressed: widget.controller.stepBackRoot,
            );
          }
          return IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close',
            onPressed: Get.back,
          );
        }),
        title: const Text(FileMapView.title),
        actions: [
          if (!isGesture)
            IconButton(
              onPressed: widget.controller.grantAccess,
              icon: const Icon(Icons.folder_open_rounded),
              tooltip: 'Choose Folder',
              color: AppColors.brandIndigo,
            ),
        ],
        bottom: isGesture
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(40),
                child: Obx(() {
                  final chain = widget.controller.breadcrumbChain();
                  if (chain.isEmpty) return const SizedBox(height: 8);

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 16, 10),
                    child: Row(
                      children: [
                        if (chain.length > 1)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: widget.controller.goBack,
                            icon: const Icon(
                              Icons.chevron_left_rounded,
                              color: AppColors.brandIndigo,
                            ),
                          ),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (var i = 0; i < chain.length; i++) ...[
                                  if (i > 0)
                                    Text(
                                      ' / ',
                                      style: TextStyle(
                                        color: AppColors.textHint,
                                        fontSize: Responsive.sp(12),
                                      ),
                                    ),
                                  GestureDetector(
                                    onTap: () => widget.controller.openFolder(chain[i].id),
                                    child: Text(
                                      chain[i].name,
                                      style: TextStyle(
                                        color: i == chain.length - 1
                                            ? AppColors.textPrimary
                                            : AppColors.brandIndigo,
                                        fontSize: Responsive.sp(12),
                                        fontWeight: i == chain.length - 1
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
      ),
      body: Column(
        children: [
          if (_tab == FileMapShellTab.gesture)
            Obx(() {
              final mapLabel = widget.controller.openedItemLabel.value;
              final gestureLabel = Get.isRegistered<GestureShapesController>()
                  ? Get.find<GestureShapesController>().openedItemLabel.value
                  : null;
              final label = mapLabel ?? gestureLabel;
              if (label == null) return const SizedBox.shrink();

              return OpenedPathBanner(
                label: label,
                onDismiss: () {
                  widget.controller.dismissOpenedItem();
                  if (Get.isRegistered<GestureShapesController>()) {
                    Get.find<GestureShapesController>().dismissOpenedItem();
                  }
                },
              );
            }),
          Expanded(
            child: _FileMapShell(
              controller: widget.controller,
              tab: _tab,
              onTabChanged: (tab) {
                setState(() => _tab = tab);
                if (tab == FileMapShellTab.map) {
                  widget.controller.dismissOpenedItem();
                  widget.controller.setDisplayMode(FileMapDisplayMode.fullTree);
                } else if (tab == FileMapShellTab.voice) {
                  widget.controller.dismissOpenedItem();
                  widget.controller.setDisplayMode(FileMapDisplayMode.singleLevel);
                }
                if (tab == FileMapShellTab.gesture &&
                    Get.isRegistered<GestureShapesController>()) {
                  Get.find<GestureShapesController>().reloadShapes();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab shell: Map (existing graph) · Gesture · Voice (hook your flows here).
class _FileMapShell extends StatefulWidget {
  const _FileMapShell({
    required this.controller,
    required this.tab,
    required this.onTabChanged,
  });

  final FileMapController controller;
  final FileMapShellTab tab;
  final ValueChanged<FileMapShellTab> onTabChanged;

  @override
  State<_FileMapShell> createState() => _FileMapShellState();
}

class _FileMapShellState extends State<_FileMapShell> {
  static const _tabBarHeight = 88.0;
  static const _gestureActionHeight = 56.0;
  static const _gestureActionGap = 20.0;

  double get _contentBottomInset {
    if (widget.tab == FileMapShellTab.gesture) {
      return _tabBarHeight + _gestureActionHeight + _gestureActionGap + 8;
    }
    return _tabBarHeight;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: _contentBottomInset),
          child: _buildTabBody(),
        ),
        if (widget.tab == FileMapShellTab.gesture)
          Positioned(
            left: 16,
            right: 16,
            bottom: _tabBarHeight + _gestureActionGap,
            child: const _GestureActionBar(),
          ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 8,
          child: SafeArea(
            top: false,
            child: _FileMapModeBar(
              selected: widget.tab,
              onSelected: widget.onTabChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBody() {
    switch (widget.tab) {
      case FileMapShellTab.map:
        return _MapTabBody(controller: widget.controller);
      case FileMapShellTab.gesture:
        return const GesturePadBody();
      case FileMapShellTab.voice:
        return _MapTabBody(controller: widget.controller, singleLevel: true);
    }
  }
}

class _GestureActionBar extends StatelessWidget {
  const _GestureActionBar();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GestureShapesController>();

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: controller.clearDraft,
                child: const Text('Clear'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => controller.tryMatchAndOpen(clearOnMiss: true),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Open match'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapTabBody extends StatelessWidget {
  const _MapTabBody({
    required this.controller,
    this.singleLevel = false,
  });

  final FileMapController controller;
  final bool singleLevel;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.ready.value) {
        return const Center(child: CircularProgressIndicator(color: AppColors.brandIndigo));
      }

      if (controller.error.value != null) {
        return _MessageState(
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.error,
          title: 'Couldn’t load files',
          body: controller.error.value!,
          actionLabel: 'Retry',
          onAction: controller.retryBootstrap,
          showDotGrid: true,
        );
      }

      if (controller.rootId.value == null) {
        return _MessageState(
          icon: Icons.account_tree_outlined,
          iconColor: AppColors.brandIndigo,
          title: singleLevel ? 'Browse a folder' : 'Map a folder',
          body: singleLevel
              ? 'Choose a folder. You will see only its immediate contents — tap a subfolder to drill in one level at a time.'
              : 'Choose a folder. Flow maps its files (PDF, images, and more) as a graph — swipe or tap a node to open it.',
          actionLabel: 'Choose folder',
          onAction: controller.grantAccess,
          showDotGrid: true,
          useGradientButton: true,
        );
      }

      if (controller.mapping.value) {
        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFFF7F7FC)),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.brandIndigo),
                  const SizedBox(height: 16),
                  Text(
                    singleLevel
                        ? 'Loading folder…'
                        : 'Mapping folders… ${controller.mappedCount.value}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: Responsive.sp(14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }

      return Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF0FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD8DCFF)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.brandIndigo.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.touch_app_rounded,
                    color: AppColors.brandIndigo,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    singleLevel
                        ? 'Each folder shows one level of its contents along the path. Tap a folder to branch in — switching a sibling collapses only that sibling’s branch. Long-press a folder for Just open / Make root; long-press a file to share.'
                        : 'Drag to highlight a path — release on a file to open it, or on a folder to make root / just open. Double-tap any file to open. Long-press a file to share. Pinch or slide with two fingers to explore branches.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: Responsive.sp(12),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _GraphMapView(controller: controller, singleLevel: singleLevel)),
          if (controller.statusMsg.value != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                controller.statusMsg.value!,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: Responsive.sp(12),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: controller.grantAccess,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandIndigo,
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.brandIndigo, width: 1.4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                icon: const Icon(Icons.folder_open_rounded),
                label: const Text(
                  'Choose Folder',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _FileMapModeBar extends StatelessWidget {
  const _FileMapModeBar({
    required this.selected,
    required this.onSelected,
  });

  final FileMapShellTab selected;
  final ValueChanged<FileMapShellTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _FileMapModeTab(
            label: 'Map',
            icon: Icons.account_tree_outlined,
            selected: selected == FileMapShellTab.map,
            onTap: () => onSelected(FileMapShellTab.map),
          ),
          _FileMapModeTab(
            label: 'Gesture',
            icon: Icons.near_me_outlined,
            selected: selected == FileMapShellTab.gesture,
            onTap: () => onSelected(FileMapShellTab.gesture),
          ),
          _FileMapModeTab(
            label: 'Voice',
            icon: Icons.mic_none_rounded,
            selected: selected == FileMapShellTab.voice,
            onTap: () => onSelected(FileMapShellTab.voice),
          ),
        ],
      ),
    );
  }
}

class _FileMapModeTab extends StatelessWidget {
  const _FileMapModeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.brandIndigo : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Responsive.sp(13),
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GraphMapView extends StatefulWidget {
  const _GraphMapView({
    required this.controller,
    this.singleLevel = false,
  });

  final FileMapController controller;
  final bool singleLevel;

  @override
  State<_GraphMapView> createState() => _GraphMapViewState();
}

class _GraphMapViewState extends State<_GraphMapView> {
  final _transformController = TransformationController();
  String? _activeId;
  final List<String> _trail = [];
  double _trailOpacity = 0;

  String? _doubleTapCandidateId;
  DateTime? _doubleTapAt;
  bool _dragActive = false;
  bool _pathTracking = false;
  bool _pathMoved = false;
  Offset? _pathStart;
  int _pointerCount = 0;
  String? _lastCenteredId;

  static const _doubleTapWindow = Duration(milliseconds: 350);

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _GraphMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scrollToFocused();
  }

  void _scrollToFocused({bool force = false}) {
    final focusedId = widget.controller.focusedId.value;
    if (focusedId == null) return;
    if (!force && focusedId == _lastCenteredId) return;
    final target = widget.controller.nodes[focusedId];
    if (target == null) return;
    _lastCenteredId = focusedId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final viewport = MediaQuery.sizeOf(context);
      final scale = _transformController.value.getMaxScaleOnAxis().clamp(0.45, 2.5);
      final dx = viewport.width / 2 - target.x * scale;
      final dy = viewport.height / 2 - target.y * scale;
      final next = Matrix4.identity()
        ..translateByDouble(dx, dy, 0, 1)
        ..scaleByDouble(scale, scale, 1, 1);
      _transformController.value = next;
    });
  }

  String? _hitTest(Offset local) {
    const hitSlack = 18.0;
    String? best;
    var bestDist = double.infinity;

    for (final n in widget.controller.nodes.values) {
      final radius = n.isRoot ? FileMapConstants.rootRadius : FileMapConstants.nodeRadius;
      final dx = n.x - local.dx;
      final dy = n.y - local.dy;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist <= radius + hitSlack && dist < bestDist) {
        bestDist = dist;
        best = n.id;
      }
    }
    return best;
  }

  bool _isFolder(String id) => widget.controller.nodes[id]?.node.isFolder == true;

  bool _isFile(String id) => widget.controller.nodes[id]?.node.isFile == true;

  void _setActive(String? id, {bool haptic = false}) {
    if (haptic && id != null && id != _activeId) {
      HapticFeedback.selectionClick();
    }
    setState(() => _activeId = id);
  }

  /// Build / extend the highlighted path as the finger moves across nodes.
  void _updateTrail(String? hit) {
    if (hit == null) return;
    if (_trail.isEmpty) {
      setState(() {
        _trail.add(hit);
        _trailOpacity = 1;
      });
      return;
    }
    if (hit == _trail.last) return;

    final prior = _trail.indexOf(hit);
    setState(() {
      if (prior >= 0) {
        _trail.removeRange(prior + 1, _trail.length);
      } else {
        _trail.add(hit);
      }
      _trailOpacity = 1;
    });
    HapticFeedback.selectionClick();
  }

  void _fadeTrailSoon() {
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _trail.clear();
        _trailOpacity = 0;
        _activeId = null;
      });
    });
  }

  Future<void> _shareFile(GraphLayoutNode node) async {
    HapticFeedback.mediumImpact();
    await FilePreview.shareFile(node.node.path, node.node.name);
  }

  Future<void> _offerFolderActions(GraphLayoutNode node) async {
    HapticFeedback.mediumImpact();
    if (node.id == widget.controller.rootId.value) return;
    await widget.controller.offerMakeRootOrNavigate(node.id, context);
  }

  Future<void> _onPanEnd() async {
    final id = _activeId;
    _setActive(null);
    _dragActive = false;
    _pathTracking = false;

    if (id == null) {
      _fadeTrailSoon();
      return;
    }

    HapticFeedback.mediumImpact();

    if (_isFile(id)) {
      await widget.controller.openFile(id, context);
      if (!mounted) return;
      _fadeTrailSoon();
      return;
    }

    if (_isFolder(id)) {
      if (widget.singleLevel) {
        if (id != widget.controller.focusedId.value) {
          widget.controller.openFolder(id);
        }
      } else {
        final isRoot = id == widget.controller.rootId.value;
        if (isRoot) {
          widget.controller.openFolder(id);
        } else {
          await widget.controller.offerMakeRootOrNavigate(id, context);
        }
      }
      if (!mounted) return;
      _scrollToFocused(force: true);
      _fadeTrailSoon();
      return;
    }

    _fadeTrailSoon();
  }

  void _handleTap(String id) {
    if (_dragActive) return;

    if (_isFile(id)) {
      final now = DateTime.now();
      final isDouble = _doubleTapCandidateId == id &&
          _doubleTapAt != null &&
          now.difference(_doubleTapAt!) <= _doubleTapWindow;

      if (isDouble) {
        _doubleTapCandidateId = null;
        _doubleTapAt = null;
        HapticFeedback.mediumImpact();
        widget.controller.openFile(id, context);
        _fadeTrailSoon();
        return;
      }

      _doubleTapCandidateId = id;
      _doubleTapAt = now;
      setState(() {
        _trail
          ..clear()
          ..add(id);
        _trailOpacity = 1;
        _activeId = id;
      });
      _fadeTrailSoon();
      return;
    }

    if (_isFolder(id)) {
      HapticFeedback.mediumImpact();
      if (!widget.singleLevel || id != widget.controller.focusedId.value) {
        widget.controller.openFolder(id);
      }
      _fadeTrailSoon();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final nodes = widget.controller.nodes;
      final canvasSize = widget.controller.canvasSize.value;
      final focusedId = widget.controller.focusedId.value;

      _scrollToFocused();

      // Two-finger pan/zoom via InteractiveViewer; one-finger on a node keeps path logic.
      // Dot grid is painted in viewport space so it tiles infinitely while panning.
      return ClipRect(
        child: ColoredBox(
          color: const Color(0xFFF7F7FC),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedBuilder(
                animation: _transformController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _InfiniteDotGridPainter(
                      transform: _transformController.value,
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
              InteractiveViewer(
                transformationController: _transformController,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(4000),
                minScale: 0.45,
                maxScale: 2.6,
                panEnabled: !_pathTracking,
                scaleEnabled: true,
                child: SizedBox(
                  width: canvasSize.width,
                  height: canvasSize.height,
                  child: Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (e) {
                      _pointerCount += 1;
                      if (_pointerCount >= 2) {
                        // Two fingers → canvas move/zoom; cancel path tracking.
                        if (_pathTracking) {
                          setState(() {
                            _pathTracking = false;
                            _pathMoved = false;
                            _dragActive = false;
                          });
                        }
                        return;
                      }

                      // Child coords are already in scene space under InteractiveViewer.
                      final scene = e.localPosition;
                      final hit = _hitTest(scene);
                      _pathStart = scene;
                      _pathMoved = false;
                      if (hit != null) {
                        setState(() {
                          _pathTracking = true;
                          _dragActive = true;
                          _trail
                            ..clear()
                            ..add(hit);
                          _trailOpacity = 1;
                        });
                        _setActive(hit, haptic: true);
                      }
                    },
                    onPointerMove: (e) {
                      if (!_pathTracking || _pointerCount != 1) return;
                      final scene = e.localPosition;
                      if (_pathStart != null && (scene - _pathStart!).distance > 10) {
                        _pathMoved = true;
                      }
                      final hit = _hitTest(scene);
                      _updateTrail(hit);
                      if (hit != null) _setActive(hit);
                    },
                    onPointerUp: (e) {
                      _pointerCount = (_pointerCount - 1).clamp(0, 10);
                      if (_pathTracking && _pointerCount == 0) {
                        if (!_pathMoved) {
                          final id = _activeId;
                          _pathTracking = false;
                          _dragActive = false;
                          _setActive(null);
                          if (id != null) {
                            _handleTap(id);
                          } else {
                            _fadeTrailSoon();
                          }
                        } else {
                          _onPanEnd();
                        }
                        return;
                      }
                    },
                    onPointerCancel: (_) {
                      _pointerCount = (_pointerCount - 1).clamp(0, 10);
                      if (_pointerCount == 0) {
                        _pathTracking = false;
                        _pathMoved = false;
                        _dragActive = false;
                        _fadeTrailSoon();
                      }
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CustomPaint(
                          size: canvasSize,
                          painter: _GraphEdgesPainter(
                            nodes: nodes,
                            trail: List<String>.from(_trail),
                            trailOpacity: _trailOpacity,
                          ),
                        ),
                        for (final n in nodes.values)
                          _GraphNodeWidget(
                            node: n,
                            isFocused: focusedId == n.id,
                            isActive: _activeId == n.id,
                            inTrail: _trail.contains(n.id) && _activeId != n.id,
                            onLongPress: n.node.isFile
                                ? () => _shareFile(n)
                                : () => _offerFolderActions(n),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _GraphNodeWidget extends StatelessWidget {
  const _GraphNodeWidget({
    required this.node,
    required this.isFocused,
    required this.isActive,
    required this.inTrail,
    this.onLongPress,
  });

  final GraphLayoutNode node;
  final bool isFocused;
  final bool isActive;
  final bool inTrail;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final isRoot = node.isRoot;
    final radius = isRoot ? FileMapConstants.rootRadius + 3 : FileMapConstants.nodeRadius + 3;
    final scale = isActive ? 1.28 : inTrail ? 1.1 : 1.0;

    final Color bg;
    final Color border;
    final Color iconColor;

    if (isRoot) {
      bg = AppColors.brandIndigo;
      border = AppColors.brandIndigo;
      iconColor = Colors.white;
    } else if (isActive) {
      bg = AppColors.brandIndigo.withValues(alpha: 0.18);
      border = AppColors.brandIndigo;
      iconColor = AppColors.brandIndigo;
    } else if (inTrail) {
      bg = AppColors.infoBannerFill;
      border = AppColors.brandIndigo.withValues(alpha: 0.55);
      iconColor = AppColors.brandIndigo;
    } else if (node.node.isFolder) {
      bg = AppColors.surface;
      border = isFocused ? AppColors.brandIndigo : AppColors.border;
      iconColor = AppColors.brandIndigo;
    } else {
      bg = AppColors.surface;
      border = isFocused ? AppColors.brandIndigo : AppColors.border;
      iconColor = _fileIconColor(node.node.name);
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      left: node.x - radius,
      top: node.y - radius,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 120),
          child: SizedBox(
            width: radius * 2,
            height: radius * 2,
            child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: border,
                    width: isRoot || isFocused || isActive ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isRoot ? 0.12 : 0.07),
                      blurRadius: isRoot ? 14 : 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: node.loading
                    ? SizedBox(
                        width: radius * 0.7,
                        height: radius * 0.7,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isRoot ? Colors.white : AppColors.brandIndigo,
                        ),
                      )
                    : Icon(
                        _iconForNode(node),
                        size: isRoot ? 24 : 22,
                        color: iconColor,
                      ),
              ),
              if (node.node.isFolder && (node.childCount ?? 0) > 0)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: AppColors.brandIndigo,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandIndigo.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${node.childCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: radius * 2 + 8,
                width: isRoot ? 110 : 88,
                left: radius - (isRoot ? 55 : 44),
                child: Text(
                  shortGraphLabel(node.node.name, maxChars: isRoot ? 16 : 12),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isRoot ? AppColors.brandIndigo : AppColors.textSecondary,
                    fontSize: isRoot ? 12 : 11,
                    fontWeight: isRoot ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  IconData _iconForNode(GraphLayoutNode node) {
    if (node.isRoot) return Icons.folder_special_rounded;
    if (node.node.isFolder) return Icons.folder_rounded;
    return switch (graphFileKind(node.node.name)) {
      GraphFileKind.pdf => Icons.picture_as_pdf_rounded,
      GraphFileKind.image => Icons.image_rounded,
      GraphFileKind.video => Icons.videocam_rounded,
      GraphFileKind.audio => Icons.audiotrack_rounded,
      GraphFileKind.doc => Icons.description_rounded,
      GraphFileKind.sheet => Icons.table_chart_rounded,
      GraphFileKind.slide => Icons.slideshow_rounded,
      GraphFileKind.text => Icons.article_outlined,
      GraphFileKind.file => Icons.insert_drive_file_rounded,
    };
  }

  Color _fileIconColor(String name) {
    return switch (graphFileKind(name)) {
      GraphFileKind.pdf => const Color(0xFFE53935),
      GraphFileKind.image => AppColors.accent,
      GraphFileKind.video => AppColors.purple,
      GraphFileKind.audio => AppColors.primaryLight,
      GraphFileKind.doc => AppColors.brandIndigo,
      GraphFileKind.sheet => AppColors.success,
      GraphFileKind.slide => AppColors.warning,
      GraphFileKind.text => AppColors.textSecondary,
      GraphFileKind.file => AppColors.brandIndigo,
    };
  }
}

/// Infinite tiling dots in viewport space — scrolls forever with pan/zoom.
class _InfiniteDotGridPainter extends CustomPainter {
  _InfiniteDotGridPainter({required this.transform});

  final Matrix4 transform;

  static const _baseStep = 18.0;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = transform.getMaxScaleOnAxis().clamp(0.35, 3.0);
    final tx = transform.storage[12];
    final ty = transform.storage[13];
    final step = _baseStep * scale;

    final paint = Paint()
      ..color = const Color(0xFFD7D9E8).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    // Align dots to world grid so they feel continuous while panning.
    var startX = tx % step;
    var startY = ty % step;
    if (startX > 0) startX -= step;
    if (startY > 0) startY -= step;

    for (var x = startX; x < size.width + step; x += step) {
      for (var y = startY; y < size.height + step; y += step) {
        canvas.drawCircle(Offset(x, y), 1.05 * scale.clamp(0.7, 1.4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _InfiniteDotGridPainter oldDelegate) {
    return oldDelegate.transform != transform;
  }
}

class _GraphEdgesPainter extends CustomPainter {
  _GraphEdgesPainter({
    required this.nodes,
    required this.trail,
    required this.trailOpacity,
  });

  final Map<String, GraphLayoutNode> nodes;
  final List<String> trail;
  final double trailOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final edgePaint = Paint()..style = PaintingStyle.stroke;

    for (final n in nodes.values) {
      final parentId = n.parentId;
      if (parentId == null) continue;
      final parent = nodes[parentId];
      if (parent == null) continue;

      final lit = _edgeLit(parent.node.id, n.id);
      edgePaint.color = lit
          ? AppColors.brandIndigo.withValues(alpha: 0.95 * trailOpacity.clamp(0.35, 1))
          : const Color(0xFFD5D7E4);
      edgePaint.strokeWidth = lit ? 2.6 : 1.15;
      canvas.drawLine(Offset(parent.x, parent.y), Offset(n.x, n.y), edgePaint);
    }

    if (trail.length < 2 || trailOpacity <= 0) return;

    final trailPaint = Paint()
      ..color = AppColors.brandIndigo.withValues(alpha: trailOpacity * 0.9)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    var started = false;
    for (var i = 0; i < trail.length; i++) {
      final p = nodes[trail[i]];
      if (p == null) continue;
      if (!started) {
        path.moveTo(p.x, p.y);
        started = true;
      } else {
        path.lineTo(p.x, p.y);
      }
    }
    if (started) canvas.drawPath(path, trailPaint);
  }

  bool _edgeLit(String a, String b) {
    for (var i = 0; i < trail.length - 1; i++) {
      if ((trail[i] == a && trail[i + 1] == b) || (trail[i] == b && trail[i + 1] == a)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool shouldRepaint(covariant _GraphEdgesPainter oldDelegate) {
    return oldDelegate.trail != trail ||
        oldDelegate.trailOpacity != trailOpacity ||
        oldDelegate.nodes != nodes;
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    this.showDotGrid = false,
    this.useGradientButton = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;
  final bool showDotGrid;
  final bool useGradientButton;

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 34),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: Responsive.sp(20),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: Responsive.sp(14),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              if (useGradientButton)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.buttonGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandIndigo.withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onAction,
                      borderRadius: BorderRadius.circular(28),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                        child: Text(
                          actionLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                FilledButton(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandIndigo,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
      ),
    );

    if (!showDotGrid) {
      return SizedBox.expand(child: content);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFFF7F7FC)),
        CustomPaint(
          painter: _InfiniteDotGridPainter(transform: Matrix4.identity()),
          child: const SizedBox.expand(),
        ),
        content,
      ],
    );
  }
}
