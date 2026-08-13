import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/storage_keys.dart';
import '../model/gesture_shape.dart';

class GestureShapeStorage {
  Future<List<GestureShape>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(StorageKeys.gestureShapes);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => GestureShape.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> saveAll(List<GestureShape> shapes) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(shapes.map((s) => s.toJson()).toList());
    await prefs.setString(StorageKeys.gestureShapes, encoded);
  }
}
