import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class PickedFileItem {
  const PickedFileItem({
    required this.name,
    required this.path,
    required this.size,
    required this.addedAt,
    this.extension,
  });

  final String name;
  final String? path;
  final int? size;
  final String? extension;
  final DateTime addedAt;

  factory PickedFileItem.fromPlatformFile(PlatformFile file) {
    return PickedFileItem(
      name: file.name,
      path: file.path,
      size: file.size,
      extension: file.extension,
      addedAt: DateTime.now(),
    );
  }

  factory PickedFileItem.fromXFile(XFile file) {
    final name = file.name;
    final dot = name.lastIndexOf('.');
    return PickedFileItem(
      name: name,
      path: file.path,
      size: null,
      extension: dot == -1 ? null : name.substring(dot + 1),
      addedAt: DateTime.now(),
    );
  }

  String get sizeLabel => formatFileSize(size);

  static String formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return 'Unknown size';
    const units = ['B', 'KB', 'MB', 'GB'];
    var value = bytes.toDouble();
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    final precision = unit == 0 ? 0 : 1;
    return '${value.toStringAsFixed(precision)} ${units[unit]}';
  }
}
