import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../controller/transfer_complete_controller.dart';
import '../model/transfer_device.dart';

class TransferCompleteView extends GetView<TransferCompleteController> {
  const TransferCompleteView({super.key});

  @override
  Widget build(BuildContext context) {
    final result = controller.result;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transfer Details'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_outlined)),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: Responsive.pagePadding,
              children: [
                const SizedBox(height: 16),
                const Center(child: _SuccessIcon()),
                const SizedBox(height: 20),
                Text(
                  'Transfer Complete!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Responsive.sp(24),
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.fileCount > 1
                      ? '${result.fileCount} files delivered successfully'
                      : 'Your file has been successfully delivered.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Responsive.sp(14),
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                _DestinationCard(result: result),
                const SizedBox(height: 20),
                Text(
                  'Transferred Files',
                  style: TextStyle(
                    fontSize: Responsive.sp(16),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < result.files.length; i++) ...[
                  _FileDetailCard(file: result.files[i], index: i + 1),
                  if (i < result.files.length - 1) const SizedBox(height: 12),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
          Padding(
            padding: Responsive.pagePadding.copyWith(bottom: 24),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: controller.onDone,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandIndigo,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: controller.onSendAnother,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brandIndigo,
                      side: const BorderSide(color: AppColors.brandIndigo),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Send Another',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessIcon extends StatelessWidget {
  const _SuccessIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.brandIndigo.withValues(alpha: 0.1),
      ),
      child: Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppColors.brandIndigo,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
        ),
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({required this.result});

  final TransferResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.infoBannerFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.infoBannerBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.brandIndigo.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(result.destinationIcon, color: AppColors.brandIndigo),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sent to',
                  style: TextStyle(
                    fontSize: Responsive.sp(12),
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  result.destinationName,
                  style: TextStyle(
                    fontSize: Responsive.sp(16),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${result.fileCount} file${result.fileCount == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: Responsive.sp(13),
              fontWeight: FontWeight.w600,
              color: AppColors.brandIndigo,
            ),
          ),
        ],
      ),
    );
  }
}

class _FileDetailCard extends StatelessWidget {
  const _FileDetailCard({required this.file, required this.index});

  final TransferredFileDetail file;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brandIndigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(file.icon, color: AppColors.brandIndigo, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'File $index',
                  style: TextStyle(
                    fontSize: Responsive.sp(12),
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandIndigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Success',
                  style: TextStyle(
                    color: AppColors.brandIndigo,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DetailRow(label: 'File Name', value: file.fileName),
          const Divider(height: 20),
          _DetailRow(label: 'Size', value: file.fileSizeLabel),
          if (file.extension != null) ...[
            const Divider(height: 20),
            _DetailRow(label: 'Type', value: file.extension!.toUpperCase()),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: Responsive.sp(13),
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: Responsive.sp(13),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
