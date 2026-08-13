import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/opened_path_banner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../controller/gesture_shapes_controller.dart';
import '../model/gesture_shape.dart';
import '../widgets/gesture_draw_canvas.dart';
import '../widgets/gesture_shape_preview.dart';

/// Profile → Gesture Shapes screen.
/// File: [flow_drive/lib/modules/gesture_shapes/view/gesture_shapes_view.dart]
class GestureShapesView extends GetView<GestureShapesController> {
  const GestureShapesView({super.key});

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final canvasHeight = keyboardOpen
        ? 130.0
        : (MediaQuery.sizeOf(context).height * 0.2).clamp(150.0, 190.0);
    final pagePadding = Responsive.pagePadding;

    return GestureDetector(
      onTap: controller.unfocusKeyboard,
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text('Gesture Shapes'),
          actions: [
            Obx(() {
              if (!controller.isEditing &&
                  controller.draftStrokes.isEmpty &&
                  controller.currentStroke.isEmpty) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: controller.isEditing ? controller.cancelEditing : controller.clearDraft,
                child: Text(controller.isEditing ? 'Cancel' : 'Clear'),
              );
            }),
          ],
        ),
        body: Column(
          children: [
            Obx(() {
              final label = controller.openedItemLabel.value;
              if (label == null) return const SizedBox.shrink();
              return OpenedPathBanner(
                label: label,
                onDismiss: controller.dismissOpenedItem,
              );
            }),
            // Draw pad lives OUTSIDE the scroll view so horizontal strokes never scroll the page.
            Padding(
              padding: pagePadding.copyWith(top: 12, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Obx(() {
                    if (!controller.isEditing) {
                      return Text(
                        'Record a shape and link it to a file. Then draw it in File Map → Gesture.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: Responsive.sp(13),
                          height: 1.4,
                        ),
                      );
                    }
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.brandIndigo.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.brandIndigo.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        'Editing shape — redraw or rename, then tap Save below.',
                        style: TextStyle(
                          color: AppColors.brandIndigo,
                          fontSize: Responsive.sp(13),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  Text(
                    'New shape',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: Responsive.sp(16),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: canvasHeight,
                    child: GestureDrawCanvas(controller: controller),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Shape name',
                      hintText: 'e.g. Circle for invoices',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    controller: controller.draftNameController,
                    textInputAction: TextInputAction.done,
                    onTapOutside: (_) => controller.unfocusKeyboard(),
                    onSubmitted: (_) => controller.unfocusKeyboard(),
                  ),
                  Obx(() {
                    final message = controller.statusMessage.value;
                    if (message == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        message,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: Responsive.sp(12),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Padding(
              padding: pagePadding.copyWith(top: 4, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Saved shapes',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: Responsive.sp(16),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.shapes.isEmpty) {
                  return Center(
                    child: Text(
                      'No shapes saved yet.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: Responsive.sp(13),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: pagePadding.copyWith(bottom: 16),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: controller.shapes.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final shape = controller.shapes[index];
                    return _ShapeTile(
                      shape: shape,
                      onDelete: () => controller.deleteShape(shape.id),
                      onOpen: () => controller.openShapeFile(shape),
                      onEdit: () => controller.startEditingShape(shape),
                      onChangeFile: () => controller.changeShapeFile(shape.id),
                    );
                  },
                );
              }),
            ),
          ],
        ),
        bottomNavigationBar: Obx(
          () => Material(
            elevation: 8,
            color: AppColors.surface,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: FilledButton.icon(
                  onPressed: () => controller.saveDraftShape(),
                  icon: Icon(
                    controller.isEditing ? Icons.check_rounded : Icons.save_outlined,
                  ),
                  label: Text(
                    controller.isEditing ? 'Save changes' : 'Pick file & save shape',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShapeTile extends StatelessWidget {
  const _ShapeTile({
    required this.shape,
    required this.onDelete,
    required this.onOpen,
    required this.onEdit,
    required this.onChangeFile,
  });

  final GestureShape shape;
  final VoidCallback onDelete;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onChangeFile;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Responsive.radius(14)),
        side: const BorderSide(color: AppColors.border),
      ),
      child: GestureDetector(
        onLongPressStart: (_) => GestureShapePreviewOverlay.show(context, shape),
        onLongPressEnd: (_) => GestureShapePreviewOverlay.dismiss(),
        onTap: onEdit,
        child: InkWell(
          borderRadius: BorderRadius.circular(Responsive.radius(14)),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                GestureShapeThumbnail(strokes: shape.strokes),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shape.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${shape.kindLabel} · ${shape.displayFileName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: Responsive.sp(12),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'file') onChangeFile();
                    if (value == 'open') onOpen();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit shape')),
                    PopupMenuItem(value: 'file', child: Text('Change linked file')),
                    PopupMenuItem(value: 'open', child: Text('Open in local storage')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
