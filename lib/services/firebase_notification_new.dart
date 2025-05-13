import 'package:road_helperr/ui/screens/bottomnavigationbar_screes/notification_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:road_helperr/models/notification_model.dart';
import 'package:road_helperr/services/notification_manager.dart';

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
      await _firebaseMessaging.requestPermission();
      String? token = await _firebaseMessaging.getToken();
      // استخدام debugPrint بدلاً من print للتسجيل في وضع التطوير فقط
      debugPrint("FCM Token: $token");

      // إعداد معالجة الإشعارات في الخلفية
      await handleBackGroundNotification();

      // إعداد معالجة الإشعارات عندما يكون التطبيق في المقدمة
      await handleForegroundNotification();
    } catch (e) {
      debugPrint("خطأ في تهيئة الإشعارات: $e");
    }
  }

  // معالجة الإشعارات عندما يكون التطبيق في المقدمة
  Future<void> handleForegroundNotification() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // تحويل الإشعار إلى نموذج بيانات
      final notification = _createNotificationFromMessage(message);

      // حفظ الإشعار في قاعدة البيانات المحلية
      _notificationManager.addNotification(notification);
    });
  }

  // معالجة الإشعارات عندما يتم النقر عليها
  void handleMessage(RemoteMessage? message) async {
    if (message == null) return;

    // تحويل الإشعار إلى نموذج بيانات
    final notification = _createNotificationFromMessage(message);

    // حفظ الإشعار في قاعدة البيانات المحلية إذا لم يكن موجوداً
    await _notificationManager.addNotification(notification);

    // تعليم الإشعار كمقروء
    await _notificationManager.markAsRead(notification.id);

    // فتح شاشة الإشعارات
    navigatorKey.currentState!.pushNamed(NotificationScreen.routeName);
  }

  // إعداد معالجة الإشعارات في الخلفية
  Future<void> handleBackGroundNotification() async {
    try {
      // معالجة الإشعارات عند فتح التطبيق من خلال الإشعار
      FirebaseMessaging.instance.getInitialMessage().then(handleMessage);

      // معالجة الإشعارات عندما يكون التطبيق في الخلفية
      FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
    } catch (e) {
      debugPrint("خطأ في إعداد معالجة الإشعارات: $e");
    }
  }

  // تحويل رسالة Firebase إلى نموذج بيانات الإشعار
  NotificationModel _createNotificationFromMessage(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;

    // تحديد نوع الإشعار
    String type = 'other';
    if (data.containsKey('type')) {
      type = data['type'] as String;
    }

    // إنشاء معرف فريد للإشعار
    final String id =
        message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();

    // إنشاء نموذج بيانات الإشعار
    return NotificationModel(
      id: id,
      title: notification?.title ?? 'إشعار جديد',
      body: notification?.body ?? '',
      type: type,
      timestamp: DateTime.now(),
      data: data,
      isRead: false,
    );
  }
}
