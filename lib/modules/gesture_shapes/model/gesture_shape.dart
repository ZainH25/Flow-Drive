import 'dart:ui';

import '../service/gesture_signature.dart';

class GestureShape {
  const GestureShape({
    required this.id,
    required this.name,
    required this.filePath,
    required this.fileName,
    required this.strokes,
    required this.signature,
  });

  final String id;
  final String name;
  final String filePath;
  final String fileName;
  final List<List<Offset>> strokes;
  final GestureSignature signature;

  String get kindLabel =>
      signature.kind == GestureShapeKind.line ? 'Line' : 'Closed shape';

  String get displayFileName {
    final raw = fileName.isNotEmpty ? fileName : filePath.split('/').last;
    try {
      return Uri.decodeComponent(raw);
    } catch (_) {
      return raw;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'filePath': filePath,
        'fileName': fileName,
        'kind': signature.kind.name,
        'lineScore': signature.lineScore,
        'circularity': signature.circularity,
        'strokes': strokes
            .map(
              (stroke) => stroke
                  .map((p) => {'dx': p.dx, 'dy': p.dy})
                  .toList(growable: false),
            )
            .toList(growable: false),
      };

  factory GestureShape.fromJson(Map<String, dynamic> json) {
    final strokes = _parseStrokes(json);
    // Always recompute signature from strokes so matching stays accurate.
    final signature = GestureSignature.fromStrokes(strokes);

    return GestureShape(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Shape',
      filePath: json['filePath'] as String,
      fileName: json['fileName'] as String? ?? 'File',
      strokes: strokes,
      signature: signature,
    );
  }

  static List<List<Offset>> _parseStrokes(Map<String, dynamic> json) {
    final rawStrokes = json['strokes'] as List<dynamic>? ?? const [];
    final strokes = <List<Offset>>[];
    for (final stroke in rawStrokes) {
      final points = <Offset>[];
      for (final point in stroke as List<dynamic>) {
        final map = point as Map<String, dynamic>;
        points.add(Offset((map['dx'] as num).toDouble(), (map['dy'] as num).toDouble()));
      }
      strokes.add(points);
    }
    return strokes;
  }

  List<List<Offset>> cloneStrokes() {
    return strokes.map((stroke) => List<Offset>.from(stroke)).toList(growable: false);
  }
}
