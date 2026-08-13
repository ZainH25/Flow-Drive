import 'dart:math' as math;
import 'dart:ui';

enum GestureShapeKind { line, closed }

/// Geometric fingerprint used to separate lines from closed shapes (circle, square, etc.).
class GestureSignature {
  const GestureSignature({
    required this.kind,
    required this.lineScore,
    required this.circularity,
  });

  final GestureShapeKind kind;
  final double lineScore;
  final double circularity;

  static GestureSignature fromStrokes(List<List<Offset>> strokes) {
    final points = _flatten(strokes);
    if (points.length < 2) {
      return const GestureSignature(
        kind: GestureShapeKind.line,
        lineScore: 0,
        circularity: 0,
      );
    }

    final length = _pathLength(points);
    final endpointGap = (points.first - points.last).distance;
    final diagonal = _boundingDiagonal(points);
    final lineScore = length <= 0 ? 0.0 : (endpointGap / length).clamp(0.0, 1.0);
    final loopRatio = diagonal <= 0 ? 0.0 : length / diagonal;
    final closedByGap = _isClosed(points);
    final closedByLoop = loopRatio >= 2.6 && points.length >= 14;
    final isClosed = closedByGap || closedByLoop;
    final circularity = isClosed ? _circularity(points) : 0.0;

    final kind = !isClosed && lineScore >= 0.48
        ? GestureShapeKind.line
        : GestureShapeKind.closed;

    return GestureSignature(
      kind: kind,
      lineScore: lineScore,
      circularity: circularity,
    );
  }

  bool isCompatibleWith(GestureSignature other) => kind == other.kind;

  static List<Offset> _flatten(List<List<Offset>> strokes) {
    final flat = <Offset>[];
    for (final stroke in strokes) {
      if (stroke.length >= 2) flat.addAll(stroke);
    }
    return flat;
  }

  static bool _isClosed(List<Offset> points) {
    if (points.length < 10) return false;
    final span = _boundingDiagonal(points);
    if (span <= 0) return false;
    return (points.first - points.last).distance < span * 0.24;
  }

  static double _circularity(List<Offset> points) {
    final area = _polygonArea(points).abs();
    final perimeter = _pathLength(points);
    if (perimeter <= 0) return 0;
    return ((4 * math.pi * area) / (perimeter * perimeter)).clamp(0.0, 1.0);
  }

  static double _polygonArea(List<Offset> points) {
    var sum = 0.0;
    for (var i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      sum += points[i].dx * points[j].dy - points[j].dx * points[i].dy;
    }
    return sum / 2;
  }

  static double _boundingDiagonal(List<Offset> points) {
    var minX = points.first.dx;
    var maxX = points.first.dx;
    var minY = points.first.dy;
    var maxY = points.first.dy;
    for (final p in points) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }
    final w = maxX - minX;
    final h = maxY - minY;
    return math.sqrt(w * w + h * h);
  }

  static double _pathLength(List<Offset> points) {
    var length = 0.0;
    for (var i = 1; i < points.length; i++) {
      length += (points[i] - points[i - 1]).distance;
    }
    return length;
  }
}
