import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:road_helperr/models/user_location.dart';
import 'package:road_helperr/services/hybrid_help_request_service.dart';
import 'package:road_helperr/services/notification_service.dart';
import 'package:road_helperr/ui/screens/chat_screen.dart';
import 'package:road_helperr/ui/widgets/user_rating_dialog.dart';
import 'package:road_helperr/ui/widgets/user_ratings_bottom_sheet.dart';
import 'package:road_helperr/utils/app_colors.dart';

class UserDetailsBottomSheet extends StatefulWidget {
  final UserLocation user;
  final LatLng currentUserLocation;

  const UserDetailsBottomSheet({
    super.key,
    required this.user,
    required this.currentUserLocation,
  });

  static Future<void> show(
    BuildContext context,
    UserLocation user,
    LatLng currentUserLocation,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserDetailsBottomSheet(
        user: user,
        currentUserLocation: currentUserLocation,
      ),
    );
  }

  @override
  State<UserDetailsBottomSheet> createState() => _UserDetailsBottomSheetState();
}

class _UserDetailsBottomSheetState extends State<UserDetailsBottomSheet> {
  bool _isLoading = false;
  bool _isSendingRequest = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (widget.user.userId.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch additional user data if needed
      // For now, we'll just use the data from the UserLocation object
      setState(() {
        _isLoading = false;
        _userData = {
          'name': widget.user.userName,
          'carModel': widget.user.carModel ?? 'Unknown',
          'carColor': widget.user.carColor ?? 'Unknown',
          'plateNumber': widget.user.plateNumber ?? 'Unknown',
        };
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching user data: $e')),
        );
      }
    }
  }

  Future<void> _sendHelpRequest() async {
    if (_isSendingRequest) return;

    setState(() {
      _isSendingRequest = true;
    });

    try {
      await HybridHelpRequestService().sendHelpRequest(
        receiverId: widget.user.userId,
        receiverName: widget.user.userName,
        senderLocation: widget.currentUserLocation,
        receiverLocation: widget.user.position,
        message: 'I need help with my car. Can you assist me?',
      );

      if (mounted) {
        setState(() {
          _isSendingRequest = false;
        });

        // Close the bottom sheet
        Navigator.of(context).pop();

        // Show success message
        NotificationService.showSuccess(
          context: context,
          title: 'Help Request Sent',
          message:
              'Your help request has been sent to ${widget.user.userName}. You will be notified when they respond.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSendingRequest = false;
        });
        NotificationService.showError(
          context: context,
          title: 'Error',
          message: 'Failed to send help request: $e',
        );
      }
    }
  }

  void _openChat() {
    Navigator.of(context).pop();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(otherUser: widget.user),
      ),
    );
  }

  void _showRatingDialog() async {
    final result = await UserRatingDialog.show(context, widget.user);
    if (result == true) {
      // Rating submitted successfully
      _fetchUserData(); // Refresh user data to show updated rating
    }
  }

  void _showRatings() {
    UserRatingsBottomSheet.show(context, widget.user);
  }

  Future<void> _createRouteToUser() async {
    Navigator.of(context).pop();

    // Get the MapController from context or through a callback
    // This is a placeholder - implement according to your app's structure
    // mapController.createRouteToUser(widget.user);

    NotificationService.showSuccess(
      context: context,
      title: 'Route Created',
      message: 'Route to ${widget.user.userName} has been created.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;
    final cardWidth = isDesktop ? 600.0 : size.width;

    return Container(
      width: cardWidth,
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop ? (size.width - cardWidth) / 2 : 0,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'User Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.star, color: Colors.amber),
                      onPressed: _showRatings,
                      tooltip: 'View Ratings',
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat, color: Colors.blue),
                      onPressed: _openChat,
                      tooltip: 'Chat',
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            )
          else if (_userData != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    context,
                    'Name',
                    _userData!['name'] ?? 'Unknown',
                    Icons.person,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    'Car Model',
                    _userData!['carModel'] ?? 'Unknown',
                    Icons.directions_car,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    'Car Color',
                    _userData!['carColor'] ?? 'Unknown',
                    Icons.color_lens,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    'Plate Number',
                    _userData!['plateNumber'] ?? 'Unknown',
                    Icons.confirmation_number,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _createRouteToUser,
                          icon:
                              const Icon(Icons.directions, color: Colors.white),
                          label: const Text(
                            'Navigate',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showRatingDialog,
                          icon: const Icon(Icons.star, color: Colors.white),
                          label: const Text(
                            'Rate',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSendingRequest ? null : _sendHelpRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.getSwitchColor(context),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSendingRequest
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Send Help Request',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('No user data available'),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.getSwitchColor(context),
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
