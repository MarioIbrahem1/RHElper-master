import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:road_helperr/services/hybrid_help_request_service.dart';
import 'package:road_helperr/services/hybrid_user_location_service.dart';
import 'package:road_helperr/services/hybrid_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HybridServiceManager {
  static final HybridServiceManager _instance =
      HybridServiceManager._internal();
  factory HybridServiceManager() => _instance;
  HybridServiceManager._internal();

  bool _isInitialized = false;

  // خدمات النظام الهجين
  late HybridHelpRequestService _helpRequestService;
  late HybridUserLocationService _userLocationService;
  late HybridNotificationService _notificationService;

  // Getters للخدمات
  HybridHelpRequestService get helpRequestService => _helpRequestService;
  HybridUserLocationService get userLocationService => _userLocationService;
  HybridNotificationService get notificationService => _notificationService;

  // تهيئة النظام الهجين
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // تهيئة Firebase Realtime Database
      FirebaseDatabase.instance.setPersistenceEnabled(true);

      // تهيئة الخدمات الهجينة
      _helpRequestService = HybridHelpRequestService();
      _userLocationService = HybridUserLocationService();
      _notificationService = HybridNotificationService();

      _isInitialized = true;
      debugPrint('Hybrid services initialized successfully');
    } catch (e) {
      debugPrint('Error initializing hybrid services: $e');
      throw Exception('Failed to initialize hybrid services: $e');
    }
  }

  // تسجيل دخول المستخدم (هجين)
  Future<void> onUserLogin({
    required String userId,
    required String name,
    required String email,
    String? phone,
    String? carModel,
    String? carColor,
    String? plateNumber,
    String? profileImageUrl,
    bool isFirebaseUser = false,
  }) async {
    try {
      // تحديث معلومات المستخدم في Firebase
      await _userLocationService.updateUserInfo(
        name: name,
        email: email,
        phone: phone,
        carModel: carModel,
        carColor: carColor,
        plateNumber: plateNumber,
        profileImageUrl: profileImageUrl,
        isAvailableForHelp: true,
      );

      // مزامنة المستخدم مع نظام الإشعارات
      await _notificationService.syncUserOnLogin(
        userId: userId,
        name: name,
        email: email,
        phone: phone,
        isFirebaseUser: isFirebaseUser,
      );

      // بدء تتبع الموقع
      _userLocationService.startLocationTracking();

      debugPrint(
          'User logged in successfully: $email (${isFirebaseUser ? 'Firebase' : 'Regular'})');
    } catch (e) {
      debugPrint('Error on user login: $e');
      throw Exception('Failed to process user login: $e');
    }
  }

  // تسجيل خروج المستخدم (هجين)
  Future<void> onUserLogout() async {
    try {
      // إيقاف تتبع الموقع
      _userLocationService.stopLocationTracking();

      // تحديث حالة المستخدم إلى غير متصل
      await _userLocationService.setUserOffline();

      debugPrint('User logged out successfully');
    } catch (e) {
      debugPrint('Error on user logout: $e');
    }
  }

  // التحقق من نوع المستخدم الحالي
  Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    try {
      // أولاً: تحقق من Firebase Auth
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        return {
          'userId': firebaseUser.uid,
          'name': firebaseUser.displayName ?? 'Unknown User',
          'email': firebaseUser.email ?? '',
          'isFirebaseUser': true,
          'authMethod': 'firebase',
        };
      }

      // ثانياً: تحقق من SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final userName = prefs.getString('user_name');
      final userEmail = prefs.getString('user_email');
      final userPhone = prefs.getString('user_phone');

      if (userId != null && userId.isNotEmpty) {
        return {
          'userId': userId,
          'name': userName ?? 'Unknown User',
          'email': userEmail ?? '',
          'phone': userPhone,
          'isFirebaseUser': false,
          'authMethod': 'regular',
        };
      }

      return null;
    } catch (e) {
      debugPrint('Error getting current user info: $e');
      return null;
    }
  }

  // التحقق من تسجيل الدخول (هجين)
  Future<bool> isUserLoggedIn() async {
    try {
      final userInfo = await getCurrentUserInfo();
      return userInfo != null;
    } catch (e) {
      debugPrint('Error checking login status: $e');
      return false;
    }
  }

  // مزامنة المستخدم العادي مع Firebase عند أول تسجيل دخول
  Future<void> syncRegularUserWithFirebase() async {
    try {
      final userInfo = await getCurrentUserInfo();
      if (userInfo == null || userInfo['isFirebaseUser'] == true) {
        return; // مستخدم غير موجود أو مستخدم Firebase بالفعل
      }

      // الحصول على معلومات إضافية من SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final carModel = prefs.getString('user_car_model');
      final carColor = prefs.getString('user_car_color');
      final plateNumber = prefs.getString('user_plate_number');
      final profileImageUrl = prefs.getString('user_profile_image');

      // تحديث معلومات المستخدم في Firebase
      await _userLocationService.updateUserInfo(
        name: userInfo['name'],
        email: userInfo['email'],
        phone: userInfo['phone'],
        carModel: carModel,
        carColor: carColor,
        plateNumber: plateNumber,
        profileImageUrl: profileImageUrl,
        isAvailableForHelp: true,
      );

      debugPrint('Regular user synced with Firebase: ${userInfo['email']}');
    } catch (e) {
      debugPrint('Error syncing regular user with Firebase: $e');
    }
  }

  // إرسال إشعار عام لجميع المستخدمين (للإدارة)
  Future<void> sendBroadcastNotification({
    required String title,
    required String message,
    String type = 'system',
    Map<String, dynamic>? data,
  }) async {
    try {
      // هذه الوظيفة للإدارة فقط
      // يمكن تطويرها لاحقاً لإرسال إشعارات لجميع المستخدمين
      debugPrint('Broadcast notification: $title - $message');
    } catch (e) {
      debugPrint('Error sending broadcast notification: $e');
    }
  }

  // تنظيف البيانات القديمة
  Future<void> cleanupOldData() async {
    try {
      // تنظيف الإشعارات القديمة
      await _notificationService.cleanupOldNotifications();

      debugPrint('Old data cleanup completed');
    } catch (e) {
      debugPrint('Error cleaning up old data: $e');
    }
  }

  // إحصائيات النظام
  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      final userInfo = await getCurrentUserInfo();
      if (userInfo == null) {
        return {'error': 'User not logged in'};
      }

      // إحصائيات بسيطة
      return {
        'userId': userInfo['userId'],
        'authMethod': userInfo['authMethod'],
        'isFirebaseUser': userInfo['isFirebaseUser'],
        'systemStatus': 'active',
        'servicesInitialized': _isInitialized,
      };
    } catch (e) {
      debugPrint('Error getting system stats: $e');
      return {'error': 'Failed to get stats'};
    }
  }

  // تنظيف الموارد
  void dispose() {
    _helpRequestService.dispose();
    _userLocationService.dispose();
    _notificationService.dispose();
  }

  // التحقق من حالة التهيئة
  bool get isInitialized => _isInitialized;

  // الحصول على معرف المستخدم الحالي
  Future<String?> getCurrentUserId() async {
    final userInfo = await getCurrentUserInfo();
    return userInfo?['userId'];
  }

  // التحقق من نوع المستخدم
  Future<bool> isFirebaseUser() async {
    final userInfo = await getCurrentUserInfo();
    return userInfo?['isFirebaseUser'] == true;
  }
}
