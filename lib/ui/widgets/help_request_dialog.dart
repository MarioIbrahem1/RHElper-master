import 'package:flutter/material.dart';
import 'package:road_helperr/models/help_request.dart';
import 'package:road_helperr/services/hybrid_help_request_service.dart';
import 'package:road_helperr/services/notification_service.dart';
import 'package:road_helperr/utils/app_colors.dart';
import 'package:road_helperr/utils/message_utils.dart';

class HelpRequestDialog extends StatefulWidget {
  final HelpRequest request;

  const HelpRequestDialog({
    super.key,
    required this.request,
  });

  static Future<bool?> show(BuildContext context, HelpRequest request) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => HelpRequestDialog(request: request),
    );
  }

  @override
  State<HelpRequestDialog> createState() => _HelpRequestDialogState();
}

class _HelpRequestDialogState extends State<HelpRequestDialog> {
  bool _isLoading = false;

  Future<void> _respondToRequest(bool accept) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await HybridHelpRequestService().respondToHelpRequest(
        requestId: widget.request.requestId,
        accept: accept,
        estimatedArrival: accept ? '10-15 minutes' : null,
      );

      if (mounted) {
        Navigator.of(context).pop(accept);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        NotificationService.showError(
          context: context,
          title: "Error",
          message: 'Failed to respond to help request: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Help Request'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You have received a help request from:',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Name', widget.request.senderName),
          if (widget.request.senderCarModel != null)
            _buildInfoRow('Car', widget.request.senderCarModel!),
          if (widget.request.senderCarColor != null)
            _buildInfoRow('Color', widget.request.senderCarColor!),
          if (widget.request.message != null &&
              widget.request.message!.isNotEmpty)
            _buildInfoRow('Message', widget.request.message!),
          const SizedBox(height: 8),
          Text(
            'Distance: ${_calculateDistance()} km away',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => _respondToRequest(false),
          child: Text(
            'Decline',
            style: TextStyle(
              color: MessageUtils.getErrorColor(context),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _respondToRequest(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.getSwitchColor(context),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Accept',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _calculateDistance() {
    // Calculate the distance between sender and receiver
    // This is a simplified calculation - in a real app, you would use
    // the Haversine formula or a mapping service API
    final lat1 = widget.request.senderLocation.latitude;
    final lon1 = widget.request.senderLocation.longitude;
    final lat2 = widget.request.receiverLocation.latitude;
    final lon2 = widget.request.receiverLocation.longitude;

    // Simple Euclidean distance (not accurate for long distances)
    final distance = _haversineDistance(lat1, lon1, lat2, lon2);
    return distance.toStringAsFixed(1);
  }

  // Haversine formula to calculate distance between two points on Earth
  double _haversineDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Earth radius in kilometers
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) *
            _cos(_toRadians(lat2)) *
            _sin(dLon / 2) *
            _sin(dLon / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) {
    return degree * (3.141592653589793 / 180.0);
  }

  double _sin(double x) {
    return _sinLookup(x);
  }

  double _cos(double x) {
    return _sinLookup(x + 3.141592653589793 / 2);
  }

  double _sinLookup(double x) {
    // Simple sin implementation
    return x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  }

  double _sqrt(double x) {
    // Simple square root implementation using Newton's method
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _atan2(double y, double x) {
    // Simple atan2 implementation
    if (x > 0) {
      return _atan(y / x);
    } else if (x < 0) {
      return y >= 0
          ? _atan(y / x) + 3.141592653589793
          : _atan(y / x) - 3.141592653589793;
    } else {
      return y > 0 ? 3.141592653589793 / 2 : -3.141592653589793 / 2;
    }
  }

  double _atan(double x) {
    // Simple atan implementation
    return x - (x * x * x) / 3 + (x * x * x * x * x) / 5;
  }
}
