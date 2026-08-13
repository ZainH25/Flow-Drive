import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../model/gesture_shape.dart';
import 'gesture_stroke_painter.dart';

/// Small preview of a saved gesture shape.
class GestureShapeThumbnail extends StatelessWidget {
  const GestureShapeThumbnail({
    super.key,
    required this.strokes,
    this.size = 48,
  });

  final List<List<Offset>> strokes;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: CustomPaint(
        painter: GestureStrokePainter(
          strokes: strokes,
          fitToBounds: true,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}

/// Full-screen overlay preview — dismiss on tap or finger release.
class GestureShapePreviewOverlay {
  GestureShapePreviewOverlay._();

  static OverlayEntry? _entry;

  static void show(BuildContext context, GestureShape shape) {
    dismiss();

    final overlay = Overlay.of(context, rootOverlay: true);
    _entry = OverlayEntry(
      builder: (ctx) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerUp: (_) => dismiss(),
          onPointerCancel: (_) => dismiss(),
          child: GestureDetector(
            onTap: dismiss,
            behavior: HitTestBehavior.opaque,
            child: Material(
              color: Colors.black.withValues(alpha: 0.55),
              child: SafeArea(
                child: Center(
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 280,
                      padding: const EdgeInsets.all(20),
                      margin: Responsive.pagePadding,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            shape.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            shape.kindLabel,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: Responsive.sp(12),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 220,
                            height: 220,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F7FC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: CustomPaint(
                                painter: GestureStrokePainter(
                                  strokes: shape.strokes,
                                  fitToBounds: true,
                                  strokeWidth: 3.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Release to close',
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: Responsive.sp(11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_entry!);
  }

  static void dismiss() {
    _entry?.remove();
    _entry = null;
  }
}
