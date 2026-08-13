import 'dart:math' as math;
import 'dart:ui';

import 'gesture_signature.dart';

/// $1-style unistroke matcher with rotation + cyclic search for closed shapes.
class GestureRecognizer {
  static const _sampleCount = 64;
  static const _squareSize = 250.0;
  static const _matchThreshold = 2.55;
  static const _duplicateThreshold = 1.65;

  static GestureMatch? bestMatch(
    List<List<Offset>> input,
    List<({String id, List<List<Offset>> strokes, GestureSignature signature})> templates,
  ) {
    if (input.isEmpty || templates.isEmpty) return null;

    final inputSignature = GestureSignature.fromStrokes(input);
    final normalizedInput = _normalizePoints(_flatten(input));
    if (normalizedInput.isEmpty) return null;

    final scores = <({String id, double score})>[];

    for (final template in templates) {
      if (!inputSignature.isCompatibleWith(template.signature)) continue;

      final normalizedTemplate = _normalizePoints(_flatten(template.strokes));
      if (normalizedTemplate.isEmpty) continue;

      final allowCyclic = inputSignature.kind == GestureShapeKind.closed;
      final score = _distanceAtBestAngle(
        normalizedInput,
        normalizedTemplate,
        allowCyclicShift: allowCyclic,
      );
      scores.add((id: template.id, score: score));
    }

    if (scores.isEmpty) return null;

    scores.sort((a, b) => a.score.compareTo(b.score));
    final best = scores.first;
    if (best.score > _matchThreshold) return null;

    if (scores.length > 1) {
      final gap = scores[1].score - best.score;
      if (gap < 0.12) return null;
    }

    return GestureMatch(id: best.id, score: best.score);
  }

  /// Returns true when [input] is too similar to an existing saved shape.
  static bool isDuplicate(
    List<List<Offset>> input,
    List<({List<List<Offset>> strokes, GestureSignature signature})> templates,
  ) {
    if (input.isEmpty || templates.isEmpty) return false;

    final inputSignature = GestureSignature.fromStrokes(input);
    final normalizedInput = _normalizePoints(_flatten(input));
    if (normalizedInput.isEmpty) return false;

    for (final template in templates) {
      if (!inputSignature.isCompatibleWith(template.signature)) continue;

      final normalizedTemplate = _normalizePoints(_flatten(template.strokes));
      if (normalizedTemplate.isEmpty) continue;

      final score = _distanceAtBestAngle(
        normalizedInput,
        normalizedTemplate,
        allowCyclicShift: inputSignature.kind == GestureShapeKind.closed,
      );
      if (score <= _duplicateThreshold) return true;
    }
    return false;
  }

  static List<Offset> _flatten(List<List<Offset>> strokes) {
    final flat = <Offset>[];
    for (final stroke in strokes) {
      if (stroke.length >= 2) flat.addAll(stroke);
    }
    return flat;
  }

  static List<Offset> _normalizePoints(List<Offset> points) {
    if (points.length < 2) return const [];

    var resampled = _resample(points, _sampleCount);
    final angle = _indicativeAngle(resampled);
    resampled = _rotate(resampled, -angle);
    resampled = _scaleToSquare(resampled, _squareSize);
    resampled = _translateToOrigin(resampled);
    return resampled;
  }

  static double _distanceAtBestAngle(
    List<Offset> a,
    List<Offset> b, {
    required bool allowCyclicShift,
  }) {
    var best = double.infinity;

    for (var i = 0; i < 24; i++) {
      final rotated = _rotate(b, i * math.pi / 12);
      best = math.min(best, _pathDistance(a, rotated));
    }

    if (allowCyclicShift) {
      final step = math.max(1, _sampleCount ~/ 16);
      for (var shift = 0; shift < _sampleCount; shift += step) {
        final shifted = _cyclicallyShift(b, shift);
        for (var i = 0; i < 24; i++) {
          final rotated = _rotate(shifted, i * math.pi / 12);
          best = math.min(best, _pathDistance(a, rotated));
        }
      }
    }

    return best;
  }

  static List<Offset> _cyclicallyShift(List<Offset> points, int shift) {
    if (points.isEmpty || shift == 0) return points;
    final n = points.length;
    final s = shift % n;
    return [...points.sublist(s), ...points.sublist(0, s)];
  }

  static double _pathDistance(List<Offset> a, List<Offset> b) {
    final count = math.min(a.length, b.length);
    if (count == 0) return double.infinity;
    var total = 0.0;
    for (var i = 0; i < count; i++) {
      total += (a[i] - b[i]).distance;
    }
    return total / count;
  }

  static Offset _centroid(List<Offset> points) {
    var x = 0.0;
    var y = 0.0;
    for (final p in points) {
      x += p.dx;
      y += p.dy;
    }
    return Offset(x / points.length, y / points.length);
  }

  static double _indicativeAngle(List<Offset> points) {
    final c = _centroid(points);
    return math.atan2(c.dy - points.first.dy, c.dx - points.first.dx);
  }

  static List<Offset> _rotate(List<Offset> points, double radians) {
    final c = _centroid(points);
    final cos = math.cos(radians);
    final sin = math.sin(radians);
    return points
        .map((p) {
          final dx = p.dx - c.dx;
          final dy = p.dy - c.dy;
          return Offset(
            dx * cos - dy * sin + c.dx,
            dx * sin + dy * cos + c.dy,
          );
        })
        .toList(growable: false);
  }

  static List<Offset> _scaleToSquare(List<Offset> points, double size) {
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
    final scale = size / math.max(w, h).clamp(1e-6, double.infinity);
    final c = Offset((minX + maxX) / 2, (minY + maxY) / 2);

    return points
        .map((p) => Offset((p.dx - c.dx) * scale, (p.dy - c.dy) * scale))
        .toList(growable: false);
  }

  static List<Offset> _translateToOrigin(List<Offset> points) {
    final c = _centroid(points);
    return points.map((p) => p - c).toList(growable: false);
  }

  static List<Offset> _resample(List<Offset> points, int n) {
    if (points.length == 1) return List<Offset>.filled(n, points.first);

    final length = _pathLength(points);
    if (length == 0) return List<Offset>.filled(n, points.first);

    final interval = length / (n - 1);
    var dist = 0.0;
    final out = <Offset>[points.first];

    for (var i = 1; i < points.length; i++) {
      final seg = (points[i] - points[i - 1]).distance;
      if (seg == 0) continue;
      while (dist + seg >= interval && out.length < n) {
        final t = (interval - dist) / seg;
        final nx = points[i - 1].dx + t * (points[i].dx - points[i - 1].dx);
        final ny = points[i - 1].dy + t * (points[i].dy - points[i - 1].dy);
        out.add(Offset(nx, ny));
        dist = 0;
      }
      dist += seg;
    }

    while (out.length < n) {
      out.add(points.last);
    }
    return out;
  }

  static double _pathLength(List<Offset> points) {
    var length = 0.0;
    for (var i = 1; i < points.length; i++) {
      length += (points[i] - points[i - 1]).distance;
    }
    return length;
  }
}

class GestureMatch {
  const GestureMatch({required this.id, required this.score});

  final String id;
  final double score;
}
