import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:road_helperr/models/help_request.dart';

class FirebaseHelpRequestService {
  static final FirebaseHelpRequestService _instance =
      FirebaseHelpRequestService._internal();
  factory FirebaseHelpRequestService() => _instance;
  FirebaseHelpRequestService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // إرسال طلب مساعدة
  Future<String> sendHelpRequest({
    required String receiverId,
    required String receiverName,
    required LatLng senderLocation,
    required LatLng receiverLocation,
    String? message,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // إنشاء ID جديد للطلب
      final requestRef = _database.child('helpRequests').push();
      final requestId = requestRef.key!;

      // بيانات الطلب
      final helpRequestData = {
        'requestId': requestId,
        'senderId': currentUser.uid,
        'senderName': currentUser.displayName ?? 'Unknown User',
        'senderEmail': currentUser.email ?? '',
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
      };

      // حفظ الطلب في Firebase
      await requestRef.set(helpRequestData);

      // إرسال إشعار للمستقبل
      await _sendNotificationToUser(
        receiverId,
        requestId,
        'help_request',
        'طلب مساعدة جديد من ${currentUser.displayName ?? 'مستخدم'}',
        helpRequestData,
      );

      debugPrint('Help request sent successfully: $requestId');
      return requestId;
    } catch (e) {
      debugPrint('Error sending help request: $e');
      throw Exception('Failed to send help request: $e');
    }
  }

  // الرد على طلب المساعدة
  Future<void> respondToHelpRequest({
    required String requestId,
    required bool accept,
    String? estimatedArrival,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final updates = {
        'status': accept ? 'accepted' : 'rejected',
        'respondedAt': ServerValue.timestamp,
        'responderId': currentUser.uid,
        'responderName': currentUser.displayName ?? 'Unknown User',
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
              ? 'تم قبول طلب المساعدة من ${currentUser.displayName ?? 'مستخدم'}'
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

  // الاستماع للطلبات الواردة للمستخدم الحالي
  Stream<List<HelpRequest>> listenToIncomingHelpRequests() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _database
        .child('helpRequests')
        .orderByChild('receiverId')
        .equalTo(currentUser.uid)
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
  }

  // الاستماع لطلبات المساعدة المرسلة من المستخدم الحالي
  Stream<List<HelpRequest>> listenToSentHelpRequests() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _database
        .child('helpRequests')
        .orderByChild('senderId')
        .equalTo(currentUser.uid)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <HelpRequest>[];

      return data.entries
          .map((entry) => _helpRequestFromFirebase(entry.key, entry.value))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
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
