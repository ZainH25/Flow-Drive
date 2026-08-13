import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Paints gesture strokes — optional [fitToBounds] for list thumbnails / previews.
class GestureStrokePainter extends CustomPainter {
  const GestureStrokePainter({
    required this.strokes,
    this.showDotGrid = false,
    this.lightStyle = false,
    this.fitToBounds = false,
    this.strokeWidth = 4,
  });

  final List<List<Offset>> strokes;
  final bool showDotGrid;
  final bool lightStyle;
  final bool fitToBounds;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (showDotGrid) {
      const step = 24.0;
      final dotColor = lightStyle
          ? const Color(0xFFD8D8E4)
          : AppColors.border.withValues(alpha: 0.55);
      final dot = Paint()..color = dotColor;
      for (var x = 0.0; x < size.width; x += step) {
        for (var y = 0.0; y < size.height; y += step) {
          canvas.drawCircle(Offset(x, y), 1.2, dot);
        }
      }
    }

    final drawStrokes = fitToBounds ? _fitStrokes(strokes, size, padding: 10) : strokes;

    final strokePaint = Paint()
      ..color = AppColors.brandIndigo
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final stroke in drawStrokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, strokePaint);
    }
  }

  static List<List<Offset>> _fitStrokes(
    List<List<Offset>> strokes,
    Size size, {
    required double padding,
  }) {
    final flat = <Offset>[];
    for (final stroke in strokes) {
      flat.addAll(stroke);
    }
    if (flat.isEmpty) return strokes;

    var minX = flat.first.dx;
    var maxX = flat.first.dx;
    var minY = flat.first.dy;
    var maxY = flat.first.dy;
    for (final p in flat) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }

    final w = math.max(maxX - minX, 1.0);
    final h = math.max(maxY - minY, 1.0);
    final availW = size.width - padding * 2;
    final availH = size.height - padding * 2;
    final scale = math.min(availW / w, availH / h);
    final cx = (minX + maxX) / 2;
    final cy = (minY + maxY) / 2;
    final targetCx = size.width / 2;
    final targetCy = size.height / 2;

    return strokes
        .map(
          (stroke) => stroke
              .map(
                (p) => Offset(
                  (p.dx - cx) * scale + targetCx,
                  (p.dy - cy) * scale + targetCy,
                ),
              )
              .toList(growable: false),
        )
        .toList(growable: false);
  }

  @override
  bool shouldRepaint(covariant GestureStrokePainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.showDotGrid != showDotGrid ||
        oldDelegate.lightStyle != lightStyle ||
        oldDelegate.fitToBounds != fitToBounds ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
