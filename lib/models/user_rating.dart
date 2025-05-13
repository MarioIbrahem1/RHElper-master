class UserRating {
  final String id;
  final String userId;
  final String ratedByUserId;
  final double rating;
  final String? comment;
  final DateTime timestamp;

  UserRating({
    required this.id,
    required this.userId,
    required this.ratedByUserId,
    required this.rating,
    this.comment,
    required this.timestamp,
  });

  factory UserRating.fromJson(Map<String, dynamic> json) {
    return UserRating(
      id: json['id'],
      userId: json['userId'],
      ratedByUserId: json['ratedByUserId'],
      rating: json['rating'].toDouble(),
      comment: json['comment'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'ratedByUserId': ratedByUserId,
      'rating': rating,
      'comment': comment,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
