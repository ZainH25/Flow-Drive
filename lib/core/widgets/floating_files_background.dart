import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// File & send icons drifting bottom-left → top-right behind auth screens.
class FloatingFilesBackground extends StatefulWidget {
  const FloatingFilesBackground({super.key, this.opacity = 1});

  final double opacity;

  @override
  State<FloatingFilesBackground> createState() => _FloatingFilesBackgroundState();
}

class _FloatingFilesBackgroundState extends State<FloatingFilesBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_DriftIcon> _icons;

  static const _iconSet = [
    Icons.send_rounded,
    Icons.near_me_rounded,
    Icons.upload_file_rounded,
    Icons.description_outlined,
    Icons.insert_drive_file_outlined,
    Icons.folder_outlined,
    Icons.image_outlined,
    Icons.cloud_upload_outlined,
  ];

  @override
  void initState() {
    super.initState();
    final random = math.Random(7);
    _icons = List.generate(18, (i) {
      return _DriftIcon(
        icon: _iconSet[i % _iconSet.length],
        progress: random.nextDouble(),
        lane: (random.nextDouble() - 0.5) * 0.35,
        size: 18 + random.nextDouble() * 16,
        speed: 0.06 + random.nextDouble() * 0.1,
        fade: 0.12 + random.nextDouble() * 0.18,
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (final item in _icons)
                  _buildIcon(item, w, h),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildIcon(_DriftIcon item, double w, double h) {
    final t = (item.progress + _controller.value * item.speed) % 1.0;
    const travel = 1.35;
    final along = t * travel - 0.18;
    final x = (along + item.lane * 0.4) * w;
    final y = h - (along * 0.72 + item.lane * 0.25) * h;

    return Positioned(
      left: x,
      top: y,
      child: Transform.rotate(
        angle: -0.55,
        child: Icon(
          item.icon,
          size: item.size,
          color: AppColors.authFileIcon.withValues(
            alpha: item.fade * widget.opacity,
          ),
        ),
      ),
    );
  }
}

class _DriftIcon {
  const _DriftIcon({
    required this.icon,
    required this.progress,
    required this.lane,
    required this.size,
    required this.speed,
    required this.fade,
  });

  final IconData icon;
  final double progress;
  final double lane;
  final double size;
  final double speed;
  final double fade;
}
