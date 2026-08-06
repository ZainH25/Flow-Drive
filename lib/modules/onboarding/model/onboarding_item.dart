import 'package:flutter/material.dart';

class OnboardingItem {
  const OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    this.imageAsset,
    this.gradientColors,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? imageAsset;
  final List<Color>? gradientColors;
}
