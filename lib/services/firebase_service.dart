import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:road_helperr/services/firebase_user_location_service.dart';
import 'package:road_helperr/services/firebase_help_request_service.dart';
import 'package:road_helperr/services/firebase_notification_service.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _isInitialized = false;

  // خدمات Firebase
  late FirebaseUserLocationService _userLocationService;
  late FirebaseHelpRequestService _helpRequestService;
  late FirebaseNotificationService _notificationService;

  // Getters للخدمات
  FirebaseUserLocationService get userLocationService => _userLocationService;
  FirebaseHelpRequestService get helpRequestService => _helpRequestService;
  FirebaseNotificationService get notificationService => _notificationService;

  // تهيئة Firebase
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // تهيئة Firebase Core
      await Firebase.initializeApp();

      // تهيئة Firebase Realtime Database
      FirebaseDatabase.instance.setPersistenceEnabled(true);

      // تهيئة الخدمات
      _userLocationService = FirebaseUserLocationService();
      _helpRequestService = FirebaseHelpRequestService();
      _notificationService = FirebaseNotificationService();

      _isInitialized = true;
      debugPrint('Firebase services initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
      throw Exception('Failed to initialize Firebase: $e');
    }
  }

  // تسجيل دخول المستخدم وتحديث معلوماته
  Future<void> signInUser({
    required String email,
    required String name,
    String? phone,
    String? carModel,
    String? carColor,
    String? plateNumber,
    String? profileImageUrl,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

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

      // بدء تتبع الموقع
      _userLocationService.startLocationTracking();

      debugPrint('User signed in and info updated: $email');
    } catch (e) {
      debugPrint('Error signing in user: $e');
      throw Exception('Failed to sign in user: $e');
    }
  }

  // تسجيل خروج المستخدم
  Future<void> signOutUser() async {
    try {
      // إيقاف تتبع الموقع
      _userLocationService.stopLocationTracking();

      // تحديث حالة المستخدم إلى غير متصل
      await _userLocationService.setUserOffline();

      debugPrint('User signed out successfully');
    } catch (e) {
      debugPrint('Error signing out user: $e');
    }
  }

  // تحديث موقع المستخدم
  Future<void> updateUserLocation(double latitude, double longitude) async {
    try {
      await _userLocationService.updateUserLocation(
        gmaps.LatLng(latitude, longitude),
      );
    } catch (e) {
      debugPrint('Error updating user location: $e');
    }
  }

  // إرسال طلب مساعدة
  Future<String> sendHelpRequest({
    required String receiverId,
    required String receiverName,
    required double senderLat,
    required double senderLng,
    required double receiverLat,
    required double receiverLng,
    String? message,
  }) async {
    try {
      return await _helpRequestService.sendHelpRequest(
        receiverId: receiverId,
        receiverName: receiverName,
        senderLocation: gmaps.LatLng(senderLat, senderLng),
        receiverLocation: gmaps.LatLng(receiverLat, receiverLng),
        message: message,
      );
    } catch (e) {
      debugPrint('Error sending help request: $e');
      throw Exception('Failed to send help request: $e');
    }
  }

  // الرد على طلب مساعدة
  Future<void> respondToHelpRequest({
    required String requestId,
    required bool accept,
    String? estimatedArrival,
  }) async {
    try {
      await _helpRequestService.respondToHelpRequest(
        requestId: requestId,
        accept: accept,
        estimatedArrival: estimatedArrival,
      );
    } catch (e) {
      debugPrint('Error responding to help request: $e');
      throw Exception('Failed to respond to help request: $e');
    }
  }

  // إضافة إشعار
  Future<void> addNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _notificationService.addNotification(
        userId: userId,
        type: type,
        title: title,
        message: message,
        data: data,
      );
    } catch (e) {
      debugPrint('Error adding notification: $e');
    }
  }

  // تنظيف الموارد
  void dispose() {
    _userLocationService.dispose();
    _helpRequestService.dispose();
    _notificationService.dispose();
  }

  // التحقق من حالة الاتصال
  bool get isInitialized => _isInitialized;

  // الحصول على معرف المستخدم الحالي
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // التحقق من تسجيل الدخول
  bool get isUserSignedIn => FirebaseAuth.instance.currentUser != null;
}

// كلاس مساعد لـ LatLng
class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  @override
  String toString() => 'LatLng($latitude, $longitude)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LatLng &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;

  // تحويل إلى Map
  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // إنشاء من Map
  factory LatLng.fromMap(Map<String, dynamic> map) {
    return LatLng(
      (map['latitude'] as num).toDouble(),
      (map['longitude'] as num).toDouble(),
    );
  }
}
