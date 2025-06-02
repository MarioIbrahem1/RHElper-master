import 'package:road_helperr/ui/screens/bottomnavigationbar_screes/notification_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:road_helperr/models/notification_model.dart';
import 'package:road_helperr/services/notification_manager.dart';
import 'package:road_helperr/utils/message_utils.dart';

// Global navigation key for the application
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class FirebaseNotification {
  late final FirebaseMessaging _firebaseMessaging;
  final NotificationManager _notificationManager = NotificationManager();

  Future<void> initNotification() async {
    try {
      // Initialize FirebaseMessaging
      _firebaseMessaging = FirebaseMessaging.instance;

      // Request notification permissions
      await _firebaseMessaging.requestPermission();
      String? token = await _firebaseMessaging.getToken();
      // Use debugPrint instead of print for logging in development mode only
      debugPrint("FCM Token: $token");

      // Set up background notification handling
      await handleBackGroundNotification();

      // Set up foreground notification handling
      await handleForegroundNotification();
    } catch (e) {
      debugPrint("Error initializing notifications: $e");
    }
  }

  // Handle notifications when the app is in the foreground
  Future<void> handleForegroundNotification() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Convert the notification to a data model
      final notification = _createNotificationFromMessage(message);

      // Save the notification in the local database
      _notificationManager.addNotification(notification);
    });
  }

  // Handle notifications when they are clicked
  void handleMessage(RemoteMessage? message) async {
    if (message == null) return;

    // Convert the notification to a data model
    final notification = _createNotificationFromMessage(message);

    // Save the notification in the local database if it doesn't exist
    await _notificationManager.addNotification(notification);

    // Mark the notification as read
    await _notificationManager.markAsRead(notification.id);

    // Open the notifications screen
    navigatorKey.currentState!.pushNamed(NotificationScreen.routeName);
  }

  // Set up background notification handling
  Future<void> handleBackGroundNotification() async {
    try {
      // Handle notifications when opening the app through a notification
      FirebaseMessaging.instance.getInitialMessage().then(handleMessage);

      // Handle notifications when the app is in the background
      FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
    } catch (e) {
      debugPrint("Error setting up notification handling: $e");
    }
  }

  // Convert Firebase message to notification model
  NotificationModel _createNotificationFromMessage(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;
    final BuildContext? context = navigatorKey.currentContext;

    // Determine notification type
    String type = 'other';
    if (data.containsKey('type')) {
      type = data['type'] as String;
    }

    // Create unique ID for notification
    final String id =
        message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();

    // Get default title based on context if available
    String defaultTitle = 'New Notification';
    if (context != null) {
      defaultTitle = MessageUtils.getNewNotificationTitle(context);
    }

    // Create notification model
    return NotificationModel(
      id: id,
      title: notification?.title ?? defaultTitle,
      body: notification?.body ?? '',
      type: type,
      timestamp: DateTime.now(),
      data: data,
      isRead: false,
    );
  }
}
