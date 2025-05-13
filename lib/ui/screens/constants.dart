import 'package:flutter/material.dart';

class AppColors {
  static const primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0A1931),
      Color(0xFF150E56),
      Color(0xFF1B1B2F),
    ],
  );

  static const primaryBlue = Color.fromRGBO(1, 18, 42, 1);
  static const white = Colors.white;
  static const errorRed = Colors.red;
  static const successGreen = Colors.green;

  static Color? buttonColor;
}

class AppConstants {
  static const otpLength = 6;
  static const otpTimeout = 60; // seconds
}
