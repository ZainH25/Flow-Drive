import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../controller/graph_map_controller.dart';
import '../model/file_graph_node.dart';

/// Light graph map for fast file retrieval — opens files, never sends.
class FileMapScreen extends GetView<GraphMapController> {
  const FileMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final root = controller.rootId.value;
        final focused = controller.focusedId.value;
        if (root != null && focused != null && focused != root) {
          controller.goBack();
        } else {
          Get.back();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: Get.back,
          ),
          title: Obx(() {
            final chain = controller.breadcrumbChain();
            final title = chain.isEmpty ? 'File Map' : chain.last.name;
            return Text(title);
          }),
          actions: [
            TextButton.icon(
              onPressed: controller.grantAccess,
              icon: const Icon(Icons.folder_open_rounded, size: 20),
              label: const Text('Choose Folder'),
              style: TextButton.styleFrom(foregroundColor: AppColors.brandIndigo),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(40),
            child: Obx(() {
              final chain = controller.breadcrumbChain();
              if (chain.isEmpty) return const SizedBox(height: 8);

              return Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 16, 10),
                child: Row(
                  children: [
                    if (chain.length > 1)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: controller.goBack,
                        icon: const Icon(Icons.chevron_left_rounded, color: AppColors.brandIndigo),
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
                                onTap: () => controller.openFolder(chain[i].id),
                                child: Text(
                                  chain[i].name,
                                  style: TextStyle(
                                    color: i == chain.length - 1
                                        ? AppColors.textPrimary
                                        : AppColors.brandIndigo,
                                    fontSize: Responsive.sp(12),
                                    fontWeight:
                                        i == chain.length - 1 ? FontWeight.w700 : FontWeight.w500,
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
        body: Obx(() {
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
            );
          }

          if (controller.rootId.value == null) {
            return _MessageState(
              icon: Icons.account_tree_outlined,
              iconColor: AppColors.brandIndigo,
              title: 'Map a folder',
              body:
                  'Choose a folder. Flow maps its files (PDF, images, and more) as a graph — swipe or tap a node to open it.',
              actionLabel: 'Choose folder',
              onAction: controller.grantAccess,
            );
          }

          if (controller.mapping.value) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.brandIndigo),
                  const SizedBox(height: 16),
                  Text(
                    'Mapping folders… ${controller.mappedCount.value}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: Responsive.sp(14),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.infoBannerFill,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.infoBannerBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.touch_app_rounded, color: AppColors.brandIndigo, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Swipe or tap a node to open it. Folders focus · files open.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: Responsive.sp(12),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _GraphMapView(controller: controller)),
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
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: controller.grantAccess,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.brandIndigo,
                        side: const BorderSide(color: AppColors.brandIndigo),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.folder_open_rounded),
                      label: const Text(
                        'Choose Folder',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _GraphMapView extends StatefulWidget {
  const _GraphMapView({required this.controller});

  final GraphMapController controller;

  @override
  State<_GraphMapView> createState() => _GraphMapViewState();
}

class _GraphMapViewState extends State<_GraphMapView> {
  final _scrollController = ScrollController();
  String? _activeId;
  final List<String> _trail = [];
  double _trailOpacity = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _GraphMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scrollToFocused();
  }

  void _scrollToFocused() {
    final focusedId = widget.controller.focusedId.value;
    if (focusedId == null) return;
    final target = widget.controller.nodes[focusedId];
    if (target == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final canvasH = widget.controller.canvasSize.value.height;
      final screenH = MediaQuery.sizeOf(context).height;
      final y = (canvasH - target.y - screenH / 2).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        y,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    });
  }

  String? _hitTest(Offset local) {
    const hitSlack = 14.0;
    String? best;
    var bestDist = double.infinity;

    for (final n in widget.controller.nodes.values) {
      final radius = n.isRoot ? GraphMapConstants.rootRadius : GraphMapConstants.nodeRadius;
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

  void _setActive(String? id, {bool haptic = false}) {
    if (haptic && id != null && id != _activeId) {
      HapticFeedback.selectionClick();
    }
    setState(() => _activeId = id);
  }

  void _updateTrail(String? hit) {
    if (hit == null) return;
    if (_trail.isEmpty) {
      setState(() {
        _trail.add(hit);
        _trailOpacity = 1;
      });
      return;
    }
    if (hit == _activeId) return;

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

  void _commitSelection(String id) {
    HapticFeedback.mediumImpact();
    widget.controller.commitSelection(id, context);
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _trail.clear();
        _trailOpacity = 0;
        _activeId = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final nodes = widget.controller.nodes;
      final canvasSize = widget.controller.canvasSize.value;
      final focusedId = widget.controller.focusedId.value;

      _scrollToFocused();

      return SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 24),
        child: SizedBox(
          width: canvasSize.width,
          height: canvasSize.height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) {
              final hit = _hitTest(d.localPosition);
              _setActive(hit, haptic: hit != null);
              setState(() {
                _trail
                  ..clear()
                  ..addAll(hit != null ? [hit] : []);
                _trailOpacity = 1;
              });
            },
            onPanUpdate: (d) {
              final hit = _hitTest(d.localPosition);
              if (hit == null) return;
              _setActive(hit);
              _updateTrail(hit);
            },
            onPanEnd: (_) {
              final id = _activeId;
              _setActive(null);
              if (id != null) _commitSelection(id);
            },
            onTapUp: (d) {
              final hit = _hitTest(d.localPosition);
              if (hit != null) _commitSelection(hit);
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  size: canvasSize,
                  painter: _GraphEdgesPainter(
                    nodes: nodes,
                    trail: _trail,
                    trailOpacity: _trailOpacity,
                  ),
                ),
                for (final n in nodes.values)
                  _GraphNodeWidget(
                    node: n,
                    isFocused: focusedId == n.id,
                    isActive: _activeId == n.id,
                    inTrail: _trail.contains(n.id) && _activeId != n.id,
                  ),
              ],
            ),
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
  });

  final GraphLayoutNode node;
  final bool isFocused;
  final bool isActive;
  final bool inTrail;

  @override
  Widget build(BuildContext context) {
    final isRoot = node.isRoot;
    final radius = isRoot ? GraphMapConstants.rootRadius + 2 : GraphMapConstants.nodeRadius + 2;
    final scale = isActive ? 1.35 : inTrail ? 1.12 : 1.0;

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
                  border: Border.all(color: border, width: isFocused || isActive ? 2 : 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
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
                        size: isRoot ? 18 : 16,
                        color: iconColor,
                      ),
              ),
              if (node.node.isFolder && (node.childCount ?? 0) > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: AppColors.brandIndigo,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${node.childCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: radius * 2 + 4,
                width: isRoot ? 88 : 64,
                left: radius - (isRoot ? 44 : 32),
                child: Text(
                  shortGraphLabel(node.node.name, maxChars: isRoot ? 16 : 12),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isRoot ? AppColors.brandIndigo : AppColors.textSecondary,
                    fontSize: isRoot ? 10 : 9,
                    fontWeight: isRoot ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
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
      edgePaint.color = lit ? AppColors.brandIndigo : AppColors.border;
      edgePaint.strokeWidth = lit ? 2.2 : 1.2;
      canvas.drawLine(Offset(parent.x, parent.y), Offset(n.x, n.y), edgePaint);
    }

    if (trail.length < 2 || trailOpacity <= 0) return;

    final trailPaint = Paint()
      ..color = AppColors.brandIndigo.withValues(alpha: trailOpacity * 0.85)
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (var i = 0; i < trail.length; i++) {
      final p = nodes[trail[i]];
      if (p == null) continue;
      if (i == 0) {
        path.moveTo(p.x, p.y);
      } else {
        path.lineTo(p.x, p.y);
      }
    }
    canvas.drawPath(path, trailPaint);
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
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 30),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: Responsive.sp(18),
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
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
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
    );
  }
}
