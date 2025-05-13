import 'package:flutter/material.dart';
import 'package:road_helperr/models/user_location.dart';
import 'package:road_helperr/services/api_service.dart';
import 'package:road_helperr/services/notification_service.dart';
import 'package:road_helperr/utils/app_colors.dart';

class UserRatingDialog extends StatefulWidget {
  final UserLocation user;

  const UserRatingDialog({
    super.key,
    required this.user,
  });

  static Future<bool?> show(BuildContext context, UserLocation user) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => UserRatingDialog(user: user),
    );
  }

  @override
  State<UserRatingDialog> createState() => _UserRatingDialogState();
}

class _UserRatingDialogState extends State<UserRatingDialog> {
  double _rating = 5.0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ApiService.rateUser(
        userId: widget.user.userId,
        rating: _rating,
        comment: _commentController.text.isNotEmpty ? _commentController.text : null,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        NotificationService.showSuccess(
          context: context,
          title: 'Rating Submitted',
          message: 'Thank you for rating ${widget.user.userName}!',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        NotificationService.showError(
          context: context,
          title: 'Error',
          message: 'Failed to submit rating: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rate ${widget.user.userName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'How would you rate your experience?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            _buildRatingStars(),
            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Comment (optional)',
                border: OutlineInputBorder(),
                hintText: 'Share your experience...',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitRating,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.getSwitchColor(context),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Submit',
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }

  Widget _buildRatingStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < _rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 36,
          ),
          onPressed: () {
            setState(() {
              _rating = index + 1;
            });
          },
        );
      }),
    );
  }
}
