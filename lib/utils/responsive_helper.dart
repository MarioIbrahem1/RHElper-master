import 'package:flutter/material.dart';

class ResponsiveHelper {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;

  static late double _safeAreaHorizontal;
  static late double _safeAreaVertical;
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;

  static late double fontSize;
  static late double iconSize;
  static late double buttonHeight;
  static late double buttonWidth;

  static bool isMobile = false;
  static bool isTablet = false;
  static bool isDesktop = false;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;

    _safeAreaHorizontal =
        _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    _safeAreaVertical =
        _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    safeBlockHorizontal = (screenWidth - _safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - _safeAreaVertical) / 100;

    if (screenWidth < 600) {
      isMobile = true;
      isTablet = false;
      isDesktop = false;
    } else if (screenWidth < 1200) {
      isMobile = false;
      isTablet = true;
      isDesktop = false;
    } else {
      isMobile = false;
      isTablet = false;
      isDesktop = true;
    }

    _initializeSizes();
  }

  static void _initializeSizes() {
    fontSize = isMobile
        ? blockSizeHorizontal * 4
        : isTablet
            ? blockSizeHorizontal * 3
            : blockSizeHorizontal * 2;

    iconSize = isMobile
        ? blockSizeHorizontal * 6
        : isTablet
            ? blockSizeHorizontal * 5
            : blockSizeHorizontal * 4;

    buttonHeight = isMobile
        ? blockSizeVertical * 7
        : isTablet
            ? blockSizeVertical * 6
            : blockSizeVertical * 5;

    buttonWidth = isMobile
        ? screenWidth * 0.85
        : isTablet
            ? screenWidth * 0.6
            : screenWidth * 0.4;
  }

  static double getResponsiveWidth(double percentage) {
    return screenWidth * (percentage / 100);
  }

  static double getResponsiveHeight(double percentage) {
    return screenHeight * (percentage / 100);
  }

  static double getResponsiveFontSize(double size) {
    double finalSize = size * blockSizeHorizontal;
    return finalSize.clamp(12, 32); // ضبط القيم ضمن نطاق معين
  }

  static EdgeInsets getResponsivePadding({
    double horizontal = 0,
    double vertical = 0,
  }) {
    return EdgeInsets.symmetric(
      horizontal: getResponsiveWidth(horizontal),
      vertical: getResponsiveHeight(vertical),
    );
  }

  static double getResponsiveValue({
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    if (isMobile) return mobile;
    if (isTablet) return tablet;
    return desktop;
  }
}
