import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../controller/gesture_shapes_controller.dart';
import '../widgets/gesture_draw_canvas.dart';

/// Draw-to-open pad used inside File Map's Gesture tab.
class GesturePadBody extends StatefulWidget {
  const GesturePadBody({super.key});

  @override
  State<GesturePadBody> createState() => _GesturePadBodyState();
}

class _GesturePadBodyState extends State<GesturePadBody> {
  late final GestureShapesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<GestureShapesController>();
    _controller.reloadShapes();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Obx(() {
        final hasShapes = _controller.shapes.isNotEmpty;
        final message = _controller.statusMessage.value;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasShapes
                          ? 'Draw a saved shape to open its file in local storage.'
                          : 'No shapes yet — add them in Profile first.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: Responsive.sp(13),
                        height: 1.35,
                      ),
                    ),
                  ),
                  if (!hasShapes)
                    TextButton(
                      onPressed: () => Get.toNamed(AppRoutes.gestureShapes),
                      child: const Text('Add shapes'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: GestureDrawCanvas(
                  controller: _controller,
                  matchOnStrokeEnd: true,
                  showDotGrid: true,
                  lightStyle: true,
                ),
              ),
            ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: Responsive.sp(12)),
                ),
              ),
          ],
        );
      }),
    );
  }
}
