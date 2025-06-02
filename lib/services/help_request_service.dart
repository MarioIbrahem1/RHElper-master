import 'dart:async';
import 'package:flutter/material.dart';
import 'package:road_helperr/models/help_request.dart';
import 'package:road_helperr/models/notification_model.dart';
import 'package:road_helperr/services/api_service.dart';
import 'package:road_helperr/services/notification_manager.dart';
import 'package:road_helperr/ui/widgets/help_request_dialog.dart';
// import 'package:road_helperr/utils/message_utils.dart';

class HelpRequestService {
  static final HelpRequestService _instance = HelpRequestService._internal();
  factory HelpRequestService() => _instance;
  HelpRequestService._internal();

  Timer? _checkRequestsTimer;
  final List<String> _processedRequestIds = [];
  bool _isInitialized = false;
  final NotificationManager _notificationManager = NotificationManager();

  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isInitialized = true;
    _startCheckingRequests();
  }

  // Start checking for new help requests periodically
  void _startCheckingRequests() {
    _checkRequestsTimer?.cancel();
    _checkRequestsTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkForNewRequests(),
    );
  }

  // Check for new help requests
  Future<void> _checkForNewRequests() async {
    try {
      final requests = await ApiService.getPendingHelpRequests();

      // Filter out already processed requests
      final newRequests = requests
          .where(
            (request) => !_processedRequestIds.contains(request.requestId),
          )
          .toList();

      // Add new request IDs to processed list
      for (var request in newRequests) {
        _processedRequestIds.add(request.requestId);
      }

      // Limit the size of the processed list to avoid memory issues
      if (_processedRequestIds.length > 100) {
        _processedRequestIds.removeRange(0, _processedRequestIds.length - 100);
      }

      // Show notifications for new requests
      for (var request in newRequests) {
        _showHelpRequestNotification(request);
      }
    } catch (e) {
      debugPrint('Error checking for help requests: $e');
    }
  }

  // Show a notification for a new help request
  Future<void> _showHelpRequestNotification(HelpRequest request) async {
    // Log the notification
    debugPrint('New help request from ${request.senderName}');

    // Convert help request to notification using the fromHelpRequest method
    final notification = NotificationModel.fromHelpRequest(request.toJson());

    // Save notification to notification manager
    await _notificationManager.addNotification(notification);
  }

  // Show a help request dialog
  Future<bool?> showHelpRequestDialog(
      BuildContext context, HelpRequest request) {
    return HelpRequestDialog.show(context, request);
  }

  // Get all help request notifications
  Future<List<NotificationModel>> getHelpRequestNotifications() async {
    try {
      // استخدام مدير الإشعارات للحصول على جميع الإشعارات
      final allNotifications = await _notificationManager.getAllNotifications();

      // تصفية الإشعارات للحصول على طلبات المساعدة فقط
      return allNotifications
          .where((notification) => notification.type == 'help_request')
          .toList();
    } catch (e) {
      debugPrint('Error getting help request notifications: $e');
      return [];
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      // استخدام مدير الإشعارات لمسح جميع الإشعارات
      await _notificationManager.clearAllNotifications();
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  // Remove a specific notification
  Future<void> removeNotification(String notificationId) async {
    try {
      // استخدام مدير الإشعارات لحذف إشعار محدد
      await _notificationManager.removeNotification(notificationId);
    } catch (e) {
      debugPrint('Error removing notification: $e');
    }
  }

  // Dispose resources
  void dispose() {
    _checkRequestsTimer?.cancel();
    _isInitialized = false;
  }
}
