import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../controller/gesture_shapes_controller.dart';
import 'gesture_stroke_painter.dart';

/// Draw pad wired to [GestureShapesController]. Captures drags without scrolling parents.
class GestureDrawCanvas extends StatelessWidget {
  const GestureDrawCanvas({
    super.key,
    required this.controller,
    this.matchOnStrokeEnd = false,
    this.showDotGrid = false,
    this.lightStyle = false,
  });

  final GestureShapesController controller;
  final bool matchOnStrokeEnd;
  final bool showDotGrid;
  final bool lightStyle;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Responsive.radius(20)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: lightStyle
              ? Colors.white
              : (showDotGrid ? const Color(0xFFF7F7FC) : AppColors.surface),
          border: Border.all(
            color: lightStyle ? const Color(0xFFE8E8F0) : AppColors.border,
          ),
        ),
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => controller.unfocusKeyboard(),
          child: Obx(() {
            return RawGestureDetector(
              behavior: HitTestBehavior.opaque,
              gestures: <Type, GestureRecognizerFactory>{
                _CanvasPanGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<_CanvasPanGestureRecognizer>(
                  _CanvasPanGestureRecognizer.new,
                  (_CanvasPanGestureRecognizer instance) {
                    instance.onStart = (details) {
                      controller.beginStroke(details.localPosition);
                    };
                    instance.onUpdate = (details) {
                      controller.extendStroke(details.localPosition);
                    };
                    instance.onEnd = (_) {
                      controller.endStroke();
                      if (matchOnStrokeEnd) {
                        controller.tryMatchAndOpen(clearOnMiss: false);
                      }
                    };
                  },
                ),
              },
              child: CustomPaint(
                painter: GestureStrokePainter(
                  strokes: controller.activeStrokes,
                  showDotGrid: showDotGrid,
                  lightStyle: lightStyle,
                ),
                child: const SizedBox.expand(),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _CanvasPanGestureRecognizer extends PanGestureRecognizer {
  _CanvasPanGestureRecognizer();

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}
