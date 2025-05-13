import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:road_helperr/models/notification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:road_helperr/services/update_service.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  // مفتاح لقائمة معرفات الإشعارات
  static const String _notificationIdsKey = 'notification_ids';
  // بادئة لمفاتيح بيانات الإشعارات
  static const String _notificationPrefix = 'notification_';
  // مفتاح لعدد الإشعارات غير المقروءة
  static const String _unreadCountKey = 'unread_notifications_count';

  // الحصول على جميع الإشعارات
  Future<List<NotificationModel>> getAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // الحصول على معرفات الإشعارات
      final List<String> notificationIds =
          prefs.getStringList(_notificationIdsKey) ?? [];

      // الحصول على بيانات كل إشعار
      final List<NotificationModel> notifications = [];

      for (final id in notificationIds) {
        final String? notificationData =
            prefs.getString('$_notificationPrefix$id');

        if (notificationData != null) {
          try {
            // تحليل بيانات الإشعار
            final Map<String, dynamic> data = jsonDecode(notificationData);
            notifications.add(NotificationModel.fromJson(data));
          } catch (e) {
            debugPrint('خطأ في تحليل بيانات الإشعار: $e');
          }
        }
      }

      // ترتيب الإشعارات حسب الوقت (الأحدث أولاً)
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return notifications;
    } catch (e) {
      debugPrint('خطأ في الحصول على الإشعارات: $e');
      return [];
    }
  }

  // إضافة إشعار جديد
  Future<void> addNotification(NotificationModel notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // الحصول على معرفات الإشعارات الحالية
      final List<String> notificationIds =
          prefs.getStringList(_notificationIdsKey) ?? [];

      // إضافة معرف الإشعار الجديد إذا لم يكن موجوداً
      if (!notificationIds.contains(notification.id)) {
        notificationIds.add(notification.id);
        await prefs.setStringList(_notificationIdsKey, notificationIds);

        // زيادة عدد الإشعارات غير المقروءة
        final int unreadCount = prefs.getInt(_unreadCountKey) ?? 0;
        await prefs.setInt(_unreadCountKey, unreadCount + 1);
      }

      // حفظ بيانات الإشعار
      await prefs.setString(
        '$_notificationPrefix${notification.id}',
        jsonEncode(notification.toJson()),
      );
    } catch (e) {
      debugPrint('خطأ في إضافة الإشعار: $e');
    }
  }

  // تعليم إشعار كمقروء
  Future<void> markAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // الحصول على بيانات الإشعار
      final String? notificationData =
          prefs.getString('$_notificationPrefix$notificationId');

      if (notificationData != null) {
        // تحليل بيانات الإشعار
        final Map<String, dynamic> data = jsonDecode(notificationData);
        final notification = NotificationModel.fromJson(data);

        // إذا كان الإشعار غير مقروء، قم بتحديثه وتقليل العدد
        if (!notification.isRead) {
          notification.isRead = true;

          // حفظ بيانات الإشعار المحدثة
          await prefs.setString(
            '$_notificationPrefix$notificationId',
            jsonEncode(notification.toJson()),
          );

          // تقليل عدد الإشعارات غير المقروءة
          final int unreadCount = prefs.getInt(_unreadCountKey) ?? 0;
          if (unreadCount > 0) {
            await prefs.setInt(_unreadCountKey, unreadCount - 1);
          }
        }
      }
    } catch (e) {
      debugPrint('خطأ في تعليم الإشعار كمقروء: $e');
    }
  }

  // تعليم جميع الإشعارات كمقروءة
  Future<void> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<NotificationModel> notifications = await getAllNotifications();

      for (final notification in notifications) {
        if (!notification.isRead) {
          notification.isRead = true;
          await prefs.setString(
            '$_notificationPrefix${notification.id}',
            jsonEncode(notification.toJson()),
          );
        }
      }

      // إعادة تعيين عدد الإشعارات غير المقروءة
      await prefs.setInt(_unreadCountKey, 0);
    } catch (e) {
      debugPrint('خطأ في تعليم جميع الإشعارات كمقروءة: $e');
    }
  }

  // حذف إشعار محدد
  Future<void> removeNotification(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // الحصول على معرفات الإشعارات
      final List<String> notificationIds =
          prefs.getStringList(_notificationIdsKey) ?? [];

      // الحصول على بيانات الإشعار لمعرفة ما إذا كان مقروءاً
      final String? notificationData =
          prefs.getString('$_notificationPrefix$notificationId');

      if (notificationData != null) {
        final Map<String, dynamic> data = jsonDecode(notificationData);
        final notification = NotificationModel.fromJson(data);

        // إذا كان الإشعار غير مقروء، قم بتقليل العدد
        if (!notification.isRead) {
          final int unreadCount = prefs.getInt(_unreadCountKey) ?? 0;
          if (unreadCount > 0) {
            await prefs.setInt(_unreadCountKey, unreadCount - 1);
          }
        }
      }

      // إزالة معرف الإشعار من القائمة
      notificationIds.remove(notificationId);
      await prefs.setStringList(_notificationIdsKey, notificationIds);

      // حذف بيانات الإشعار
      await prefs.remove('$_notificationPrefix$notificationId');
    } catch (e) {
      debugPrint('خطأ في حذف الإشعار: $e');
    }
  }

  // حذف جميع الإشعارات
  Future<void> clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // الحصول على معرفات الإشعارات
      final List<String> notificationIds =
          prefs.getStringList(_notificationIdsKey) ?? [];

      // حذف بيانات جميع الإشعارات
      for (final id in notificationIds) {
        await prefs.remove('$_notificationPrefix$id');
      }

      // مسح قائمة معرفات الإشعارات
      await prefs.setStringList(_notificationIdsKey, []);

      // إعادة تعيين عدد الإشعارات غير المقروءة
      await prefs.setInt(_unreadCountKey, 0);
    } catch (e) {
      debugPrint('خطأ في حذف جميع الإشعارات: $e');
    }
  }

  // الحصول على عدد الإشعارات غير المقروءة
  Future<int> getUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_unreadCountKey) ?? 0;
    } catch (e) {
      debugPrint('خطأ في الحصول على عدد الإشعارات غير المقروءة: $e');
      return 0;
    }
  }

  // إضافة إشعار تحديث جديد
  Future<void> addUpdateNotification({
    required String version,
    required String downloadUrl,
    required String releaseNotes,
  }) async {
    final notification = NotificationModel(
      id: 'update_${DateTime.now().millisecondsSinceEpoch}',
      title: 'تحديث جديد متاح',
      body: 'الإصدار $version متاح الآن. انقر للتحديث.',
      timestamp: DateTime.now(),
      isRead: false,
      type: 'update',
      data: {
        'version': version,
        'downloadUrl': downloadUrl,
        'releaseNotes': releaseNotes,
      },
    );
    await addNotification(notification);
  }

  // معالجة النقر على إشعار
  Future<void> handleNotificationTap(
      NotificationModel notification, BuildContext context) async {
    if (notification.type == 'update' && notification.data != null) {
      final downloadUrl = notification.data!['downloadUrl'] as String;
      final version = notification.data!['version'] as String;
      final releaseNotes = notification.data!['releaseNotes'] as String;

      // عرض مربع حوار التحديث
      if (context.mounted) {
        final updateService = UpdateService();
        final updateInfo = UpdateInfo(
          version: version,
          versionCode: 0,
          downloadUrl: downloadUrl,
          releaseNotes: releaseNotes,
          forceUpdate: false,
        );
        updateService.showUpdateDialog(context, updateInfo);
      }
    }
    // تعليم الإشعار كمقروء
    await markAsRead(notification.id);
  }
}
