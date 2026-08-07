import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/asset_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/greeting_utils.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/controller/auth_controller.dart';
import '../../controller/home_controller.dart';
import '../widgets/quick_actions_section.dart';

class HomeTab extends GetView<HomeController> {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Obx(() {
      final user = auth.user.value;
      final displayName = user?.username ?? user?.email.split('@').first ?? 'User';
      final avatarName = user?.username ?? user?.email ?? 'User';

      final content = ListView(
        padding: Responsive.pagePadding.copyWith(bottom: 100),
        children: [
          _GreetingChip(displayName: displayName),
          const SizedBox(height: 20),
          _StorageCard(controller: controller),
          const SizedBox(height: 28),
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: Responsive.sp(18),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          const QuickActionsSection(),
          const SizedBox(height: 28),
          _SectionHeader(title: 'Connected Devices', onViewAll: () {}),
          const SizedBox(height: 14),
          _DevicesGrid(devices: controller.devices),
          const SizedBox(height: 28),
          _SectionHeader(title: 'Recent Transfers', onViewAll: () {}),
          const SizedBox(height: 14),
          _TransfersList(transfers: controller.transfers),
        ],
      );

      if (Responsive.isDesktop) {
        return ColoredBox(
          color: AppColors.background,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth),
              child: content,
            ),
          ),
        );
      }

      return Scaffold(
        backgroundColor: AppColors.background,
        // appBar: AppBar(
        //   scrolledUnderElevation:0,
        //   centerTitle: true,
        //   titleSpacing: 0,
        //   title: Row(
        //     mainAxisSize: MainAxisSize.min, //
        //     children: [
        //       const SizedBox(width: 4),
        //       ClipRRect(
        //         borderRadius: BorderRadius.circular(10),
        //         child: Image.asset(
        //           AssetPaths.logo,
        //           width: 32,
        //           height: 32,
        //           fit: BoxFit.cover,
        //           errorBuilder: (context, error, stackTrace) => Container(
        //             width: 32,
        //             height: 32,
        //             color: AppColors.brandIndigo,
        //             child: const Icon(Icons.hub_rounded, color: Colors.white, size: 18),
        //           ),
        //         ),
        //       ),
        //       const SizedBox(width: 0),
        //       const Text('Home', style: TextStyle(fontWeight: FontWeight.w700) , textAlign: TextAlign.center),
        //     ],
        //   ),
        //   actions: [
        //     IconButton(
        //       onPressed: () {},
        //       icon: const Icon(Icons.search_rounded),
        //     ),

        //     IconButton(
        //       onPressed: () {},
        //       icon: const Icon(Icons.notifications_rounded),
        //     ),

        //     Padding(
        //       padding: const EdgeInsets.only(right: 12),
        //       child: CircleAvatar(
        //         radius: 18,
        //         backgroundColor: AppColors.brandIndigo.withValues(alpha: 0.15),
        //         child: Text(
        //           avatarName.isNotEmpty ? avatarName[0].toUpperCase() : 'U',
        //           style: const TextStyle(
        //             color: AppColors.brandIndigo,
        //             fontWeight: FontWeight.bold,
        //           ),
        //         ),
        //       ),
        //     ),
        //   ],
        // ),

        appBar: AppBar(
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleSpacing: 0,
          
          // 1. Logo moved to 'leading' (far left edge)
          leading: Padding(
            padding: const EdgeInsets.only(left: 10), // Kept your 4px spacing
            child: Center( // Center prevents the AppBar from stretching the 32x32 image
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  AssetPaths.logo,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 32,
                    height: 32,
                    color: AppColors.brandIndigo,
                    child: const Icon(Icons.hub_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
          ),

          // 2. Text remains in 'title' to be perfectly centered
          title: const Text(
            'Home', 
            style: TextStyle(fontWeight: FontWeight.w700), 
            textAlign: TextAlign.center
          ),
          
          // 3. Actions remain completely untouched
          actions: [
            // IconButton(
            //   onPressed: () {},
            //   icon: const Icon(Icons.search_rounded),
            // ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_rounded),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.brandIndigo.withValues(alpha: 0.15),
                child: Text(
                  avatarName.isNotEmpty ? avatarName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: AppColors.brandIndigo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth),
            child: content,
          ),
        ),
      );
    });
  }
}

