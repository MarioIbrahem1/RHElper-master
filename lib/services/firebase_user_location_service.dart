import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:road_helperr/models/user_location.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

class FirebaseUserLocationService {
  static final FirebaseUserLocationService _instance =
      FirebaseUserLocationService._internal();
  factory FirebaseUserLocationService() => _instance;
  FirebaseUserLocationService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Timer? _locationUpdateTimer;
  StreamSubscription<Position>? _positionSubscription;

  // تحديث موقع المستخدم الحالي
  Future<void> updateUserLocation(LatLng location,
      {Map<String, dynamic>? additionalData}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('User not authenticated, cannot update location');
        return;
      }

      final locationData = {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'lastUpdated': ServerValue.timestamp,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // إضافة بيانات إضافية إذا وجدت
      if (additionalData != null) {
        locationData.addAll(additionalData.cast<String, Object>());
      }

      await _database
          .child('users/${currentUser.uid}/location')
          .update(locationData);

      // تحديث حالة الاتصال
      await _database.child('users/${currentUser.uid}').update({
        'isOnline': true,
        'lastSeen': ServerValue.timestamp,
      });

      debugPrint(
          'Location updated successfully: ${location.latitude}, ${location.longitude}');
    } catch (e) {
      debugPrint('Error updating user location: $e');
    }
  }

  // تحديث معلومات المستخدم الأساسية
  Future<void> updateUserInfo({
    required String name,
    required String email,
    String? phone,
    String? carModel,
    String? carColor,
    String? plateNumber,
    String? profileImageUrl,
    bool? isAvailableForHelp,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final userInfo = {
        'userId': currentUser.uid,
        'name': name,
        'email': email,
        'isOnline': true,
        'isAvailableForHelp': isAvailableForHelp ?? true,
        'lastUpdated': ServerValue.timestamp,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // إضافة البيانات الاختيارية
      if (phone != null) userInfo['phone'] = phone;
      if (carModel != null) userInfo['carModel'] = carModel;
      if (carColor != null) userInfo['carColor'] = carColor;
      if (plateNumber != null) userInfo['plateNumber'] = plateNumber;
      if (profileImageUrl != null) {
        userInfo['profileImageUrl'] = profileImageUrl;
      }

      await _database.child('users/${currentUser.uid}').update(userInfo);
      debugPrint('User info updated successfully');
    } catch (e) {
      debugPrint('Error updating user info: $e');
      throw Exception('Failed to update user info: $e');
    }
  }

  // الاستماع للمستخدمين القريبين
  Stream<List<UserLocation>> listenToNearbyUsers(
      LatLng currentLocation, double radiusKm) {
    return _database.child('users').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <UserLocation>[];

      final currentUser = _auth.currentUser;
      final currentUserId = currentUser?.uid;

      return data.entries
          .where((entry) {
            // استبعاد المستخدم الحالي
            if (entry.key == currentUserId) return false;

            final userData = entry.value as Map<dynamic, dynamic>;

            // التحقق من وجود بيانات الموقع
            if (userData['location'] == null) return false;

            // التحقق من أن المستخدم متاح للمساعدة ومتصل
            final isOnline = userData['isOnline'] == true;
            final isAvailable = userData['isAvailableForHelp'] == true;

            if (!isOnline || !isAvailable) return false;

            // التحقق من أن الموقع محدث حديثاً (خلال آخر 10 دقائق)
            final lastUpdated = userData['location']['updatedAt'];
            if (lastUpdated != null) {
              final lastUpdateTime = DateTime.parse(lastUpdated);
              final now = DateTime.now();
              final difference = now.difference(lastUpdateTime).inMinutes;
              if (difference > 10) return false; // أكثر من 10 دقائق
            }

            return true;
          })
          .map((entry) => _userLocationFromFirebase(entry.key, entry.value))
          .where((user) {
            // حساب المسافة وتصفية المستخدمين حسب النطاق
            final distance = _calculateDistance(currentLocation, user.position);
            return distance <= radiusKm;
          })
          .toList()
        ..sort((a, b) {
          // ترتيب حسب المسافة (الأقرب أولاً)
          final distanceA = _calculateDistance(currentLocation, a.position);
          final distanceB = _calculateDistance(currentLocation, b.position);
          return distanceA.compareTo(distanceB);
        });
    });
  }

  // جلب معلومات مستخدم محدد
  Future<UserLocation?> getUserById(String userId) async {
    try {
      final snapshot = await _database.child('users/$userId').get();
      if (snapshot.exists) {
        return _userLocationFromFirebase(userId, snapshot.value);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user by ID: $e');
      return null;
    }
  }

  // بدء تتبع الموقع التلقائي
  void startLocationTracking() {
    _locationUpdateTimer?.cancel();

    // تحديث الموقع كل دقيقة
    _locationUpdateTimer =
        Timer.periodic(const Duration(minutes: 1), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        await updateUserLocation(LatLng(position.latitude, position.longitude));
      } catch (e) {
        debugPrint('Error in automatic location update: $e');
      }
    });
  }

  // إيقاف تتبع الموقع
  void stopLocationTracking() {
    _locationUpdateTimer?.cancel();
    _positionSubscription?.cancel();
  }

  // تحديث حالة الاتصال عند الخروج
  Future<void> setUserOffline() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _database.child('users/${currentUser.uid}').update({
        'isOnline': false,
        'lastSeen': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('Error setting user offline: $e');
    }
  }

  // تحويل بيانات Firebase إلى UserLocation
  UserLocation _userLocationFromFirebase(String userId, dynamic data) {
    final userData = data as Map<dynamic, dynamic>;
    final locationData = userData['location'] as Map<dynamic, dynamic>?;

    return UserLocation(
      userId: userId,
      userName: userData['name'] ?? 'Unknown User',
      email: userData['email'] ?? '',
      phone: userData['phone'],
      position: LatLng(
        (locationData?['latitude'] as num?)?.toDouble() ?? 0.0,
        (locationData?['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      carModel: userData['carModel'],
      carColor: userData['carColor'],
      plateNumber: userData['plateNumber'],
      profileImageUrl: userData['profileImageUrl'],
      isOnline: userData['isOnline'] == true,
      isAvailableForHelp: userData['isAvailableForHelp'] == true,
      lastSeen: userData['lastSeen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(userData['lastSeen'])
          : DateTime.now(),
      rating: (userData['rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: userData['totalRatings'] ?? 0,
    );
  }

  // حساب المسافة بين نقطتين (بالكيلومتر)
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // نصف قطر الأرض بالكيلومتر

    final double lat1Rad = point1.latitude * (math.pi / 180);
    final double lat2Rad = point2.latitude * (math.pi / 180);
    final double deltaLatRad =
        (point2.latitude - point1.latitude) * (math.pi / 180);
    final double deltaLngRad =
        (point2.longitude - point1.longitude) * (math.pi / 180);

    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) *
            math.sin(deltaLngRad / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  // تنظيف الموارد
  void dispose() {
    stopLocationTracking();
  }
}
