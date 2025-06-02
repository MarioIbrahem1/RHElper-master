import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:road_helperr/models/notification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HybridNotificationService {
  static final HybridNotificationService _instance =
      HybridNotificationService._internal();
  factory HybridNotificationService() => _instance;
  HybridNotificationService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

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

  // الاستماع للإشعارات الجديدة (هجين)
  Stream<List<NotificationModel>> listenToNotifications() {
    return Stream.fromFuture(_getCurrentUserId()).asyncExpand((currentUserId) {
      if (currentUserId == null) {
        return Stream.value([]);
      }

      return _database
          .child('notifications/$currentUserId')
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
    });
  }

  // إضافة إشعار جديد (هجين)
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

  // تحديد إشعار كمقروء (هجين)
  Future<void> markAsRead(String notificationId) async {
    try {
      final currentUserId = await _getCurrentUserId();
      if (currentUserId == null) return;

      await _database
          .child('notifications/$currentUserId/$notificationId')
          .update({'isRead': true});

      debugPrint('Notification marked as read: $notificationId');
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // تحديد جميع الإشعارات كمقروءة (هجين)
  Future<void> markAllAsRead() async {
    try {
      final currentUserId = await _getCurrentUserId();
      if (currentUserId == null) return;

      final snapshot =
          await _database.child('notifications/$currentUserId').get();
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
        await _database.child('notifications/$currentUserId').update(updates);
      }

      debugPrint('All notifications marked as read');
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  // حذف إشعار (هجين)
  Future<void> deleteNotification(String notificationId) async {
    try {
      final currentUserId = await _getCurrentUserId();
      if (currentUserId == null) return;

      await _database
          .child('notifications/$currentUserId/$notificationId')
          .remove();

      debugPrint('Notification deleted: $notificationId');
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  // حذف جميع الإشعارات (هجين)
  Future<void> clearAllNotifications() async {
    try {
      final currentUserId = await _getCurrentUserId();
      if (currentUserId == null) return;

      await _database.child('notifications/$currentUserId').remove();

      debugPrint('All notifications cleared');
    } catch (e) {
      debugPrint('Error clearing all notifications: $e');
    }
  }

  // جلب عدد الإشعارات غير المقروءة (هجين)
  Stream<int> getUnreadNotificationsCount() {
    return Stream.fromFuture(_getCurrentUserId()).asyncExpand((currentUserId) {
      if (currentUserId == null) {
        return Stream.value(0);
      }

      return _database
          .child('notifications/$currentUserId')
          .orderByChild('isRead')
          .equalTo(false)
          .onValue
          .map((event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        return data?.length ?? 0;
      });
    });
  }

  // إرسال إشعار طلب مساعدة (هجين)
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

  // إرسال إشعار رد على طلب المساعدة (هجين)
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

  // إرسال إشعار عام للمستخدم (هجين)
  Future<void> sendGeneralNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    await addNotification(
      userId: userId,
      type: type,
      title: title,
      message: message,
      data: data,
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
      body: notificationData['message'] ??
          '', // استخدام 'message' من Firebase كـ 'body'
      timestamp: DateTime.parse(
          notificationData['createdAt'] ?? DateTime.now().toIso8601String()),
      isRead: notificationData['isRead'] == true,
      data: notificationData['data'] != null
          ? Map<String, dynamic>.from(notificationData['data'])
          : {},
    );
  }

  // تنظيف الإشعارات القديمة (أكثر من 30 يوم) - هجين
  Future<void> cleanupOldNotifications() async {
    try {
      final currentUserId = await _getCurrentUserId();
      if (currentUserId == null) return;

      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final snapshot =
          await _database.child('notifications/$currentUserId').get();
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
            .child('notifications/$currentUserId/$notificationId')
            .remove();
      }

      if (toDelete.isNotEmpty) {
        debugPrint('Cleaned up ${toDelete.length} old notifications');
      }
    } catch (e) {
      debugPrint('Error cleaning up old notifications: $e');
    }
  }

  // مزامنة المستخدم مع Firebase عند تسجيل الدخول
  Future<void> syncUserOnLogin({
    required String userId,
    required String name,
    required String email,
    String? phone,
    bool isFirebaseUser = false,
  }) async {
    try {
      // التأكد من وجود مجلد الإشعارات للمستخدم
      final userNotificationsRef = _database.child('notifications/$userId');

      // إنشاء إشعار ترحيب إذا كان المستخدم جديد
      final snapshot = await userNotificationsRef.get();
      if (!snapshot.exists) {
        await sendGeneralNotification(
          userId: userId,
          title: 'مرحباً بك في Road Helper',
          message:
              'نحن سعداء لانضمامك إلينا! يمكنك الآن طلب المساعدة من المستخدمين القريبين.',
          type: 'welcome',
        );
      }

      debugPrint('User synced with Firebase notifications: $userId');
    } catch (e) {
      debugPrint('Error syncing user with Firebase: $e');
    }
  }

  // تنظيف الموارد
  void dispose() {
    // يمكن إضافة تنظيف إضافي هنا إذا لزم الأمر
  }
}
