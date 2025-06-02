import 'package:flutter/material.dart';
import 'package:road_helperr/utils/message_utils.dart';

enum NotificationType {
  helpRequest,
  updateAvailable,
  systemMessage,
  other,
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime timestamp;
  final Map<String, dynamic>? data;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.data,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? json['message'] ?? '',
      type: json['type'] ?? 'other',
      timestamp: json['timestamp'] is String
          ? DateTime.parse(json['timestamp'])
          : DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      data: json['data'],
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'isRead': isRead,
    };
  }

  // Helper method to convert string type to enum
  static NotificationType getNotificationType(String? type) {
    if (type == null) return NotificationType.other;

    switch (type.toLowerCase()) {
      case 'help_request':
        return NotificationType.helpRequest;
      case 'update_available':
        return NotificationType.updateAvailable;
      case 'system_message':
        return NotificationType.systemMessage;
      default:
        return NotificationType.other;
    }
  }

  // Convert from HelpRequest to NotificationModel
  static NotificationModel fromHelpRequest(Map<String, dynamic> helpRequestData,
      [BuildContext? context]) {
    final String requestId = helpRequestData['requestId'] ?? '';
    final String senderName = helpRequestData['senderName'] ?? '';

    // Default title and body if context is not provided
    String title = 'Help Request';
    String body = 'You received a help request from $senderName';

    // If context is provided, use localized messages
    if (context != null) {
      title = MessageUtils.getHelpRequestTitle(context);
      body = MessageUtils.getHelpRequestBody(context, senderName);
    }

    return NotificationModel(
      id: requestId,
      title: title,
      body: body,
      type: 'help_request',
      timestamp: helpRequestData['timestamp'] is String
          ? DateTime.parse(helpRequestData['timestamp'])
          : DateTime.now(),
      data: helpRequestData,
      isRead: false,
    );
  }
}
