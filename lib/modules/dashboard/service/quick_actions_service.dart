import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../model/picked_file_item.dart';

class QuickActionsService {
  QuickActionsService._();

  static final _imagePicker = ImagePicker();

  static Future<List<PickedFileItem>> pickFilesToSend() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
      withData: false,
    );
    if (result == null) return [];
    return result.files.map(PickedFileItem.fromPlatformFile).toList();
  }

  static Future<List<PickedFileItem>> browseLocalFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
      withData: false,
    );
    if (result == null) return [];
    return result.files.map(PickedFileItem.fromPlatformFile).toList();
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
