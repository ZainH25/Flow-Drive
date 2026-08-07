import 'package:flutter/material.dart';

/// Central color palette for the entire app.
/// Every UI color should be referenced from here — see [ColorThemePage] for a visual catalog.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFF1976D2);
  static const Color primaryDark = Color(0xFF002171);
  static const Color accent = Color(0xFF00BFA5);
  static const Color accentLight = Color(0xFF5DF2D6);
  static const Color purple = Color(0xFF7E57C2);

  // ── Surfaces ───────────────────────────────────────────────────────────
  static const Color background = Color.fromARGB(255, 244, 244, 255);
  // static const Color background = Color(0xFFF9F9FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1A1F36);
  static const Color card = Color(0xFFFFFFFF);
  static const Color inputFill = Color(0xFFF0F4F8);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1F36);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnGradient = Color(0xFFFFFFFF);
  static const Color textLink = Color(0xFF4D49FF);

  // ── Borders & dividers ───────────────────────────────────────────────────
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color inputBorder = Color(0xFFE5E7EB);

  // ── Feedback ───────────────────────────────────────────────────────────
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA000);

  // ── Auth screen ──────────────────────────────────────────────────────────
  static const Color authGradientStart = Color(0xFFF9F9FF);
  static const Color authGradientMid = Color(0xFFF3F0FF);
  static const Color authGradientEnd = Color(0xFFEEF2FF);
  static const Color authCardShadow = Color(0x14000000);
  static const Color authFileIcon = Color(0xFF4D49FF);
  static const Color authFileIconAlt = Color(0xFF7E57C2);
  static const Color googleButtonBorder = Color(0xFFE0E0E0);
  static const Color checkboxBorder = Color(0xFFD1D5DB);
  static const Color infoBannerFill = Color(0xFFEEF2FF);
  static const Color infoBannerBorder = Color(0xFFDDE3FF);
  static const Color brandIndigo = Color(0xFF4D49FF);
  static const Color brandPurple = Color(0xFF6322D1);

  // ── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight, accent],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFDFDFF), Color(0xFFF3F0FF), Color(0xFFEEF2FF)],
  );

  static const LinearGradient authBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [authGradientStart, authGradientMid, authGradientEnd],
  );

  static const LinearGradient brandGradient = LinearGradient(
    colors: [brandPurple, brandIndigo, primaryLight],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [brandPurple, brandIndigo],
  );

  static const List<Color> onboardingGradientsPage1 = [primary, primaryLight];
  static const List<Color> onboardingGradientsPage2 = [Color(0xFF1565C0), accent];
  static const List<Color> onboardingGradientsPage3 = [primaryDark, primary];

  /// All solid colors for the design-system reference page.
  static const List<ColorToken> tokens = [
    ColorToken('primary', primary),
    ColorToken('primaryLight', primaryLight),
    ColorToken('primaryDark', primaryDark),
    ColorToken('accent', accent),
    ColorToken('accentLight', accentLight),
    ColorToken('purple', purple),
    ColorToken('background', background),
    ColorToken('surface', surface),
    ColorToken('surfaceDark', surfaceDark),
    ColorToken('card', card),
    ColorToken('textPrimary', textPrimary),
    ColorToken('textSecondary', textSecondary),
    ColorToken('textHint', textHint),
    ColorToken('textOnPrimary', textOnPrimary),
    ColorToken('textOnGradient', textOnGradient),
    ColorToken('textLink', textLink),
    ColorToken('border', border),
    ColorToken('borderLight', borderLight),
    ColorToken('inputFill', inputFill),
    ColorToken('error', error),
    ColorToken('success', success),
    ColorToken('warning', warning),
    ColorToken('authGradientStart', authGradientStart),
    ColorToken('authGradientMid', authGradientMid),
    ColorToken('authGradientEnd', authGradientEnd),
    ColorToken('authCardShadow', authCardShadow),
    ColorToken('authFileIcon', authFileIcon),
    ColorToken('authFileIconAlt', authFileIconAlt),
    ColorToken('googleButtonBorder', googleButtonBorder),
    ColorToken('brandIndigo', brandIndigo),
    ColorToken('brandPurple', brandPurple),
    ColorToken('infoBannerFill', infoBannerFill),
    ColorToken('inputBorder', inputBorder),
  ];

  static const List<GradientToken> gradientTokens = [
    GradientToken('primaryGradient', primaryGradient),
    GradientToken('splashGradient', splashGradient),
    GradientToken('authBackgroundGradient', authBackgroundGradient),
    GradientToken('brandGradient', brandGradient),
    GradientToken('buttonGradient', buttonGradient),
  ];
}

class ColorToken {
  const ColorToken(this.name, this.color);

  final String name;
  final Color color;

  String get hex {
    final v = color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
    return '#${v.substring(2)}';
  }
}

class GradientToken {
  const GradientToken(this.name, this.gradient);

  final String name;
  final Gradient gradient;
}
