import 'package:road_helperr/models/notification_model.dart';
import 'package:road_helperr/services/notification_manager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

// تعريف مفتاح التنقل العام للتطبيق
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class FirebaseNotification {
  late final FirebaseMessaging _firebaseMessaging;
  final NotificationManager _notificationManager = NotificationManager();

  Future<void> initNotification() async {
    try {
      // تهيئة FirebaseMessaging
      _firebaseMessaging = FirebaseMessaging.instance;

      // طلب إذن الإشعارات
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // الحصول على توكن الجهاز
      String? token = await _firebaseMessaging.getToken();
      debugPrint("FCM Token: $token");

      // إعداد معالجة الإشعارات
      await handleBackGroundNotification();
    } catch (e) {
      debugPrint("خطأ في تهيئة الإشعارات: $e");
    }
  }

  void handleMessage(RemoteMessage? message) {
    if (message == null) return;

    // تحويل رسالة Firebase إلى نموذج الإشعار الخاص بنا
    final notification = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'إشعار جديد',
      body: message.notification?.body ?? '',
      type: message.data['type'] ?? 'system',
      timestamp: DateTime.now(),
      data: message.data,
      isRead: false,
    );

    // إضافة الإشعار إلى مدير الإشعارات
    _notificationManager.addNotification(notification);

    // إذا كان التطبيق مفتوحاً، قم بمعالجة الإشعار مباشرة
    if (navigatorKey.currentState != null) {
      _notificationManager.handleNotificationTap(
        notification,
        navigatorKey.currentState!.context,
      );
    }
  }

  Future<void> handleBackGroundNotification() async {
    try {
      // معالجة الإشعارات عند فتح التطبيق من خلال الإشعار
      FirebaseMessaging.instance.getInitialMessage().then(handleMessage);

      // معالجة الإشعارات عندما يكون التطبيق في الخلفية
      FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);

      // معالجة الإشعارات عندما يكون التطبيق مفتوحاً
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        handleMessage(message);
      });
    } catch (e) {
      debugPrint("خطأ في إعداد معالجة الإشعارات: $e");
    }
  }
}
