import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:road_helperr/services/update_service.dart';

class LocalNotificationService {
  // Singleton instance
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  LocalNotificationService._internal();
  
  // تهيئة خدمة الإشعارات
  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }
  
  // معالجة النقر على الإشعار
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload == 'update_available') {
      // سيتم التعامل مع هذا في الشاشة الرئيسية
    }
  }
  
  // إرسال إشعار بتوفر تحديث جديد
  Future<void> showUpdateNotification(UpdateInfo updateInfo) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'update_channel',
      'تحديثات التطبيق',
      channelDescription: 'إشعارات بتوفر تحديثات جديدة للتطبيق',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _flutterLocalNotificationsPlugin.show(
      0,
      'تحديث جديد متاح',
      'الإصدار ${updateInfo.version} متاح الآن. انقر للتحديث.',
      platformChannelSpecifics,
      payload: 'update_available',
    );
  }
  
  // التحقق من وجود تحديثات وإرسال إشعار إذا كان هناك تحديث جديد
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
      debugPrint('خطأ في التحقق من التحديثات وإرسال الإشعارات: $e');
    }
  }
}
