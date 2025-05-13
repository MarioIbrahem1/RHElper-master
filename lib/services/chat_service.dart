import 'dart:async';
import 'package:flutter/material.dart';
import 'package:road_helperr/models/chat_message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  // In-memory storage for messages (in a real app, this would use Firebase or another backend)
  final Map<String, List<ChatMessage>> _chatMessages = {};

  // Stream controllers for each chat
  final Map<String, StreamController<List<ChatMessage>>> _chatControllers = {};

  // Get current user ID
  Future<String> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id') ?? '';
  }

  // Get chat ID from user IDs
  String _getChatId(String userId1, String userId2) {
    // Sort IDs to ensure consistent chat ID regardless of who initiates
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  // Get stream for a specific chat
  Future<Stream<List<ChatMessage>>> getChatStream(String otherUserId) async {
    final currentUserId = await _getCurrentUserId();
    final chatId = _getChatId(currentUserId, otherUserId);

    if (!_chatControllers.containsKey(chatId)) {
      _chatControllers[chatId] =
          StreamController<List<ChatMessage>>.broadcast();

      // Initialize with existing messages if any
      if (_chatMessages.containsKey(chatId)) {
        _chatControllers[chatId]!.add(_chatMessages[chatId]!);
      } else {
        _chatMessages[chatId] = [];
        _chatControllers[chatId]!.add([]);
      }
    }

    return _chatControllers[chatId]!.stream;
  }

  // Send a message
  Future<bool> sendMessage({
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    try {
      final currentUserId = await _getCurrentUserId();
      final chatId = _getChatId(currentUserId, receiverId);

      // Create a new message
      final message = ChatMessage(
        id: const Uuid().v4(),
        senderId: currentUserId,
        receiverId: receiverId,
        content: content,
        type: type,
        timestamp: DateTime.now(),
      );

      // Add to in-memory storage
      if (!_chatMessages.containsKey(chatId)) {
        _chatMessages[chatId] = [];
      }
      _chatMessages[chatId]!.add(message);

      // Notify listeners
      if (_chatControllers.containsKey(chatId)) {
        _chatControllers[chatId]!.add(_chatMessages[chatId]!);
      }

      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  // Send a location message
  Future<bool> sendLocationMessage({
    required String receiverId,
    required double latitude,
    required double longitude,
  }) async {
    return sendMessage(
      receiverId: receiverId,
      content: '$latitude,$longitude',
      type: MessageType.location,
    );
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String otherUserId) async {
    final currentUserId = await _getCurrentUserId();
    final chatId = _getChatId(currentUserId, otherUserId);

    if (_chatMessages.containsKey(chatId)) {
      bool updated = false;

      for (int i = 0; i < _chatMessages[chatId]!.length; i++) {
        final message = _chatMessages[chatId]![i];
        if (message.receiverId == currentUserId && !message.isRead) {
          _chatMessages[chatId]![i] = message.copyWith(isRead: true);
          updated = true;
        }
      }

      if (updated && _chatControllers.containsKey(chatId)) {
        _chatControllers[chatId]!.add(_chatMessages[chatId]!);
      }
    }
  }

  // Get unread message count
  Future<int> getUnreadMessageCount(String otherUserId) async {
    final currentUserId = await _getCurrentUserId();
    final chatId = _getChatId(currentUserId, otherUserId);

    if (_chatMessages.containsKey(chatId)) {
      return _chatMessages[chatId]!
          .where((msg) => msg.receiverId == currentUserId && !msg.isRead)
          .length;
    }

    return 0;
  }

  // Dispose resources
  void dispose() {
    for (final controller in _chatControllers.values) {
      controller.close();
    }
    _chatControllers.clear();
  }
}
