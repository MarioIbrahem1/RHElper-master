import 'dart:convert';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:road_helperr/models/notification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:road_helperr/services/update_service.dart';
import 'package:road_helperr/utils/message_utils.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  // Key for notification IDs list
  static const String _notificationIdsKey = 'notification_ids';
  // Prefix for notification data keys
  static const String _notificationPrefix = 'notification_';
  // Key for unread notifications count
  static const String _unreadCountKey = 'unread_notifications_count';

  // Get all notifications
  Future<List<NotificationModel>> getAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get notification IDs
      final List<String> notificationIds =
          prefs.getStringList(_notificationIdsKey) ?? [];

      // Get data for each notification
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
            debugPrint('Error parsing notification data: $e');
          }
        }
      }

      // ترتيب الإشعارات حسب الوقت (الأحدث أولاً)
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return notifications;
    } catch (e) {
      debugPrint('Error getting notifications: $e');
      return [];
    }
  }

  // Add a new notification
  Future<void> addNotification(NotificationModel notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get the current notification IDs
      final List<String> notificationIds =
          prefs.getStringList(_notificationIdsKey) ?? [];

      // Add the new notification ID if it doesn't exist
      if (!notificationIds.contains(notification.id)) {
        notificationIds.add(notification.id);
        await prefs.setStringList(_notificationIdsKey, notificationIds);

        // Increase unread notifications count
        final int unreadCount = prefs.getInt(_unreadCountKey) ?? 0;
        await prefs.setInt(_unreadCountKey, unreadCount + 1);
      }

      // Save notification data
      await prefs.setString(
        '$_notificationPrefix${notification.id}',
        jsonEncode(notification.toJson()),
      );
    } catch (e) {
      debugPrint('Error adding notification: $e');
    }
  }

  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get notification data
      final String? notificationData =
          prefs.getString('$_notificationPrefix$notificationId');

      if (notificationData != null) {
        // Parse notification data
        final Map<String, dynamic> data = jsonDecode(notificationData);
        final notification = NotificationModel.fromJson(data);

        // If notification is unread, update it and decrease the count
        if (!notification.isRead) {
          notification.isRead = true;

          // Save updated notification data
          await prefs.setString(
            '$_notificationPrefix$notificationId',
            jsonEncode(notification.toJson()),
          );

          // Decrease unread notifications count
          final int unreadCount = prefs.getInt(_unreadCountKey) ?? 0;
          if (unreadCount > 0) {
            await prefs.setInt(_unreadCountKey, unreadCount - 1);
          }
        }
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
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

      // Reset unread notifications count
      await prefs.setInt(_unreadCountKey, 0);
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  // Remove a specific notification
  Future<void> removeNotification(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get notification IDs
      final List<String> notificationIds =
          prefs.getStringList(_notificationIdsKey) ?? [];

      // Get notification data to check if it's read
      final String? notificationData =
          prefs.getString('$_notificationPrefix$notificationId');

      if (notificationData != null) {
        final Map<String, dynamic> data = jsonDecode(notificationData);
        final notification = NotificationModel.fromJson(data);

        // If notification is unread, decrease the count
        if (!notification.isRead) {
          final int unreadCount = prefs.getInt(_unreadCountKey) ?? 0;
          if (unreadCount > 0) {
            await prefs.setInt(_unreadCountKey, unreadCount - 1);
          }
        }
      }

      // Remove notification ID from the list
      notificationIds.remove(notificationId);
      await prefs.setStringList(_notificationIdsKey, notificationIds);

      // Delete notification data
      await prefs.remove('$_notificationPrefix$notificationId');
    } catch (e) {
      debugPrint('Error removing notification: $e');
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get notification IDs
      final List<String> notificationIds =
          prefs.getStringList(_notificationIdsKey) ?? [];

      // Delete all notification data
      for (final id in notificationIds) {
        await prefs.remove('$_notificationPrefix$id');
      }

      // Clear notification IDs list
      await prefs.setStringList(_notificationIdsKey, []);

      // Reset unread notifications count
      await prefs.setInt(_unreadCountKey, 0);
    } catch (e) {
      debugPrint('Error clearing all notifications: $e');
    }
  }

  // Get unread notifications count
  Future<int> getUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_unreadCountKey) ?? 0;
    } catch (e) {
      debugPrint('Error getting unread notifications count: $e');
      return 0;
    }
  }

  // Add a new update notification
  Future<void> addUpdateNotification({
    required String version,
    required String downloadUrl,
    required String releaseNotes,
    BuildContext? context,
  }) async {
    // Default notification title and body
    String title = 'Update Available';
    String body = 'Version $version is now available. Tap to update.';

    // If context is available, use localized messages
    if (context != null) {
      title = MessageUtils.getUpdateAvailableTitle(context);
      body = MessageUtils.getUpdateAvailableBody(context, version);
    }

    final notification = NotificationModel(
      id: 'update_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
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

  // Handle notification tap
  Future<void> handleNotificationTap(
      NotificationModel notification, BuildContext context) async {
    if (notification.type == 'update' && notification.data != null) {
      final downloadUrl = notification.data!['downloadUrl'] as String;
      final version = notification.data!['version'] as String;
      final releaseNotes = notification.data!['releaseNotes'] as String;

      // Show update dialog
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
    // Mark notification as read
    await markAsRead(notification.id);
  }
}
