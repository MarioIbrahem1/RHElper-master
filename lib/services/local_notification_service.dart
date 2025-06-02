import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:road_helperr/services/update_service.dart';

class LocalNotificationService {
  // Singleton instance
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  LocalNotificationService._internal();

  // Initialize notification service
  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload == 'update_available') {
      // This will be handled in the home screen
    }
  }

  // Send notification for available update
  Future<void> showUpdateNotification(UpdateInfo updateInfo) async {
    // Default notification title and body
    String title = 'Update Available';
    String body =
        'Version ${updateInfo.version} is now available. Tap to update.';

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'update_channel',
      'App Updates',
      channelDescription: 'Notifications for new app updates',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'update_available',
    );
  }

  // Check for updates and send notification if there is a new update
  Future<void> checkForUpdateAndNotify() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool updateAvailable = prefs.getBool('update_available') ?? false;

      if (updateAvailable) {
        final UpdateInfo? updateInfo = await UpdateService().getUpdateInfo();
        if (updateInfo != null) {
          await showUpdateNotification(updateInfo);
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates and sending notifications: $e');
    }
  }
}
