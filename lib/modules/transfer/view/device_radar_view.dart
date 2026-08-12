import 'dart:math' as math;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../dashboard/model/picked_file_item.dart';
import '../controller/device_radar_controller.dart';
import '../model/transfer_device.dart';
import '../service/local_file_browser_service.dart';

class DeviceRadarView extends GetView<DeviceRadarController> {
  const DeviceRadarView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: Get.back,
        ),
        title: const Text('Devices'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert_rounded)),
        ],
      ),
      body: Obx(() {
        final isSending = controller.isSending.value;
        final hasFiles = controller.files.isNotEmpty;

        return Column(
          children: [
            const SizedBox(height: 8),
            _FilterChips(
              filter: controller.filter.value,
              peers: controller.allPeers,
              onChanged: controller.setFilter,
            ),
            Expanded(
              child: Stack(
                children: [
                  _RadarMap(
                    host: controller.hostDevice,
                    userEmail: controller.userEmail,
                    devices: controller.visibleDevices,
                    onDrop: controller.onFilesDroppedOnDevice,
                    allFiles: controller.files,
                    isSending: isSending,
                  ),
                  if (hasFiles && !isSending)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 28,
                      child: Center(
                        child: _DraggableFilesCard(files: controller.files.toList()),
                      ),
                    ),
                  if (isSending) _SendingOverlay(controller: controller),
                ],
              ),
            ),
            if (hasFiles) _FileStrip(controller: controller),
          ],
        );
      }),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.filter,
    required this.peers,
    required this.onChanged,
  });

  final DeviceFilter filter;
  final List<TransferDevice> peers;
  final ValueChanged<DeviceFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _Chip(
            label: 'All (${TransferDevice.countFor(DeviceFilter.all, peers)})',
            isSelected: filter == DeviceFilter.all,
            onTap: () => onChanged(DeviceFilter.all),
          ),
          const SizedBox(width: 8),
          _Chip(
            label:
                'My Devices (${TransferDevice.countFor(DeviceFilter.myDevices, peers)})',
            isSelected: filter == DeviceFilter.myDevices,
            onTap: () => onChanged(DeviceFilter.myDevices),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Nearby (${TransferDevice.countFor(DeviceFilter.nearby, peers)})',
            isSelected: filter == DeviceFilter.nearby,
            onTap: () => onChanged(DeviceFilter.nearby),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.brandIndigo,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: Responsive.sp(13),
      ),
      backgroundColor: AppColors.surface,
      side: BorderSide(color: isSelected ? AppColors.brandIndigo : AppColors.border),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }
}

class _RadarMap extends StatelessWidget {
  const _RadarMap({
    required this.host,
    required this.userEmail,
    required this.devices,
    required this.onDrop,
    required this.allFiles,
    required this.isSending,
  });

  final TransferDevice host;
  final String userEmail;
  final List<TransferDevice> devices;
  final Future<void> Function(TransferDevice, List<PickedFileItem>) onDrop;
  final List<PickedFileItem> allFiles;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final center = Offset(size.width / 2, size.height * 0.44);
        final maxRadius = math.min(size.width, size.height) * 0.42;

        return Stack(
          children: [
            CustomPaint(
              size: size,
              painter: _RadarRingsPainter(center: center, maxRadius: maxRadius),
            ),
            Positioned(
              left: center.dx - 60,
              top: center.dy - 68,
              child: _HostDevice(host: host, userEmail: userEmail),
            ),
            for (final device in devices)
              _PositionedDevice(
                device: device,
                center: center,
                maxRadius: maxRadius,
                onDrop: onDrop,
                allFiles: allFiles,
                enabled: !isSending,
              ),
          ],
        );
      },
    );
  }
}

class _RadarRingsPainter extends CustomPainter {
  _RadarRingsPainter({required this.center, required this.maxRadius});

