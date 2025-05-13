import 'package:flutter/material.dart';
import 'package:road_helperr/models/user_location.dart';
import 'package:road_helperr/models/user_rating.dart';
import 'package:road_helperr/services/api_service.dart';
import 'package:intl/intl.dart';

class UserRatingsBottomSheet extends StatefulWidget {
  final UserLocation user;

  const UserRatingsBottomSheet({
    super.key,
    required this.user,
  });

  static Future<void> show(BuildContext context, UserLocation user) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserRatingsBottomSheet(user: user),
    );
  }

  @override
  State<UserRatingsBottomSheet> createState() => _UserRatingsBottomSheetState();
}

class _UserRatingsBottomSheetState extends State<UserRatingsBottomSheet> {
  bool _isLoading = true;
  List<UserRating> _ratings = [];
  double _averageRating = 0;

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    try {
      final ratings = await ApiService.getUserRatings(widget.user.userId);
      final averageRating = await ApiService.getUserAverageRating(widget.user.userId);

      if (mounted) {
        setState(() {
          _ratings = ratings;
          _averageRating = averageRating;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading ratings: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;
    final cardWidth = isDesktop ? 600.0 : size.width;
    final maxHeight = size.height * 0.8;

    return Container(
      width: cardWidth,
      constraints: BoxConstraints(maxHeight: maxHeight),
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
            child: Text(
              'Ratings for ${widget.user.userName}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
          ),
          // Average rating
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildRatingStars(_averageRating),
                  const SizedBox(width: 8),
                  Text(
                    '(${_ratings.length} ${_ratings.length == 1 ? 'rating' : 'ratings'})',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          // Divider
          Divider(color: Colors.grey[300]),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _ratings.isEmpty
                    ? Center(
                        child: Text(
                          'No ratings yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _ratings.length,
                        itemBuilder: (context, index) {
                          return _buildRatingItem(_ratings[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 24);
        } else if (index < rating.ceil() && rating.floor() != rating.ceil()) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 24);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 24);
        }
      }),
    );
  }

  Widget _buildRatingItem(UserRating rating) {
    final date = DateFormat.yMMMd().format(rating.timestamp);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildRatingStars(rating.rating),
                const Spacer(),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (rating.comment != null && rating.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                rating.comment!,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