class _GreetingChip extends StatelessWidget {
  const _GreetingChip({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = GreetingUtils.greetingFor(now);
    final emoji = GreetingUtils.greetingEmojiFor(now);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brandIndigo.withValues(alpha: 0.12),
            AppColors.brandPurple.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.infoBannerBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: Responsive.sp(18))),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              '$greeting, $displayName',
              style: TextStyle(
                fontSize: Responsive.sp(20),
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StorageCard extends StatelessWidget {
  const _StorageCard({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = controller.isLoadingStorage.value;
      final error = controller.storageError.value;
      final percent = controller.usedPercent;

      return Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF4F6FF), Color(0xFFEEF2FF)],
          ),
          borderRadius: BorderRadius.circular(Responsive.radius(24)),
          border: Border.all(color: AppColors.infoBannerBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandIndigo.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Device Storage',
                    style: TextStyle(
                      fontSize: Responsive.sp(18),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: controller.loadDeviceStorage,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  color: AppColors.textLink,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            if (error != null) ...[
              Text(
                error,
                style: TextStyle(
                  fontSize: Responsive.sp(13),
                  color: AppColors.error,
                ),
              ),
            ] else if (isLoading) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(
                minHeight: 8,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$percent% used',
                    style: TextStyle(
                      fontSize: Responsive.sp(14),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${controller.storageUsedLabel.value} of ${controller.storageTotalLabel.value}',
                    style: TextStyle(
                      fontSize: Responsive.sp(13),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: controller.storagePercent.value,
                  minHeight: 10,
                  backgroundColor: AppColors.brandIndigo.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation(AppColors.brandIndigo),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _StorageStat(
                      label: 'Used',
                      value: controller.storageUsedLabel.value,
                    ),
                  ),
                  Expanded(
                    child: _StorageStat(
                      label: 'Free',
                      value: controller.storageFreeLabel.value,
                      alignCenter: true,
                    ),
                  ),
                  Expanded(
                    child: _StorageStat(
                      label: 'Total',
                      value: controller.storageTotalLabel.value,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _StorageStat extends StatelessWidget {
  const _StorageStat({
    required this.label,
    required this.value,
    this.alignEnd = false,
    this.alignCenter = false,
  });

  final String label;
  final String value;
  final bool alignEnd;
  final bool alignCenter;

  @override
  Widget build(BuildContext context) {
    final alignment = alignEnd
        ? CrossAxisAlignment.end
        : alignCenter
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: Responsive.sp(13),
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: Responsive.sp(16),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onViewAll});

  final String title;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: Responsive.sp(18),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        TextButton(
          onPressed: onViewAll,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'View all',
            style: TextStyle(
              color: AppColors.textLink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _DevicesGrid extends StatelessWidget {
  const _DevicesGrid({required this.devices});

  final List<HomeDevice> devices;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.45,
      children: [
        for (final device in devices) _DeviceCard(device: device),
        const _AddDeviceCard(),
      ],
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device});

  final HomeDevice device;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FF),
        borderRadius: BorderRadius.circular(Responsive.radius(16)),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: device.iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(device.icon, color: device.iconColor, size: 20),
          ),
          const Spacer(),
          Text(
            device.name,
            style: TextStyle(
              fontSize: Responsive.sp(13),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Online',
                style: TextStyle(
                  fontSize: Responsive.sp(12),
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddDeviceCard extends StatelessWidget {
  const _AddDeviceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Responsive.radius(16)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.brandIndigo.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_rounded,
              color: AppColors.brandIndigo,
              size: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add Device',
            style: TextStyle(
              fontSize: Responsive.sp(13),
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransfersList extends StatelessWidget {
  const _TransfersList({required this.transfers});

  final List<HomeTransfer> transfers;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Responsive.radius(20)),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < transfers.length; i++) ...[
            _TransferRow(transfer: transfers[i]),
            if (i < transfers.length - 1)
              Divider(
                height: 1,
                indent: 72,
                color: AppColors.border.withValues(alpha: 0.7),
              ),
          ],
        ],
      ),
    );
  }
}

class _TransferRow extends StatelessWidget {
  const _TransferRow({required this.transfer});

  final HomeTransfer transfer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: transfer.iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(transfer.icon, color: transfer.iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transfer.name,
                  style: TextStyle(
                    fontSize: Responsive.sp(14),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  transfer.subtitle,
                  style: TextStyle(
                    fontSize: Responsive.sp(12),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            transfer.time,
            style: TextStyle(
              fontSize: Responsive.sp(12),
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
