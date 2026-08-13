import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../file_map/service/file_map_filesystem_service.dart';
import '../model/gesture_shape.dart';
import '../service/gesture_recognizer.dart';
import '../service/gesture_shape_storage.dart';
import '../service/gesture_signature.dart';

class GestureShapesController extends GetxController {
  GestureShapesController({
    GestureShapeStorage? storage,
    FileMapFileSystemService? filesystem,
  })  : _storage = storage ?? GestureShapeStorage(),
        _filesystem = filesystem ?? FileMapFileSystemService();

  final GestureShapeStorage _storage;
  final FileMapFileSystemService _filesystem;

  final shapes = <GestureShape>[].obs;
  final statusMessage = RxnString();
  final openedItemLabel = RxnString();

  final draftStrokes = <List<Offset>>[].obs;
  final currentStroke = <Offset>[].obs;
  final draftNameController = TextEditingController();
  final editingShapeId = RxnString();

  @override
  void onInit() {
    super.onInit();
    reloadShapes();
  }

  @override
  void onClose() {
    draftNameController.dispose();
    super.onClose();
  }

  Future<void> reloadShapes() async {
    shapes.assignAll(await _storage.loadAll());
  }

  void beginStroke(Offset point) {
    unfocusKeyboard();
    currentStroke.assignAll([point]);
  }

  void extendStroke(Offset point) {
    if (currentStroke.isEmpty) {
      beginStroke(point);
      return;
    }
    currentStroke.add(point);
    currentStroke.refresh();
  }

  void endStroke() {
    if (currentStroke.length < 2) {
      currentStroke.clear();
      return;
    }
    draftStrokes.add(List<Offset>.from(currentStroke));
    currentStroke.clear();
    draftStrokes.refresh();
  }

  void clearDraft() {
    draftStrokes.clear();
    currentStroke.clear();
    draftStrokes.refresh();
    currentStroke.refresh();
    statusMessage.value = null;
  }

  List<List<Offset>> get activeStrokes {
    final all = <List<Offset>>[...draftStrokes];
    if (currentStroke.length >= 2) {
      all.add(List<Offset>.from(currentStroke));
    }
    return all;
  }

  List<List<Offset>> _inputForMatch() {
    final input = _cloneStrokes(draftStrokes);
    if (currentStroke.length >= 2) {
      input.add(List<Offset>.from(currentStroke));
    }
    return input;
  }

  void unfocusKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  bool get isEditing => editingShapeId.value != null;

  void cancelEditing() {
    editingShapeId.value = null;
    draftNameController.clear();
    clearDraft();
  }

  void startEditingShape(GestureShape shape) {
    editingShapeId.value = shape.id;
    draftNameController.text = shape.name;
    draftStrokes.assignAll(shape.cloneStrokes());
    draftStrokes.refresh();
    statusMessage.value = 'Editing “${shape.name}”. Redraw or rename, then tap Save.';
  }

  Future<void> saveDraftShape() async {
    unfocusKeyboard();
    if (isEditing) {
      await updateEditingShape();
      return;
    }
    await pickFileAndSaveShape(name: draftNameController.text);
    draftNameController.clear();
    unfocusKeyboard();
  }

