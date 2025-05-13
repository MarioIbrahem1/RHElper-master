import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:road_helperr/utils/theme_provider.dart';

/// A switch widget that toggles between dark and light theme modes
class ThemeSwitch extends StatelessWidget {
  const ThemeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current theme provider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return IconButton(
      icon: Icon(
        themeProvider.isDarkMode
            ? Icons.dark_mode_rounded // Moon icon
            : Icons.light_mode_rounded, // Sun icon
        color:
            themeProvider.isDarkMode ? Colors.white : const Color(0xFF023A87),
        size: 24,
      ),
      onPressed: () {
        themeProvider.setThemeMode(
            themeProvider.isDarkMode ? ThemeMode.light : ThemeMode.dark);
      },
    );
  }
}
