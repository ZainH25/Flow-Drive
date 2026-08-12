import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../model/picked_file_item.dart';

class QuickActionsService {
  QuickActionsService._();

  static final _imagePicker = ImagePicker();

  static Future<List<PickedFileItem>> pickFilesToSend() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: false,
      );
      if (result == null) return [];
      // Keep every returned file — do not drop items without a path on iOS.
      return result.files.map(PickedFileItem.fromPlatformFile).toList();
    } on PlatformException catch (e) {
      throw FilePickerException(
        e.message ?? 'Could not open the file picker on this device.',
      );
    }
  }

  static Future<List<PickedFileItem>> browseLocalFiles() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: false,
      );
      if (result == null) return [];
      return result.files.map(PickedFileItem.fromPlatformFile).toList();
    } on PlatformException catch (e) {
      throw FilePickerException(
        e.message ?? 'Could not open the file picker on this device.',
      );
    }
  }

  static Future<PickedFileItem?> captureImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image == null) return null;
    return PickedFileItem.fromXFile(image);
  }
}

class FilePickerException implements Exception {
  FilePickerException(this.message);

  final String message;

  @override
  String toString() => message;
} 
