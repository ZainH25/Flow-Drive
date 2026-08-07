import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../controller/home_controller.dart';

class QuickActionsSection extends GetView<HomeController> {
  const QuickActionsSection({super.key});

  static const _actions = [
    _QuickAction(
      label: 'Send Files',
      icon: Icons.upload_file_rounded,
      color: Color(0xFF4D49FF),
      action: _QuickActionType.send,
    ),
    _QuickAction(
      label: 'Receive Files',
      icon: Icons.download_rounded,
      color: Color(0xFF00BFA5),
      action: _QuickActionType.receive,
    ),
    _QuickAction(
      label: 'Browse File',
      icon: Icons.folder_open_rounded,
      color: Color(0xFF1976D2),
      action: _QuickActionType.browse,
    ),
    _QuickAction(
      label: 'Scan Images',
      icon: Icons.photo_camera_rounded,
      color: Color(0xFF7E57C2),
      action: _QuickActionType.scan,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        for (final action in _actions)
          _QuickActionCard(
            action: action,
            onTap: () => _handleAction(action.action),
          ),
      ],
    );
  }

  void _handleAction(_QuickActionType type) {
    switch (type) {
      case _QuickActionType.send:
        controller.sendFiles();
      case _QuickActionType.receive:
        controller.receiveFiles();
      case _QuickActionType.browse:
        controller.browseFiles();
      case _QuickActionType.scan:
        controller.scanImage();
    }
  }
}

enum _QuickActionType { send, receive, browse, scan }

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.action,
  });

  final String label;
  final IconData icon;
  final Color color;
  final _QuickActionType action;
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.action,
    required this.onTap,
  });

  final _QuickAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(Responsive.radius(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Responsive.radius(16)),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Responsive.radius(16)),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(action.icon, color: action.color, size: 20),
              ),
              const Spacer(),
              Text(
                action.label,
                style: TextStyle(
                  fontSize: Responsive.sp(13),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