  final Offset center;
  final double maxRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.brandIndigo.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(center, maxRadius * (i / 3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HostDevice extends StatelessWidget {
  const _HostDevice({required this.host, required this.userEmail});

  final TransferDevice host;
  final String userEmail;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sending from',
            style: TextStyle(
              fontSize: Responsive.sp(11),
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.brandIndigo, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandIndigo.withValues(alpha: 0.25),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(host.icon, color: host.color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            host.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Responsive.sp(13),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (userEmail.isNotEmpty)
            Text(
              userEmail,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Responsive.sp(10),
                color: AppColors.textSecondary,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            'ONLINE',
            style: TextStyle(
              fontSize: Responsive.sp(10),
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _PositionedDevice extends StatelessWidget {
  const _PositionedDevice({
    required this.device,
    required this.center,
    required this.maxRadius,
    required this.onDrop,
    required this.allFiles,
    required this.enabled,
  });

  final TransferDevice device;
  final Offset center;
  final double maxRadius;
  final Future<void> Function(TransferDevice, List<PickedFileItem>) onDrop;
  final List<PickedFileItem> allFiles;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final x = center.dx + math.cos(device.radarAngle) * maxRadius * device.radarRadius - 46;
    final y = center.dy + math.sin(device.radarAngle) * maxRadius * device.radarRadius - 50;

    return Positioned(
      left: x,
      top: y,
      child: _DeviceDropTarget(
        device: device,
        onDrop: onDrop,
        allFiles: allFiles,
        enabled: enabled,
      ),
    );
  }
}

class _DeviceDropTarget extends StatelessWidget {
  const _DeviceDropTarget({
    required this.device,
    required this.onDrop,
    required this.allFiles,
    required this.enabled,
  });

  final TransferDevice device;
  final Future<void> Function(TransferDevice, List<PickedFileItem>) onDrop;
  final List<PickedFileItem> allFiles;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isOnline = device.isOnline;

    return DragTarget<FileDragPayload>(
      onWillAcceptWithDetails: (_) => enabled && isOnline,
      onAcceptWithDetails: (details) => onDrop(device, details.data.files),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isHovering
                ? AppColors.brandIndigo.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: isHovering
                ? Border.all(color: AppColors.brandIndigo, width: 2)
                : null,
          ),
          child: Opacity(
            opacity: isOnline ? 1 : 0.35,
            child: SizedBox(
              width: 92,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isHovering ? AppColors.brandIndigo : AppColors.border,
                        width: isHovering ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(device.icon, color: device.color, size: 28),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    device.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Responsive.sp(11),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isOnline ? AppColors.success : AppColors.textHint,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          device.statusLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: Responsive.sp(9),
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DraggableFilesCard extends StatelessWidget {
  const _DraggableFilesCard({required this.files});

  final List<PickedFileItem> files;

  @override
  Widget build(BuildContext context) {
    final payload = FileDragPayload(files);
    final first = files.first;

    return Draggable<FileDragPayload>(
      data: payload,
      feedback: Material(
        color: Colors.transparent,
        child: _FilesCardContent(files: files, isDragging: true),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _FilesCardContent(files: files),
      ),
      child: _FilesCardContent(files: files, leading: first),
    );
  }
}

class _FilesCardContent extends StatelessWidget {
  const _FilesCardContent({
    required this.files,
    this.isDragging = false,
    this.leading,
  });

  final List<PickedFileItem> files;
  final bool isDragging;
  final PickedFileItem? leading;

  @override
  Widget build(BuildContext context) {
    final first = leading ?? files.first;
    final isImage = LocalFileBrowserService.isImage(first);

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          if (isDragging)
            BoxShadow(
              color: AppColors.brandIndigo.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.drag_indicator_rounded, color: AppColors.textHint, size: 22),
          const SizedBox(width: 8),
          Icon(
            isImage ? Icons.image_rounded : LocalFileBrowserService.iconFor(first),
            color: AppColors.brandIndigo,
            size: 22,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              files.length == 1
                  ? first.name
                  : '${files.length} files selected',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: Responsive.sp(14),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _FileStrip extends StatelessWidget {
  const _FileStrip({required this.controller});

  final DeviceRadarController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 34),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Drag files to a device',
            style: TextStyle(
              fontSize: Responsive.sp(20),
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Drop all ${controller.files.length} file${controller.files.length == 1 ? '' : 's'} together on an online device',
            style: TextStyle(
              fontSize: Responsive.sp(15),
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: controller.files.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final file = controller.files[index];
                final isImage = LocalFileBrowserService.isImage(file);
                final path = file.path;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isImage && path != null && path.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(path),
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            cacheWidth: 72,
                            cacheHeight: 72,
                            filterQuality: FilterQuality.low,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.broken_image_outlined,
                              size: 20,
                              color: AppColors.brandIndigo,
                            ),
                          ),
                        )
                      else
                        Icon(
                          LocalFileBrowserService.iconFor(file),
                          size: 20,
                          color: AppColors.brandIndigo,
                        ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 140),
                        child: Text(
                          file.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: Responsive.sp(13),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SendingOverlay extends StatelessWidget {
  const _SendingOverlay({required this.controller});

  final DeviceRadarController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.35),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Obx(() {
            final progress = controller.sendProgress.value;
            final count = controller.sendingFileCount.value;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: progress > 0 ? progress : null,
                    strokeWidth: 5,
                    color: AppColors.brandIndigo,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  count > 1 ? 'Sending files...' : 'Sending file...',
                  style: TextStyle(
                    fontSize: Responsive.sp(18),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  controller.sendingFileName.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Responsive.sp(14),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'To ${controller.sendingDestination.value}',
                  style: TextStyle(
                    fontSize: Responsive.sp(13),
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: controller.cancelSending,
                  child: const Text('Cancel'),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
