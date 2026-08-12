import 'package:flutter/material.dart';

import '../../dashboard/model/picked_file_item.dart';

class LocalFileFolder {
  const LocalFileFolder({
    required this.name,
    required this.path,
    required this.icon,
  });

  final String name;
  final String path;
  final IconData icon;
}

class LocalBrowseResult {
  const LocalBrowseResult({
    required this.folders,
    required this.files,
  });

  final List<LocalFileFolder> folders;
  final List<PickedFileItem> files;
}
