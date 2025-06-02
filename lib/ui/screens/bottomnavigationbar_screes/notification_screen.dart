import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:road_helperr/models/help_request.dart';
import 'package:road_helperr/models/notification_model.dart';

import 'package:road_helperr/services/hybrid_notification_service.dart';
import 'package:road_helperr/ui/widgets/help_request_dialog.dart';
import 'package:road_helperr/ui/screens/ai_welcome_screen.dart';
import 'package:road_helperr/ui/screens/bottomnavigationbar_screes/map_screen.dart';
import 'package:road_helperr/ui/screens/bottomnavigationbar_screes/profile_screen.dart';

import '../../../utils/app_colors.dart';
import 'home_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class NotificationScreen extends StatefulWidget {
  static const String routeName = "notification";

  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int _selectedIndex = 3; // Removed const since we need to update it

  final HybridNotificationService _notificationService =
      HybridNotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // تحميل الإشعارات
  Future<void> _loadNotifications() async {
    try {
      // الاستماع للإشعارات من Firebase
      _notificationService.listenToNotifications().listen((notifications) {
        if (mounted) {
          setState(() {
            _notifications = notifications;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      debugPrint('خطأ في تحميل الإشعارات: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // مسح جميع الإشعارات
  Future<void> _clearAllNotifications() async {
    try {
      await _notificationService.clearAllNotifications();

      if (mounted) {
        setState(() {
          _notifications = [];
        });
      }
    } catch (e) {
      debugPrint('خطأ في مسح الإشعارات: $e');
    }
  }

  // حذف إشعار محدد
  Future<void> _removeNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);

      if (mounted) {
        setState(() {
          _notifications
              .removeWhere((notification) => notification.id == notificationId);
        });
      }
    } catch (e) {
      debugPrint('خطأ في حذف الإشعار: $e');
    }
  }

  // تعليم إشعار كمقروء
  Future<void> _markAsRead(NotificationModel notification) async {
    if (!notification.isRead) {
      try {
        await _notificationService.markAsRead(notification.id);

        if (mounted) {
          setState(() {
            notification.isRead = true;
          });
        }
      } catch (e) {
        debugPrint('خطأ في تعليم الإشعار كمقروء: $e');
      }
    }
  }

  // عرض محتوى الإشعار
  Future<void> _showNotificationContent(NotificationModel notification) async {
    // تعليم الإشعار كمقروء
    await _markAsRead(notification);

    // عرض محتوى الإشعار حسب نوعه
    if (notification.type == 'help_request') {
      await _showHelpRequestDialog(notification);
    } else if (notification.type == 'update') {
      // معالجة إشعار التحديث - يمكن إضافة منطق التحديث هنا
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(notification.title),
            content: Text(notification.body),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      }
    } else if (mounted) {
      // عرض محتوى الإشعارات الأخرى
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(notification.title),
          content: Text(notification.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
    }
  }

  // عرض حوار طلب المساعدة
  Future<void> _showHelpRequestDialog(NotificationModel notification) async {
    try {
      if (notification.data == null) {
        debugPrint('لا توجد بيانات لطلب المساعدة');
        return;
      }

      // تحويل بيانات الإشعار إلى كائن HelpRequest
      final request = HelpRequest.fromJson(notification.data!);

      // عرض الحوار
      final result = await HelpRequestDialog.show(context, request);

      // إذا استجاب المستخدم للطلب، قم بحذف الإشعار
      if (result != null) {
        await _removeNotification(notification.id);
      }
    } catch (e) {
      debugPrint('خطأ في عرض حوار طلب المساعدة: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = MediaQuery.of(context).size;
        final isTablet = constraints.maxWidth > 600;
        final isDesktop = constraints.maxWidth > 1200;

        double titleSize = size.width *
            (isDesktop
                ? 0.02
                : isTablet
                    ? 0.03
                    : 0.04);
        double subtitleSize = titleSize * 0.8;
        double iconSize = size.width *
            (isDesktop
                ? 0.02
                : isTablet
                    ? 0.025
                    : 0.03);
        double navBarHeight = size.height *
            (isDesktop
                ? 0.08
                : isTablet
                    ? 0.07
                    : 0.06);
        double spacing = size.height * 0.02;

        return platform == TargetPlatform.iOS ||
                platform == TargetPlatform.macOS
            ? _buildCupertinoLayout(context, size, titleSize, subtitleSize,
                iconSize, navBarHeight, spacing, isDesktop)
            : _buildMaterialLayout(context, size, titleSize, subtitleSize,
                iconSize, navBarHeight, spacing, isDesktop);
      },
    );
  }

  Widget _buildMaterialLayout(
    BuildContext context,
    Size size,
    double titleSize,
    double subtitleSize,
    double iconSize,
    double navBarHeight,
    double spacing,
    bool isDesktop,
  ) {
    var lang = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : const Color(0xFF01122A),
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF01122A),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.black
                : Colors.white,
            size: iconSize,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          lang.noNotifications,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.black
                : Colors.white,
            fontSize: titleSize,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _clearAllNotifications,
            child: Text(
              lang.clearAll,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? AppColors.getSwitchColor(context)
                    : Colors.white,
                fontSize: subtitleSize,
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(
          context, size, titleSize, subtitleSize, spacing, isDesktop),
      bottomNavigationBar:
          _buildMaterialNavBar(context, iconSize, navBarHeight, isDesktop),
    );
  }

  Widget _buildCupertinoLayout(
    BuildContext context,
    Size size,
    double titleSize,
    double subtitleSize,
    double iconSize,
    double navBarHeight,
    double spacing,
    bool isDesktop,
  ) {
    var lang = AppLocalizations.of(context)!;
    return CupertinoPageScaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : AppColors.getCardColor(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : AppColors.getCardColor(context),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.back,
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.black
                : Colors.white,
            size: iconSize,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        middle: Text(
          lang.noNotifications,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.black
                : Colors.white,
            fontSize: titleSize,
            fontFamily: '.SF Pro Text',
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _clearAllNotifications,
          child: Text(
            lang.clearAll,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.light
                  ? AppColors.getSwitchColor(context)
                  : Colors.white,
              fontSize: subtitleSize,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildBody(
                  context, size, titleSize, subtitleSize, spacing, isDesktop),
            ),
            _buildCupertinoNavBar(context, iconSize, navBarHeight, isDesktop),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    Size size,
    double titleSize,
    double subtitleSize,
    double spacing,
    bool isDesktop,
  ) {
    final platform = Theme.of(context).platform;
    final isIOS =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    var lang = AppLocalizations.of(context)!;

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 800 : 600,
        ),
        padding: EdgeInsets.all(size.width * 0.04),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          Theme.of(context).brightness == Brightness.light
                              ? "assets/images/notification light.png"
                              : "assets/images/Group 12.png",
                          width: size.width * (isDesktop ? 0.3 : 0.5),
                          height: size.height * 0.25,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: spacing * 3),
                        Text(
                          lang.noNotifications,
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? AppColors.getSwitchColor(context)
                                    : const Color(0xFFA0A0A0),
                            fontSize: titleSize,
                            fontWeight: FontWeight.w600,
                            fontFamily: isIOS ? '.SF Pro Text' : null,
                          ),
                        ),
                        SizedBox(height: spacing * 1.5),
                        Text(
                          lang.notificationInboxEmpty,
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? AppColors.getSwitchColor(context)
                                    : const Color(0xFFA0A0A0),
                            fontSize: subtitleSize,
                            fontFamily: isIOS ? '.SF Pro Text' : null,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];

                      // عرض جميع أنواع الإشعارات
                      return _buildNotificationItem(
                        context,
                        notification,
                        titleSize,
                        subtitleSize,
                      );
                    },
                  ),
      ),
    );
  }

  // تنسيق الوقت بنظام 12 ساعة
  String _formatTime(DateTime timestamp) {
    // تحويل إلى نظام 12 ساعة
    int hour = timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour;
    // إذا كانت الساعة 0 (منتصف الليل)، عرضها كـ 12
    hour = hour == 0 ? 12 : hour;
    String period = timestamp.hour >= 12 ? 'م' : 'ص';

    return '${hour.toString()}:${timestamp.minute.toString().padLeft(2, '0')} $period';
  }

  // بناء عنصر الإشعار
  Widget _buildNotificationItem(
    BuildContext context,
    NotificationModel notification,
    double titleSize,
    double subtitleSize,
  ) {
    final timestamp = notification.timestamp;
    final timeString = _formatTime(timestamp);
    final dateString = '${timestamp.day}/${timestamp.month}/${timestamp.year}';

    // تحديد لون الخلفية بناءً على حالة القراءة
    final backgroundColor = notification.isRead
        ? Colors.transparent
        : Theme.of(context).brightness == Brightness.light
            ? Colors.blue.withOpacity(0.1)
            : Colors.blue.withOpacity(0.2);

    // تحديد أيقونة الإشعار حسب النوع
    IconData notificationIcon;
    Color iconColor = Colors.white;
    Color iconBackgroundColor = AppColors.getSwitchColor(context);

    switch (notification.type) {
      case 'help_request':
        notificationIcon = Icons.help_outline;
        break;
      case 'update':
        notificationIcon = Icons.system_update;
        iconBackgroundColor = Colors.green;
        break;
      case 'system_message':
        notificationIcon = Icons.info_outline;
        iconBackgroundColor = Colors.orange;
        break;
      default:
        notificationIcon = Icons.notifications_none;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      child: InkWell(
        onTap: () => _showNotificationContent(notification),
        child: Container(
          color: backgroundColor,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: iconBackgroundColor,
              child: Icon(notificationIcon, color: iconColor),
            ),
            title: Text(
              notification.title,
              style: TextStyle(
                fontSize: titleSize * 0.8,
                fontWeight:
                    notification.isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  style: TextStyle(fontSize: subtitleSize * 0.9),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$timeString - $dateString',
                  style: TextStyle(
                    fontSize: subtitleSize * 0.8,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            trailing: notification.isRead
                ? null
                : Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialNavBar(
    BuildContext context,
    double iconSize,
    double navBarHeight,
    bool isDesktop,
  ) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: isDesktop ? 1200 : double.infinity,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 0),
        child: CurvedNavigationBar(
          backgroundColor: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : const Color(0xFF01122A),
          color: Theme.of(context).brightness == Brightness.light
              ? const Color(0xFF023A87)
              : const Color(0xFF1F3551),
          buttonBackgroundColor:
              Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFF023A87)
                  : const Color(0xFF1F3551),
          animationDuration: const Duration(milliseconds: 300),
          height: 45,
          index: _selectedIndex,
          letIndexChange: (index) => true,
          items: [
            Icon(Icons.home_outlined, size: iconSize, color: Colors.white),
            Icon(Icons.location_on_outlined,
                size: iconSize, color: Colors.white),
            Icon(Icons.textsms_outlined, size: iconSize, color: Colors.white),
            Icon(Icons.notifications_outlined,
                size: iconSize, color: Colors.white),
            Icon(Icons.person_2_outlined, size: iconSize, color: Colors.white),
          ],
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            _handleNavigation(context, index);
          },
        ),
      ),
    );
  }

  Widget _buildCupertinoNavBar(
    BuildContext context,
    double iconSize,
    double navBarHeight,
    bool isDesktop,
  ) {
    var lang = AppLocalizations.of(context)!;
    return Container(
      constraints: BoxConstraints(
        maxWidth: isDesktop ? 1200 : double.infinity,
      ),
      child: CupertinoTabBar(
        backgroundColor: AppColors.getBackgroundColor(context),
        activeColor: Colors.white,
        inactiveColor: Colors.white.withOpacity(0.6),
        height: navBarHeight,
        currentIndex: _selectedIndex,
        items: [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home, size: iconSize),
            label: lang.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.location, size: iconSize),
            label: lang.map,
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chat_bubble, size: iconSize),
            label: lang.chat,
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.bell, size: iconSize),
            label: lang.noNotifications,
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person, size: iconSize),
            label: lang.profile,
          ),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _handleNavigation(context, index);
        },
      ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    final routes = [
      HomeScreen.routeName,
      MapScreen.routeName,
      AiWelcomeScreen.routeName,
      NotificationScreen.routeName,
      ProfileScreen.routeName,
    ];

    if (index >= 0 && index < routes.length) {
      Navigator.pushReplacementNamed(context, routes[index]);
    }
  }
}