  Future<void> updateEditingShape() async {
    final id = editingShapeId.value;
    if (id == null) return;

    if (draftStrokes.isEmpty) {
      Get.snackbar('Draw a shape', 'Sketch your gesture on the canvas first.');
      return;
    }

    final strokes = _cloneStrokes(draftStrokes);
    final existing = shapes
        .where((s) => s.id != id)
        .map((s) => (strokes: s.strokes, signature: s.signature))
        .toList(growable: false);

    if (GestureRecognizer.isDuplicate(strokes, existing)) {
      Get.snackbar(
        'Shape already used',
        'Another saved gesture already looks like this.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final index = shapes.indexWhere((s) => s.id == id);
    if (index < 0) return;

    final previous = shapes[index];
    final signature = GestureSignature.fromStrokes(strokes);
    final updated = GestureShape(
      id: previous.id,
      name: draftNameController.text.trim().isEmpty
          ? previous.name
          : draftNameController.text.trim(),
      filePath: previous.filePath,
      fileName: previous.fileName,
      strokes: strokes,
      signature: signature,
    );

    shapes[index] = updated;
    await _storage.saveAll(shapes);
    shapes.refresh();
    cancelEditing();
    statusMessage.value = 'Updated “${updated.name}”.';
  }

  Future<void> changeShapeFile(String id) async {
    final index = shapes.indexWhere((s) => s.id == id);
    if (index < 0) return;

    unfocusKeyboard();
    final picked = await FilePicker.pickFiles(
      dialogTitle: 'Choose new file for this gesture',
      allowMultiple: false,
      withData: false,
    );
    final file = picked?.files.single;
    final path = file?.path;
    if (path == null || path.isEmpty) return;

    final previous = shapes[index];
    shapes[index] = GestureShape(
      id: previous.id,
      name: previous.name,
      filePath: path,
      fileName: file?.name ?? 'File',
      strokes: previous.strokes,
      signature: previous.signature,
    );
    await _storage.saveAll(shapes);
    shapes.refresh();
    statusMessage.value = 'Linked “${shapes[index].name}” to a new file.';
  }

  void dismissOpenedItem() {
    openedItemLabel.value = null;
  }

  void _markOpened(String label) {
    openedItemLabel.value = label;
  }

  Future<void> pickFileAndSaveShape({required String name}) async {
    if (draftStrokes.isEmpty) {
      Get.snackbar('Draw a shape', 'Sketch your gesture on the canvas first.');
      return;
    }

    unfocusKeyboard();

    final strokes = _cloneStrokes(draftStrokes);
    final existing = shapes
        .map((s) => (strokes: s.strokes, signature: s.signature))
        .toList(growable: false);

    if (GestureRecognizer.isDuplicate(strokes, existing)) {
      Get.snackbar(
        'Shape already used',
        'This gesture is already linked to a file. Draw a different shape.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final picked = await FilePicker.pickFiles(
      dialogTitle: 'Choose file for this gesture',
      allowMultiple: false,
      withData: false,
    );
    final file = picked?.files.single;
    final path = file?.path;
    if (path == null || path.isEmpty) return;

    final signature = GestureSignature.fromStrokes(strokes);

    final shape = GestureShape(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim().isEmpty ? 'My shape' : name.trim(),
      filePath: path,
      fileName: file?.name ?? 'File',
      strokes: strokes,
      signature: signature,
    );

    shapes.add(shape);
    await _storage.saveAll(shapes);
    clearDraft();
    statusMessage.value =
        'Saved “${shape.name}” (${shape.kindLabel}). Draw it in File Map → Gesture to open.';
  }

  Future<void> deleteShape(String id) async {
    shapes.removeWhere((s) => s.id == id);
    await _storage.saveAll(shapes);
  }

  Future<void> openShapeFile(GestureShape shape) async {
    try {
      await _filesystem.revealInSystemFileManager(shape.filePath);
      statusMessage.value = 'Opened “${shape.fileName}”.';
      _markOpened(shape.fileName);
    } catch (e) {
      Get.snackbar(
        'Cannot open file',
        e is Exception ? e.toString() : 'Could not open that file.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> tryMatchAndOpen({bool clearOnMiss = true}) async {
    await reloadShapes();

    final input = _inputForMatch();
    if (input.isEmpty) return;

    final templates = shapes
        .map((s) => (id: s.id, strokes: s.strokes, signature: s.signature))
        .toList(growable: false);

    final match = GestureRecognizer.bestMatch(input, templates);
    if (match == null) {
      if (clearOnMiss) {
        Get.snackbar(
          'No match',
          shapes.isEmpty
              ? 'Add shapes in Profile → Gesture Shapes first.'
              : 'Draw the same shape you saved (circle, square, or line).',
          snackPosition: SnackPosition.BOTTOM,
        );
        clearDraft();
      }
      return;
    }

    final shape = shapes.firstWhereOrNull((s) => s.id == match.id);
    if (shape == null) return;

    try {
      await _filesystem.revealInSystemFileManager(shape.filePath);
      statusMessage.value = 'Opened “${shape.fileName}”.';
      _markOpened(shape.fileName);
    } catch (e) {
      Get.snackbar(
        'Cannot open file',
        e is Exception ? e.toString() : 'Could not open that file.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      clearDraft();
    }
  }

  List<List<Offset>> _cloneStrokes(List<List<Offset>> source) {
    return source.map((s) => List<Offset>.from(s)).toList(growable: false);
  }
}
