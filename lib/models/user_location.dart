import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserLocation {
  final String userId;
  final String userName;
  final LatLng position;
  final String? profileImage;
  final bool isOnline;
  final String? phone;
  final String? carModel;
  final String? carColor;
  final String? plateNumber;
  final BitmapDescriptor? markerIcon;

  UserLocation({
    required this.userId,
    required this.userName,
    required this.position,
    this.profileImage,
    this.isOnline = true,
    this.phone,
    this.carModel,
    this.carColor,
    this.plateNumber,
    this.markerIcon,
  });

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      userId: json['userId'],
      userName: json['userName'],
      position: LatLng(
        json['position']['latitude'],
        json['position']['longitude'],
      ),
      profileImage: json['profileImage'],
      isOnline: json['isOnline'] ?? true,
      phone: json['phone'],
      carModel: json['carModel'],
      carColor: json['carColor'],
      plateNumber: json['plateNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'position': {
        'latitude': position.latitude,
        'longitude': position.longitude,
      },
      'profileImage': profileImage,
      'isOnline': isOnline,
      'phone': phone,
      'carModel': carModel,
      'carColor': carColor,
      'plateNumber': plateNumber,
    };
  }

  // Create a copy of this UserLocation with some fields replaced
  UserLocation copyWith({
    String? userId,
    String? userName,
    LatLng? position,
    String? profileImage,
    bool? isOnline,
    String? phone,
    String? carModel,
    String? carColor,
    String? plateNumber,
    BitmapDescriptor? markerIcon,
  }) {
    return UserLocation(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      position: position ?? this.position,
      profileImage: profileImage ?? this.profileImage,
      isOnline: isOnline ?? this.isOnline,
      phone: phone ?? this.phone,
      carModel: carModel ?? this.carModel,
      carColor: carColor ?? this.carColor,
      plateNumber: plateNumber ?? this.plateNumber,
      markerIcon: markerIcon ?? this.markerIcon,
    );
  }
}
