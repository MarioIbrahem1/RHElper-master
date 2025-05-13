import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider لإدارة ثيم التطبيق (وضع فاتح/مظلم)
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.light;

  /// الحصول على وضع الثيم الحالي
  ThemeMode get themeMode => _themeMode;

  /// التحقق إذا كان الوضع المظلم مفعلاً
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadThemeMode();
  }

  /// تحميل التفضيل المحفوظ
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_themeKey) ?? false;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  /// تبديل وضع الثيم مع حفظ التفضيل
  Future<void> toggleTheme() async {
    try {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _themeMode == ThemeMode.dark);
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling theme: $e');
    }
  }

  /// تغيير وضع الثيم مع حفظ التفضيل
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _saveThemePreference();
  }

  /// حفظ التفضيل محلياً
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _themeMode == ThemeMode.dark);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  // Theme data for light mode
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF023A87), // Darker blue for better contrast
          secondary: Color(0xFF86A5D9), // Lighter blue for secondary elements
          surface: Color(0xFFFDFEFF), // White
          onPrimary: Colors.white, // White text on primary
          onSecondary: Color(0xFF023A87), // Dark blue text on secondary
          onSurface: Color(0xFF023A87), // Dark blue text on background
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF023A87),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: const Color(0xFFFDFEFF),
          surfaceTintColor: const Color(0xFFFDFEFF),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        textTheme: const TextTheme(
          titleMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Color(0xFF023A87),
          ),
          bodyMedium: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w700,
            color: Color(0xFF023A87),
          ),
          headlineSmall: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Color(0xFF023A87),
          ),
        ),
      );

  // Theme data for dark mode
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF86A5D9), // Lighter blue for primary
          secondary: Color(0xFF023A87), // Darker blue for secondary
          surface: Color(0xFF1F3551), // Darker background
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF1F3551),
          surfaceTintColor: const Color(0xFF1F3551),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        textTheme: const TextTheme(
          titleMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          bodyMedium: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          headlineSmall: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Color(0xFFA4A4A4),
          ),
        ),
      );
}














// import 'package:flutter/material.dart';
//
// class ThemeProvider{
//  static Color lightPrimary = Color(0xFF01122A);
//  static Color darkPrimary = Color(0xFFFDFEFF);
//
//  static ThemeData darkTheme = ThemeData(
//   textTheme: const TextTheme(
//    titleMedium: TextStyle(
//     fontSize: 20,
//     fontWeight: FontWeight.w500,
//     color: Colors.white,
//    ),
//       bodyMedium: TextStyle(
//        fontSize: 25,
//        fontWeight: FontWeight.w700,
//        color: Colors.white,
//       ),
//       headlineSmall: TextStyle(
//        fontSize: 20,
//        fontWeight: FontWeight.w400,
//        color: Color(0xFFA4A4A4),
//       )
//   ),
//
//   scaffoldBackgroundColor: const Color(0xFF1F3551),
//   cardTheme: CardTheme(
//    color: const Color(0xFF01122A),
//    surfaceTintColor: const Color(0xFF01122A),
//    elevation: 18,
//    shape: RoundedRectangleBorder(
//     borderRadius: BorderRadius.circular(20),
//    ),
//   ),
//   colorScheme: ColorScheme.fromSeed(
//    seedColor: const Color(0xFF1F3551),
//    primary: const Color(0xFF01122A),
//    secondary: const Color(0xFF023A87),
//    onPrimary: const Color(0xFFFFFFFF),
//    onSecondary: const Color(0xFFFFFFFF),
//   ),
//   useMaterial3: true,
//  );
//
//
//      static ThemeData lightTheme = ThemeData(
//       textTheme: const TextTheme(
//           titleMedium: TextStyle(
//            fontSize: 20,
//            fontWeight: FontWeight.w500,
//            color: Colors.white,
//           ),
//           bodyMedium: TextStyle(
//            fontSize: 25,
//            fontWeight: FontWeight.w700,
//            color: Color(0xFF023A87),
//           ),
//           headlineSmall: TextStyle(
//            fontSize: 20,
//            fontWeight: FontWeight.w400,
//            color: Color(0xFF47609A),
//           )
//       ),
//       scaffoldBackgroundColor: const Color(0xFF86A5D9),
//       cardTheme: CardTheme(
//        color: const Color(0xFFFDFEFF),
//        surfaceTintColor: const Color(0xFF86A5D9),
//        elevation: 18,
//        shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(20),
//        ),
//       ),
//       colorScheme: ColorScheme.fromSeed(
//        seedColor: const Color(0xFF86A5D9),
//        primary: const Color(0xFFFDFEFF),
//        secondary: const Color(0xFF023A87),
//        onPrimary: const Color(0xFFFFFFFF),
//        onSecondary: const Color(0xFFFFFFFF),
//       ),
//       useMaterial3: true,
//      );
//
//
//
//
// }
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
// // import 'package:flutter/material.dart';
// // import 'package:shared_preferences/shared_preferences.dart';
// //
// // class ThemeProvider with ChangeNotifier {
// //   ThemeMode _themeMode = ThemeMode.system;
// //   static const String _themePrefKey = 'isDark';
// //
// //   ThemeMode get themeMode => _themeMode;
// //   bool get isDarkMode => _themeMode == ThemeMode.dark;
// //
// //   ThemeProvider() {
// //     _loadThemePref();
// //   }
// //
// //   void toggleTheme(bool value) {
// //     _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
// //     notifyListeners();
// //   }
// //
// //   void setThemeMode(ThemeMode mode) {
// //     _themeMode = mode;
// //     notifyListeners();
// //   }
// //
// //   Future<void> _saveThemePref(bool isDark) async {
// //     try {
// //       final prefs = await SharedPreferences.getInstance();
// //       await prefs.setBool(_themePrefKey, isDark);
// //     } catch (e) {
// //       debugPrint('Error saving theme preference: $e');
// //     }
// //   }
// //
// //   Future<void> _loadThemePref() async {
// //     try {
// //       final prefs = await SharedPreferences.getInstance();
// //       final isDark = prefs.getBool(_themePrefKey) ?? false;
// //       _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
// //       notifyListeners();
// //     } catch (e) {
// //       debugPrint('Error loading theme preference: $e');
// //       _themeMode = ThemeMode.light;
// //       notifyListeners();
// //     }
// //   }
// // }
// //
