import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:road_helperr/models/notification_model.dart';

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // الاستماع للإشعارات الجديدة
  Stream<List<NotificationModel>> listenToNotifications() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _database
        .child('notifications/${currentUser.uid}')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <NotificationModel>[];

      return data.entries
          .map((entry) => _notificationFromFirebase(entry.key, entry.value))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // الأحدث أولاً
    });
  }

  // إضافة إشعار جديد
  Future<void> addNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notificationRef = _database.child('notifications/$userId').push();

      await notificationRef.set({
        'id': notificationRef.key,
        'type': type,
        'title': title,
        'message': message,
        'data': data,
        'timestamp': ServerValue.timestamp,
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      debugPrint('Notification added successfully for user: $userId');
    } catch (e) {
      debugPrint('Error adding notification: $e');
      throw Exception('Failed to add notification: $e');
    }
  }

  // تحديد إشعار كمقروء
  Future<void> markAsRead(String notificationId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _database
          .child('notifications/${currentUser.uid}/$notificationId')
          .update({'isRead': true});

      debugPrint('Notification marked as read: $notificationId');
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // تحديد جميع الإشعارات كمقروءة
  Future<void> markAllAsRead() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final snapshot =
          await _database.child('notifications/${currentUser.uid}').get();
      if (!snapshot.exists) return;

      final data = snapshot.value as Map<dynamic, dynamic>;
      final updates = <String, dynamic>{};

      for (final entry in data.entries) {
        final notificationData = entry.value as Map<dynamic, dynamic>;
        if (notificationData['isRead'] != true) {
          updates['${entry.key}/isRead'] = true;
        }
      }

      if (updates.isNotEmpty) {
        await _database
            .child('notifications/${currentUser.uid}')
            .update(updates);
      }

      debugPrint('All notifications marked as read');
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  // حذف إشعار
  Future<void> deleteNotification(String notificationId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _database
          .child('notifications/${currentUser.uid}/$notificationId')
          .remove();

      debugPrint('Notification deleted: $notificationId');
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  // حذف جميع الإشعارات
  Future<void> clearAllNotifications() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _database.child('notifications/${currentUser.uid}').remove();

      debugPrint('All notifications cleared');
    } catch (e) {
      debugPrint('Error clearing all notifications: $e');
    }
  }

  // جلب عدد الإشعارات غير المقروءة
  Stream<int> getUnreadNotificationsCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _database
        .child('notifications/${currentUser.uid}')
        .orderByChild('isRead')
        .equalTo(false)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      return data?.length ?? 0;
    });
  }

  // إرسال إشعار طلب مساعدة
  Future<void> sendHelpRequestNotification({
    required String receiverId,
    required String senderName,
    required String requestId,
    required Map<String, dynamic> requestData,
  }) async {
    await addNotification(
      userId: receiverId,
      type: 'help_request',
      title: 'طلب مساعدة جديد',
      message: 'لديك طلب مساعدة جديد من $senderName',
      data: {
        'requestId': requestId,
        'requestData': requestData,
      },
    );
  }

  // إرسال إشعار رد على طلب المساعدة
  Future<void> sendHelpResponseNotification({
    required String senderId,
    required String responderName,
    required String requestId,
    required bool accepted,
    String? estimatedArrival,
  }) async {
    final message = accepted
        ? 'تم قبول طلب المساعدة من $responderName${estimatedArrival != null ? ' - الوصول المتوقع: $estimatedArrival' : ''}'
        : 'تم رفض طلب المساعدة من $responderName';

    await addNotification(
      userId: senderId,
      type: 'help_response',
      title: accepted ? 'تم قبول طلب المساعدة' : 'تم رفض طلب المساعدة',
      message: message,
      data: {
        'requestId': requestId,
        'accepted': accepted,
        'responderName': responderName,
        'estimatedArrival': estimatedArrival,
      },
    );
  }

  // تحويل بيانات Firebase إلى NotificationModel
  NotificationModel _notificationFromFirebase(
      String notificationId, dynamic data) {
    final notificationData = data as Map<dynamic, dynamic>;

    return NotificationModel(
      id: notificationId,
      type: notificationData['type'] ?? 'general',
      title: notificationData['title'] ?? '',
      body: notificationData['message'] ?? '',
      timestamp: DateTime.parse(
          notificationData['createdAt'] ?? DateTime.now().toIso8601String()),
      isRead: notificationData['isRead'] == true,
      data: notificationData['data'] != null
          ? Map<String, dynamic>.from(notificationData['data'])
          : null,
    );
  }

  // تنظيف الإشعارات القديمة (أكثر من 30 يوم)
  Future<void> cleanupOldNotifications() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final snapshot =
          await _database.child('notifications/${currentUser.uid}').get();
      if (!snapshot.exists) return;

      final data = snapshot.value as Map<dynamic, dynamic>;
      final toDelete = <String>[];

      for (final entry in data.entries) {
        final notificationData = entry.value as Map<dynamic, dynamic>;
        final createdAt = DateTime.parse(
            notificationData['createdAt'] ?? DateTime.now().toIso8601String());

        if (createdAt.isBefore(thirtyDaysAgo)) {
          toDelete.add(entry.key);
        }
      }

      // حذف الإشعارات القديمة
      for (final notificationId in toDelete) {
        await _database
            .child('notifications/${currentUser.uid}/$notificationId')
            .remove();
      }

      if (toDelete.isNotEmpty) {
        debugPrint('Cleaned up ${toDelete.length} old notifications');
      }
    } catch (e) {
      debugPrint('Error cleaning up old notifications: $e');
    }
  }

  // تنظيف الموارد
  void dispose() {
    // يمكن إضافة تنظيف إضافي هنا إذا لزم الأمر
  }
}
