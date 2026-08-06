import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/responsive.dart';
import '../widgets/responsive_page.dart';

/// Visual catalog of every color token used across the app.
class ColorThemePage extends StatelessWidget {
  const ColorThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      appBar: AppBar(title: const Text('Color Theme')),
      padding: Responsive.pagePadding,
      body: ListView(
        children: [
          Text(
            'Solid colors',
            style: TextStyle(
              fontSize: Responsive.sp(16),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...AppColors.tokens.map(_ColorSwatch.new),
          const SizedBox(height: 28),
          Text(
            'Gradients',
            style: TextStyle(
              fontSize: Responsive.sp(16),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...AppColors.gradientTokens.map(_GradientSwatch.new),
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch(this.token);

  final ColorToken token;

  @override
  Widget build(BuildContext context) {
    final isLight = token.color.computeLuminance() > 0.7;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Responsive.radius(14)),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: token.color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isLight ? AppColors.border : Colors.transparent,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AppColors.${token.name}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: Responsive.sp(14),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  token.hex,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: Responsive.sp(13),
                    fontFamily: 'monospace',
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

class _GradientSwatch extends StatelessWidget {
  const _GradientSwatch(this.token);

  final GradientToken token;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Responsive.radius(14)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 64,
            decoration: BoxDecoration(
              gradient: token.gradient,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              'AppColors.${token.name}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: Responsive.sp(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
