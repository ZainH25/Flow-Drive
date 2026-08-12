enum GraphNodeType { folder, file }

enum GraphFileKind {
  pdf,
  image,
  video,
  audio,
  doc,
  sheet,
  slide,
  text,
  file,
}

class FileGraphNode {
  const FileGraphNode({
    required this.id,
    required this.name,
    required this.type,
    required this.path,
  });

  final String id;
  final String name;
  final GraphNodeType type;
  final String path;

  bool get isFolder => type == GraphNodeType.folder;
  bool get isFile => type == GraphNodeType.file;
}

class GraphLayoutNode {
  GraphLayoutNode({
    required this.node,
    required this.parentId,
    required this.level,
    this.x = 0,
    this.y = 0,
    this.loaded = false,
    this.loading = false,
    List<String>? childIds,
    this.childCount,
  }) : childIds = childIds ?? <String>[];

  final FileGraphNode node;
  final String? parentId;
  final int level;
  double x;
  double y;
  bool loaded;
  bool loading;
  List<String> childIds;
  int? childCount;

  String get id => node.id;
  bool get isRoot => parentId == null;
}

GraphFileKind graphFileKind(String name) {
  final ext = name.split('.').last.toLowerCase();
  if (ext == name.toLowerCase()) return GraphFileKind.file;
  if (ext == 'pdf') return GraphFileKind.pdf;
  if (['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'heic', 'heif'].contains(ext)) {
    return GraphFileKind.image;
  }
  if (['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'].contains(ext)) return GraphFileKind.video;
  if (['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'].contains(ext)) return GraphFileKind.audio;
  if (['doc', 'docx'].contains(ext)) return GraphFileKind.doc;
  if (['xls', 'xlsx', 'csv'].contains(ext)) return GraphFileKind.sheet;
  if (['ppt', 'pptx'].contains(ext)) return GraphFileKind.slide;
  if (['txt', 'md', 'json', 'log'].contains(ext)) return GraphFileKind.text;
  return GraphFileKind.file;
}

String graphKindEmoji(GraphFileKind kind) {
  return switch (kind) {
    GraphFileKind.pdf => '📕',
    GraphFileKind.image => '🖼️',
    GraphFileKind.video => '🎬',
    GraphFileKind.audio => '🎵',
    GraphFileKind.doc => '📘',
    GraphFileKind.sheet => '📗',
    GraphFileKind.slide => '📙',
    GraphFileKind.text => '📄',
    GraphFileKind.file => '📄',
  };
}

String shortGraphLabel(String name, {int maxChars = 14}) {
  final dot = name.lastIndexOf('.');
  final hasExt = dot > 0 && dot > name.length - 8;
  final base = hasExt ? name.substring(0, dot) : name;
  final ext = hasExt ? name.substring(dot) : '';
  if (base.length + ext.length <= maxChars) return name;
  final keep = (maxChars - ext.length - 1).clamp(4, maxChars);
  return '${base.substring(0, keep)}…$ext';
}
