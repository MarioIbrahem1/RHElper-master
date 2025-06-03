import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:road_helperr/models/user_location.dart';
import 'package:road_helperr/services/api_service.dart';
import 'package:road_helperr/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

class HybridUserLocationService {
  static final HybridUserLocationService _instance =
      HybridUserLocationService._internal();
  factory HybridUserLocationService() => _instance;
  HybridUserLocationService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Timer? _locationUpdateTimer;
  StreamSubscription<Position>? _positionSubscription;

  // الحصول على معرف المستخدم الحالي (هجين)
  Future<String?> _getCurrentUserId() async {
    // أولاً: تحقق من Firebase Auth (للمستخدمين اللي سجلوا بـ Google)
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      return firebaseUser.uid;
    }

    // ثانياً: تحقق من SharedPreferences (للمستخدمين العاديين)
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId != null && userId.isNotEmpty) {
      return userId;
    }

    return null;
  }

  // الحصول على معلومات المستخدم الحالي
  Future<Map<String, dynamic>?> _getCurrentUserInfo() async {
    // أولاً: تحقق من Firebase Auth
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      return {
        'userId': firebaseUser.uid,
        'name': firebaseUser.displayName ?? 'Unknown User',
        'email': firebaseUser.email ?? '',
        'isFirebaseUser': true,
      };
    }

    // ثانياً: تحقق من SharedPreferences باستخدام AuthService
    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();

    if (isLoggedIn) {
      final userId = await authService.getUserId();
      final userName = await authService.getUserName();
      final userEmail = await authService.getUserEmail();

      if (userId != null && userId.isNotEmpty) {
        debugPrint('Found authenticated user: $userEmail (ID: $userId)');
        return {
          'userId': userId,
          'name': userName ?? 'Unknown User',
          'email': userEmail ?? '',
          'isFirebaseUser': false,
        };
      }
    }

    debugPrint('No authenticated user found');
    return null;
  }

  // تحديث موقع المستخدم الحالي (هجين)
  Future<void> updateUserLocation(LatLng location,
      {Map<String, dynamic>? additionalData}) async {
    try {
      final currentUserInfo = await _getCurrentUserInfo();
      if (currentUserInfo == null) {
        debugPrint('User not authenticated, cannot update location');
        return;
      }

      final userId = currentUserInfo['userId'];

      // تحديث الموقع في Firebase
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

      await _database.child('users/$userId/location').update(locationData);

      // تحديث حالة الاتصال
      await _database.child('users/$userId').update({
        'isOnline': true,
        'lastSeen': ServerValue.timestamp,
      });

      debugPrint(
          'Location updated successfully: ${location.latitude}, ${location.longitude}');
    } catch (e) {
      debugPrint('Error updating user location: $e');
    }
  }

  // تحديث معلومات المستخدم الأساسية (هجين)
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
      final currentUserInfo = await _getCurrentUserInfo();
      if (currentUserInfo == null) {
        throw Exception('User not authenticated');
      }

      final userId = currentUserInfo['userId'];

      final userInfo = {
        'userId': userId,
        'name': name,
        'email': email,
        'isOnline': true,
        'isAvailableForHelp': isAvailableForHelp ?? true,
        'lastUpdated': ServerValue.timestamp,
        'updatedAt': DateTime.now().toIso8601String(),
        'userType': currentUserInfo['isFirebaseUser'] ? 'firebase' : 'regular',
      };

      // إضافة البيانات الاختيارية
      if (phone != null) userInfo['phone'] = phone;
      if (carModel != null) userInfo['carModel'] = carModel;
      if (carColor != null) userInfo['carColor'] = carColor;
      if (plateNumber != null) userInfo['plateNumber'] = plateNumber;
      if (profileImageUrl != null) {
        userInfo['profileImageUrl'] = profileImageUrl;
      }

      await _database.child('users/$userId').update(userInfo);
      debugPrint('User info updated successfully');
    } catch (e) {
      debugPrint('Error updating user info: $e');
      throw Exception('Failed to update user info: $e');
    }
  }

  // الاستماع للمستخدمين القريبين (هجين - Real-time مع تحديث سريع)
  Stream<List<UserLocation>> listenToNearbyUsers(
      LatLng currentLocation, double radiusKm) {
    // استخدام Firebase real-time listener مع fallback للـ API
    return _database.child('users').onValue.asyncMap((event) async {
      try {
        final List<UserLocation> allUsers = [];

        // 1. جلب المستخدمين من Firebase (Real-time)
        final firebaseUsers = await _getNearbyUsersFromFirebaseRealtime(
            event, currentLocation, radiusKm);
        allUsers.addAll(firebaseUsers);

        // 2. جلب المستخدمين من REST API (كل 30 ثانية فقط)
        if (DateTime.now().second % 30 == 0) {
          final apiUsers =
              await _getNearbyUsersFromAPI(currentLocation, radiusKm);
          allUsers.addAll(apiUsers);
        }

        // 3. إزالة المستخدمين المكررين
        final uniqueUsers = _removeDuplicateUsers(allUsers);

        // 4. ترتيب حسب المسافة
        uniqueUsers.sort((a, b) {
          final distanceA = _calculateDistance(currentLocation, a.position);
          final distanceB = _calculateDistance(currentLocation, b.position);
          return distanceA.compareTo(distanceB);
        });

        debugPrint('Real-time users found: ${uniqueUsers.length}');
        return uniqueUsers;
      } catch (e) {
        debugPrint('Error getting nearby users: $e');
        return <UserLocation>[];
      }
    });
  }

  // جلب المستخدمين من Firebase بشكل Real-time
  Future<List<UserLocation>> _getNearbyUsersFromFirebaseRealtime(
      DatabaseEvent event, LatLng currentLocation, double radiusKm) async {
    try {
      final currentUserId = await _getCurrentUserId();

      if (!event.snapshot.exists) return [];
      final data = event.snapshot.value as Map<dynamic, dynamic>;

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

            // تقليل وقت انتهاء الصلاحية إلى 5 دقائق بدلاً من 10
            final lastUpdated = userData['location']['updatedAt'];
            if (lastUpdated != null) {
              final lastUpdateTime = DateTime.parse(lastUpdated);
              final now = DateTime.now();
              final difference = now.difference(lastUpdateTime).inMinutes;
              if (difference > 5) return false; // تقليل إلى 5 دقائق
            }

            return true;
          })
          .map((entry) => _userLocationFromFirebase(entry.key, entry.value))
          .where((user) {
            // حساب المسافة وتصفية المستخدمين حسب النطاق
            final distance = _calculateDistance(currentLocation, user.position);
            return distance <= radiusKm;
          })
          .toList();
    } catch (e) {
      debugPrint('Error getting Firebase real-time users: $e');
      return [];
    }
  }

  // جلب المستخدمين القريبين من REST API
  Future<List<UserLocation>> _getNearbyUsersFromAPI(
      LatLng currentLocation, double radiusKm) async {
    try {
      // استخدام API الموجود للحصول على المستخدمين القريبين
      final apiUsers = await ApiService.getNearbyUsers(
        latitude: currentLocation.latitude,
        longitude: currentLocation.longitude,
        radius: radiusKm * 1000, // تحويل إلى متر
      );

      // تحديث معلومات هؤلاء المستخدمين في Firebase أيضاً
      for (final user in apiUsers) {
        await _syncUserToFirebase(user);
      }

      return apiUsers;
    } catch (e) {
      debugPrint('Error getting API users: $e');
      return [];
    }
  }

  // مزامنة مستخدم من API إلى Firebase
  Future<void> _syncUserToFirebase(UserLocation user) async {
    try {
      final userInfo = {
        'userId': user.userId,
        'name': user.userName,
        'email': user.email,
        'phone': user.phone,
        'carModel': user.carModel,
        'carColor': user.carColor,
        'plateNumber': user.plateNumber,
        'profileImageUrl': user.profileImageUrl,
        'isOnline': user.isOnline,
        'isAvailableForHelp': user.isAvailableForHelp,
        'lastSeen': user.lastSeen.toIso8601String(),
        'rating': user.rating,
        'totalRatings': user.totalRatings,
        'userType': 'regular', // من API
        'lastUpdated': ServerValue.timestamp,
        'updatedAt': DateTime.now().toIso8601String(),
        'location': {
          'latitude': user.position.latitude,
          'longitude': user.position.longitude,
          'lastUpdated': ServerValue.timestamp,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      };

      await _database.child('users/${user.userId}').update(userInfo);
    } catch (e) {
      debugPrint('Error syncing user to Firebase: $e');
    }
  }

  // إزالة المستخدمين المكررين
  List<UserLocation> _removeDuplicateUsers(List<UserLocation> users) {
    final Map<String, UserLocation> uniqueUsersMap = {};

    for (final user in users) {
      // إذا كان المستخدم موجود، احتفظ بالأحدث
      if (!uniqueUsersMap.containsKey(user.userId) ||
          user.lastSeen.isAfter(uniqueUsersMap[user.userId]!.lastSeen)) {
        uniqueUsersMap[user.userId] = user;
      }
    }

    return uniqueUsersMap.values.toList();
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

  // بدء تتبع الموقع التلقائي (محسن للاستجابة السريعة)
  void startLocationTracking() {
    _locationUpdateTimer?.cancel();
    _positionSubscription?.cancel();

    // تحديث الموقع كل 30 ثانية بدلاً من دقيقة كاملة
    _locationUpdateTimer =
        Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        await updateUserLocation(LatLng(position.latitude, position.longitude));
        debugPrint(
            'Location updated: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        debugPrint('Error in automatic location update: $e');
      }
    });

    // إضافة listener للحركة الفورية (عند تغيير الموقع بشكل كبير)
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // تحديث عند الحركة 50 متر
        timeLimit: Duration(seconds: 10),
      ),
    ).listen((Position position) async {
      try {
        await updateUserLocation(LatLng(position.latitude, position.longitude));
        debugPrint(
            'Real-time location update: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        debugPrint('Error in real-time location update: $e');
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
      final userId = await _getCurrentUserId();
      if (userId == null) return;

      await _database.child('users/$userId').update({
        'isOnline': false,
        'lastSeen': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('Error setting user offline: $e');
    }
  }

  // تنظيف الموارد
  void dispose() {
    stopLocationTracking();
  }
}
