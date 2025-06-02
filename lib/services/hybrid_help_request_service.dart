import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:road_helperr/models/help_request.dart';
import 'package:road_helperr/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HybridHelpRequestService {
  static final HybridHelpRequestService _instance =
      HybridHelpRequestService._internal();
  factory HybridHelpRequestService() => _instance;
  HybridHelpRequestService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final AuthService _authService = AuthService();

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

    // ثانياً: تحقق من SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final userName = prefs.getString('user_name');
    final userEmail = prefs.getString('user_email');

    if (userId != null && userId.isNotEmpty) {
      return {
        'userId': userId,
        'name': userName ?? 'Unknown User',
        'email': userEmail ?? '',
        'isFirebaseUser': false,
      };
    }

    return null;
  }

  // إرسال طلب مساعدة (هجين)
  Future<String> sendHelpRequest({
    required String receiverId,
    required String receiverName,
    required LatLng senderLocation,
    required LatLng receiverLocation,
    String? message,
  }) async {
    try {
      final currentUserInfo = await _getCurrentUserInfo();
      if (currentUserInfo == null) {
        throw Exception('User not authenticated');
      }

      // إنشاء ID جديد للطلب
      final requestRef = _database.child('helpRequests').push();
      final requestId = requestRef.key!;

      // بيانات الطلب
      final helpRequestData = {
        'requestId': requestId,
        'senderId': currentUserInfo['userId'],
        'senderName': currentUserInfo['name'],
        'senderEmail': currentUserInfo['email'],
        'senderLocation': {
          'latitude': senderLocation.latitude,
          'longitude': senderLocation.longitude,
        },
        'receiverId': receiverId,
        'receiverName': receiverName,
        'receiverLocation': {
          'latitude': receiverLocation.latitude,
          'longitude': receiverLocation.longitude,
        },
        'message': message ?? 'I need help with my car. Can you assist me?',
        'status': 'pending',
        'timestamp': ServerValue.timestamp,
        'createdAt': DateTime.now().toIso8601String(),
        'senderType':
            currentUserInfo['isFirebaseUser'] ? 'firebase' : 'regular',
      };

      // حفظ الطلب في Firebase
      await requestRef.set(helpRequestData);

      // إرسال إشعار للمستقبل
      await _sendNotificationToUser(
        receiverId,
        requestId,
        'help_request',
        'طلب مساعدة جديد من ${currentUserInfo['name']}',
        Map<String, dynamic>.from(helpRequestData),
      );

      debugPrint('Help request sent successfully: $requestId');
      return requestId;
    } catch (e) {
      debugPrint('Error sending help request: $e');
      throw Exception('Failed to send help request: $e');
    }
  }

  // الرد على طلب المساعدة (هجين)
  Future<void> respondToHelpRequest({
    required String requestId,
    required bool accept,
    String? estimatedArrival,
  }) async {
    try {
      final currentUserInfo = await _getCurrentUserInfo();
      if (currentUserInfo == null) {
        throw Exception('User not authenticated');
      }

      final updates = {
        'status': accept ? 'accepted' : 'rejected',
        'respondedAt': ServerValue.timestamp,
        'responderId': currentUserInfo['userId'],
        'responderName': currentUserInfo['name'],
        'responderType':
            currentUserInfo['isFirebaseUser'] ? 'firebase' : 'regular',
      };

      if (accept && estimatedArrival != null) {
        updates['estimatedArrival'] = estimatedArrival;
      }

      await _database.child('helpRequests/$requestId').update(updates);

      // إرسال إشعار للمرسل بالرد
      final requestSnapshot =
          await _database.child('helpRequests/$requestId').get();
      if (requestSnapshot.exists) {
        final requestData = requestSnapshot.value as Map<dynamic, dynamic>;
        final senderId = requestData['senderId'];

        await _sendNotificationToUser(
          senderId,
          requestId,
          'help_response',
          accept
              ? 'تم قبول طلب المساعدة من ${currentUserInfo['name']}'
              : 'تم رفض طلب المساعدة',
          Map<String, dynamic>.from(requestData),
        );
      }

      debugPrint(
          'Help request response sent: $requestId - ${accept ? 'accepted' : 'rejected'}');
    } catch (e) {
      debugPrint('Error responding to help request: $e');
      throw Exception('Failed to respond to help request: $e');
    }
  }

  // الاستماع للطلبات الواردة للمستخدم الحالي (هجين)
  Stream<List<HelpRequest>> listenToIncomingHelpRequests() {
    return Stream.fromFuture(_getCurrentUserId()).asyncExpand((currentUserId) {
      if (currentUserId == null) {
        return Stream.value([]);
      }

      return _database
          .child('helpRequests')
          .orderByChild('receiverId')
          .equalTo(currentUserId)
          .onValue
          .map((event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data == null) return <HelpRequest>[];

        return data.entries
            .map((entry) => _helpRequestFromFirebase(entry.key, entry.value))
            .where((request) => request.status == HelpRequestStatus.pending)
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      });
    });
  }

  // الاستماع لطلبات المساعدة المرسلة من المستخدم الحالي (هجين)
  Stream<List<HelpRequest>> listenToSentHelpRequests() {
    return Stream.fromFuture(_getCurrentUserId()).asyncExpand((currentUserId) {
      if (currentUserId == null) {
        return Stream.value([]);
      }

      return _database
          .child('helpRequests')
          .orderByChild('senderId')
          .equalTo(currentUserId)
          .onValue
          .map((event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data == null) return <HelpRequest>[];

        return data.entries
            .map((entry) => _helpRequestFromFirebase(entry.key, entry.value))
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      });
    });
  }

  // جلب طلب مساعدة محدد
  Future<HelpRequest?> getHelpRequestById(String requestId) async {
    try {
      final snapshot = await _database.child('helpRequests/$requestId').get();
      if (snapshot.exists) {
        return _helpRequestFromFirebase(requestId, snapshot.value);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting help request: $e');
      return null;
    }
  }

  // إرسال إشعار للمستخدم
  Future<void> _sendNotificationToUser(
    String userId,
    String requestId,
    String type,
    String message,
    Map<String, dynamic> data,
  ) async {
    try {
      final notificationRef = _database.child('notifications/$userId').push();

      await notificationRef.set({
        'id': notificationRef.key,
        'type': type,
        'requestId': requestId,
        'title':
            type == 'help_request' ? 'طلب مساعدة جديد' : 'رد على طلب المساعدة',
        'message': message,
        'data': data,
        'timestamp': ServerValue.timestamp,
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  // تحويل بيانات Firebase إلى HelpRequest
  HelpRequest _helpRequestFromFirebase(String requestId, dynamic data) {
    final requestData = data as Map<dynamic, dynamic>;

    return HelpRequest(
      requestId: requestId,
      senderId: requestData['senderId'] ?? '',
      senderName: requestData['senderName'] ?? 'Unknown',
      senderPhone: requestData['senderPhone'],
      senderCarModel: requestData['senderCarModel'],
      senderCarColor: requestData['senderCarColor'],
      senderPlateNumber: requestData['senderPlateNumber'],
      senderLocation: LatLng(
        (requestData['senderLocation']['latitude'] as num).toDouble(),
        (requestData['senderLocation']['longitude'] as num).toDouble(),
      ),
      receiverId: requestData['receiverId'] ?? '',
      receiverName: requestData['receiverName'] ?? 'Unknown',
      receiverPhone: requestData['receiverPhone'],
      receiverCarModel: requestData['receiverCarModel'],
      receiverCarColor: requestData['receiverCarColor'],
      receiverPlateNumber: requestData['receiverPlateNumber'],
      receiverLocation: LatLng(
        (requestData['receiverLocation']['latitude'] as num).toDouble(),
        (requestData['receiverLocation']['longitude'] as num).toDouble(),
      ),
      timestamp: DateTime.parse(
          requestData['createdAt'] ?? DateTime.now().toIso8601String()),
      status: _parseStatus(requestData['status']),
      message: requestData['message'],
    );
  }

  // تحويل النص إلى enum
  HelpRequestStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return HelpRequestStatus.pending;
      case 'accepted':
        return HelpRequestStatus.accepted;
      case 'rejected':
        return HelpRequestStatus.rejected;
      case 'completed':
        return HelpRequestStatus.completed;
      case 'cancelled':
        return HelpRequestStatus.cancelled;
      default:
        return HelpRequestStatus.pending;
    }
  }

  // تنظيف الموارد
  void dispose() {
    // يمكن إضافة تنظيف إضافي هنا إذا لزم الأمر
  }
}
