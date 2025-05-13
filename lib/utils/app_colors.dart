import 'package:flutter/material.dart';

enum AppThemeMode {
  system,
  light,
  dark,
}

class AppColors {
  static AppThemeMode _themeMode = AppThemeMode.system;
  static bool? _cachedIsLight;

  static AppThemeMode get currentThemeMode => _themeMode;

  static void setThemeMode(AppThemeMode mode, [BuildContext? context]) {
    _themeMode = mode;
    if (context != null) {
      _updateThemeFromSystem(context);
    }
  }

  static void _updateThemeFromSystem(BuildContext context) {
    if (_themeMode == AppThemeMode.system) {
      final brightness = MediaQuery.platformBrightnessOf(context);
      _cachedIsLight = brightness == Brightness.light;
    }
  }

  static bool _isLightTheme(BuildContext context) {
    if (_themeMode == AppThemeMode.light) return true;
    if (_themeMode == AppThemeMode.dark) return false;

    // System mode
    _updateThemeFromSystem(context);
    return _cachedIsLight ?? false;
  }

  // Background Colors
  static Color getBackgroundColor(BuildContext context) =>
      _isLightTheme(context)
          ? Colors.white
          : const Color(0xFF01122A);
  static Color getCardColor(BuildContext context) => _isLightTheme(context)
      ? const Color(0xFF86A5D9)
      : const Color(0xFF01122A);

  // Button Colors
  static Color basicButton = const Color(0xFF86A5D9);
  static const Color homeButton = Color(0xFF023A87);
  static Color getAiElevatedButton(BuildContext context) =>
      _isLightTheme(context)
          ? const Color(0xFF86A5D9)
          : const Color(0xFF296FF5);
  static Color getAiElevatedButton2(BuildContext context) =>
      _isLightTheme(context)
          ? const Color(0xFFFDFEFF)
          : const Color(0xFF2E3B55);
  static Color getSignAndRegister(BuildContext context) =>
      const Color(0xFF023A87);

  // Text and Label Colors
  static Color getLabelTextField(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.black
        : Colors.white;
  }

  static Color getTextStackColor(BuildContext context) => _isLightTheme(context)
      ? const Color(0xFF023A87)
      : const Color(0xFF494444);

  // Border and Field Colors
  static Color getBorderField(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? const Color(0xFFC4A7A7)
        : Colors.white;
  }

  static Color getStackColor(BuildContext context) => _isLightTheme(context)
      ? const Color(0xFFE0E0E0)
      : const Color(0xFFB7BCC2);
  static Color getStackColorIsSelected(BuildContext context) =>
      _isLightTheme(context)
          ? const Color(0xFF023A87)
          : const Color(0xFF033E90);
  static Color getSwitchColor(BuildContext context) => _isLightTheme(context)
      ? const Color(0xFF023A87)
      : const Color(0xFF4285F4);

  // Additional Colors
  static Color getLightPrimary(BuildContext context) => _isLightTheme(context)
      ? const Color(0xFF86A5D9)
      : const Color(0xFF01122A);
  static Color getDarkPrimary(BuildContext context) => _isLightTheme(context)
      ? const Color(0xFFFDFEFF)
      : const Color(0xFFFDFEFF);
  static const Color secondaryColor = Color(0xFF023A87);
  static Color getSurfaceColor(BuildContext context) => _isLightTheme(context)
      ? const Color(0xFFFDFEFF)
      : const Color(0xFF01122A);
  static const Color onPrimaryColor = Color(0xFFFFFFFF);
  static const Color onSecondaryColor = Color(0xFFFFFFFF);
  static Color getOtpFieldColor(BuildContext context) => _isLightTheme(context)
      ? const Color(0xFF023A87)
      : const Color(0xFFA4A4A4);
  static Color getProfileBackground(BuildContext context) =>
      _isLightTheme(context)
          ? const Color(0xFF86A5D9)
          : const Color(0xFF2C4874);
  static Color getDropdownColor(BuildContext context) => _isLightTheme(context)
      ? const Color(0xFFFDFEFF)
      : const Color(0xFF1A2A3F);
  static const Color activeTrackColor = Color(0xFF023A87);

  // Gradient Colors
  static Color getGradientStart(BuildContext context) => _isLightTheme(context)
      ? const Color(0xFF86A5D9)
      : const Color(0xFF01122A);
  static Color getGradientEnd(BuildContext context) => _isLightTheme(context)
      ? const Color(0xFFFDFEFF)
      : const Color(0xFF1F3551);

  // OnBoarding Gradient
  static const LinearGradient onBoardingGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF7B9DD6),
      Color(0xFFFCFCFC),
    ],
  );
}
