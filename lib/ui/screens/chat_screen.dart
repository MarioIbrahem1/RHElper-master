import 'package:flutter/material.dart';
import 'package:road_helperr/models/chat_message.dart';
import 'package:road_helperr/models/user_location.dart';
import 'package:road_helperr/services/chat_service.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

class ChatScreen extends StatefulWidget {
  final UserLocation otherUser;

  const ChatScreen({
    super.key,
    required this.otherUser,
  });

  static const String routeName = "chat";

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Mark messages as read when opening the chat
    _chatService.markMessagesAsRead(widget.otherUser.userId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      final success = await _chatService.sendMessage(
        receiverId: widget.otherUser.userId,
        content: message,
      );

      if (success) {
        _messageController.clear();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send message')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _sendLocationMessage() async {
    setState(() {
      _isSending = true;
    });

    try {
      final position = await Geolocator.getCurrentPosition();

      final success = await _chatService.sendLocationMessage(
        receiverId: widget.otherUser.userId,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send location')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending location: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                widget.otherUser.userName.isNotEmpty
                    ? widget.otherUser.userName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUser.userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.otherUser.carModel != null)
                  Text(
                    widget.otherUser.carModel!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show user details
              _showUserDetails(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: FutureBuilder<Stream<List<ChatMessage>>>(
              future: _chatService.getChatStream(widget.otherUser.userId),
              builder: (context, streamSnapshot) {
                if (streamSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (streamSnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading messages: ${streamSnapshot.error}',
                      style: TextStyle(
                        color: Colors.red[600],
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                if (!streamSnapshot.hasData) {
                  return Center(
                    child: Text(
                      'No messages available',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                return StreamBuilder<List<ChatMessage>>(
                  stream: streamSnapshot.data!,
                  builder: (context, messagesSnapshot) {
                    if (messagesSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!messagesSnapshot.hasData ||
                        messagesSnapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'No messages yet. Say hello!',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      );
                    }

                    final messages = messagesSnapshot.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[messages.length - 1 - index];
                        return _buildMessageItem(context, message);
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.location_on),
                  onPressed: _isSending ? null : _sendLocationMessage,
                  color: Colors.blue,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: _isSending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  onPressed: _isSending ? null : _sendMessage,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(BuildContext context, ChatMessage message) {
    final isMe = message.senderId != widget.otherUser.userId;
    final messageTime = DateFormat.Hm().format(message.timestamp);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.type == MessageType.text)
              Text(
                message.content,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black,
                  fontSize: 16,
                ),
              )
            else if (message.type == MessageType.location)
              _buildLocationMessage(context, message, isMe),
            const SizedBox(height: 4),
            Text(
              messageTime,
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationMessage(
    BuildContext context,
    ChatMessage message,
    bool isMe,
  ) {
    try {
      final parts = message.content.split(',');
      final latitude = double.parse(parts[0]);
      final longitude = double.parse(parts[1]);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location shared',
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              // Show location on map
              _showLocationOnMap(context, latitude, longitude);
            },
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[300],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    // Instead of using Google Maps Static API which requires an API key,
                    // we'll just show a placeholder
                    Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 50,
                              color: Colors.red[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Location: $latitude, $longitude',
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        color: Colors.black.withOpacity(0.5),
                        child: const Text(
                          'Tap to view on map',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    } catch (e) {
      return Text(
        'Invalid location data',
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black,
          fontSize: 16,
        ),
      );
    }
  }

  void _showLocationOnMap(
      BuildContext context, double latitude, double longitude) {
    // Navigate to map screen with the location
    // This is a placeholder - implement according to your app's navigation
    debugPrint('Show location on map: $latitude, $longitude');
  }

  void _showUserDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'User Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 20),
              _buildDetailItem(
                context,
                'Name',
                widget.otherUser.userName,
                Icons.person,
              ),
              if (widget.otherUser.carModel != null) ...[
                const SizedBox(height: 12),
                _buildDetailItem(
                  context,
                  'Car Model',
                  widget.otherUser.carModel!,
                  Icons.directions_car,
                ),
              ],
              if (widget.otherUser.carColor != null) ...[
                const SizedBox(height: 12),
                _buildDetailItem(
                  context,
                  'Car Color',
                  widget.otherUser.carColor!,
                  Icons.color_lens,
                ),
              ],
              if (widget.otherUser.plateNumber != null) ...[
                const SizedBox(height: 12),
                _buildDetailItem(
                  context,
                  'Plate Number',
                  widget.otherUser.plateNumber!,
                  Icons.confirmation_number,
                ),
              ],
              if (widget.otherUser.phone != null) ...[
                const SizedBox(height: 12),
                _buildDetailItem(
                  context,
                  'Phone',
                  widget.otherUser.phone!,
                  Icons.phone,
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.blue,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
