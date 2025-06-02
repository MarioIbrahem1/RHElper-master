import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserLocation {
  final String userId;
  final String userName;
  final String email;
  final LatLng position;
  final String? profileImage;
  final String? profileImageUrl;
  final bool isOnline;
  final bool isAvailableForHelp;
  final String? phone;
  final String? carModel;
  final String? carColor;
  final String? plateNumber;
  final BitmapDescriptor? markerIcon;
  final DateTime lastSeen;
  final double rating;
  final int totalRatings;

  UserLocation({
    required this.userId,
    required this.userName,
    required this.email,
    required this.position,
    this.profileImage,
    this.profileImageUrl,
    this.isOnline = true,
    this.isAvailableForHelp = true,
    this.phone,
    this.carModel,
    this.carColor,
    this.plateNumber,
    this.markerIcon,
    required this.lastSeen,
    this.rating = 0.0,
    this.totalRatings = 0,
  });

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      userId: json['userId'],
      userName: json['userName'],
      email: json['email'] ?? '',
      position: LatLng(
        json['position']['latitude'],
        json['position']['longitude'],
      ),
      profileImage: json['profileImage'],
      profileImageUrl: json['profileImageUrl'],
      isOnline: json['isOnline'] ?? true,
      isAvailableForHelp: json['isAvailableForHelp'] ?? true,
      phone: json['phone'],
      carModel: json['carModel'],
      carColor: json['carColor'],
      plateNumber: json['plateNumber'],
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'])
          : DateTime.now(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['totalRatings'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'email': email,
      'position': {
        'latitude': position.latitude,
        'longitude': position.longitude,
      },
      'profileImage': profileImage,
      'profileImageUrl': profileImageUrl,
      'isOnline': isOnline,
      'isAvailableForHelp': isAvailableForHelp,
      'phone': phone,
      'carModel': carModel,
      'carColor': carColor,
      'plateNumber': plateNumber,
      'lastSeen': lastSeen.toIso8601String(),
      'rating': rating,
      'totalRatings': totalRatings,
    };
  }

  // Create a copy of this UserLocation with some fields replaced
  UserLocation copyWith({
    String? userId,
    String? userName,
    String? email,
    LatLng? position,
    String? profileImage,
    String? profileImageUrl,
    bool? isOnline,
    bool? isAvailableForHelp,
    String? phone,
    String? carModel,
    String? carColor,
    String? plateNumber,
    BitmapDescriptor? markerIcon,
    DateTime? lastSeen,
    double? rating,
    int? totalRatings,
  }) {
    return UserLocation(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      position: position ?? this.position,
      profileImage: profileImage ?? this.profileImage,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isOnline: isOnline ?? this.isOnline,
      isAvailableForHelp: isAvailableForHelp ?? this.isAvailableForHelp,
      phone: phone ?? this.phone,
      carModel: carModel ?? this.carModel,
      carColor: carColor ?? this.carColor,
      plateNumber: plateNumber ?? this.plateNumber,
      markerIcon: markerIcon ?? this.markerIcon,
      lastSeen: lastSeen ?? this.lastSeen,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
    );
  }
}
