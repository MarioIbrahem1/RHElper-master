import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../../../../utils/app_colors.dart';

/// Widget to handle navigation bar for map screen
class MapNavigation {
  /// Build Material Design navigation bar
  static Widget buildMaterialNavBar({
    required BuildContext context,
    required double iconSize,
    required double navBarHeight,
    required bool isDesktop,
    required int selectedIndex,
    required Function(int) onTap,
  }) {
    return Container(
      constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
      margin: const EdgeInsets.only(bottom: 0),
      child: CurvedNavigationBar(
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF01122A),
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1F3551)
            : const Color(0xFF023A87),
        buttonBackgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1F3551)
            : const Color(0xFF023A87),
        animationDuration: const Duration(milliseconds: 300),
        height: 45,
        index: selectedIndex,
        items: const [
          Icon(Icons.home_outlined, size: 18, color: Colors.white),
          Icon(Icons.location_on_outlined, size: 18, color: Colors.white),
          Icon(Icons.textsms_outlined, size: 18, color: Colors.white),
          Icon(Icons.notifications_outlined, size: 18, color: Colors.white),
          Icon(Icons.person_2_outlined, size: 18, color: Colors.white),
        ],
        onTap: onTap,
      ),
    );
  }

  /// Build Cupertino navigation bar
  static Widget buildCupertinoNavBar({
    required BuildContext context,
    required double iconSize,
    required double navBarHeight,
    required bool isDesktop,
    required int selectedIndex,
    required Function(int) onTap,
  }) {
    return Container(
      constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
      child: CupertinoTabBar(
        backgroundColor: AppColors.getBackgroundColor(context),
        activeColor: Colors.white,
        inactiveColor: Colors.white.withOpacity(0.6),
        height: navBarHeight,
        currentIndex: selectedIndex,
        items: [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home, size: iconSize),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.location, size: iconSize),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chat_bubble, size: iconSize),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.bell, size: iconSize),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person, size: iconSize),
            label: 'Profile',
          ),
        ],
        onTap: onTap,
      ),
    );
  }
}
