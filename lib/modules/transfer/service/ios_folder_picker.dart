import 'package:flutter/services.dart';

/// Shared iOS folder picker — mirrors the chosen folder into app cache so
/// Dart Directory APIs can list PDFs, images, and other files like Android.
class IosFolderPicker {
  IosFolderPicker._();

  static const _channel = MethodChannel('flow_drive/ios_folder_access');

  /// Returns mirrored folder path + display name, or null if cancelled.
  static Future<({String path, String name})?> pickFolder() async {
    try {
      final raw = await _channel.invokeMethod<dynamic>('pickFolder');
      if (raw == null || raw is! Map) return null;

      final path = raw['path']?.toString();
      final name = raw['name']?.toString();
      if (path == null || path.isEmpty) return null;

      return (
        path: path,
        name: (name != null && name.isNotEmpty) ? name : path.split('/').last,
      );
    } on MissingPluginException {
      rethrow;
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Could not open the folder picker.');
    }
  }
}
