import 'package:google_maps_flutter/google_maps_flutter.dart';

enum HelpRequestStatus {
  pending,
  accepted,
  rejected,
  completed,
  cancelled,
}

class HelpRequest {
  final String requestId;
  final String senderId;
  final String senderName;
  final String? senderPhone;
  final String? senderCarModel;
  final String? senderCarColor;
  final String? senderPlateNumber;
  final LatLng senderLocation;
  final String receiverId;
  final String receiverName;
  final String? receiverPhone;
  final String? receiverCarModel;
  final String? receiverCarColor;
  final String? receiverPlateNumber;
  final LatLng receiverLocation;
  final DateTime timestamp;
  final HelpRequestStatus status;
  final String? message;

  HelpRequest({
    required this.requestId,
    required this.senderId,
    required this.senderName,
    this.senderPhone,
    this.senderCarModel,
    this.senderCarColor,
    this.senderPlateNumber,
    required this.senderLocation,
    required this.receiverId,
    required this.receiverName,
    this.receiverPhone,
    this.receiverCarModel,
    this.receiverCarColor,
    this.receiverPlateNumber,
    required this.receiverLocation,
    required this.timestamp,
    required this.status,
    this.message,
  });

  factory HelpRequest.fromJson(Map<String, dynamic> json) {
    return HelpRequest(
      requestId: json['requestId'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      senderPhone: json['senderPhone'],
      senderCarModel: json['senderCarModel'],
      senderCarColor: json['senderCarColor'],
      senderPlateNumber: json['senderPlateNumber'],
      senderLocation: LatLng(
        json['senderLocation']['latitude'],
        json['senderLocation']['longitude'],
      ),
      receiverId: json['receiverId'],
      receiverName: json['receiverName'],
      receiverPhone: json['receiverPhone'],
      receiverCarModel: json['receiverCarModel'],
      receiverCarColor: json['receiverCarColor'],
      receiverPlateNumber: json['receiverPlateNumber'],
      receiverLocation: LatLng(
        json['receiverLocation']['latitude'],
        json['receiverLocation']['longitude'],
      ),
      timestamp: DateTime.parse(json['timestamp']),
      status: HelpRequestStatus.values.firstWhere(
        (e) => e.toString() == 'HelpRequestStatus.${json['status']}',
        orElse: () => HelpRequestStatus.pending,
      ),
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhone': senderPhone,
      'senderCarModel': senderCarModel,
      'senderCarColor': senderCarColor,
      'senderPlateNumber': senderPlateNumber,
      'senderLocation': {
        'latitude': senderLocation.latitude,
        'longitude': senderLocation.longitude,
      },
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'receiverCarModel': receiverCarModel,
      'receiverCarColor': receiverCarColor,
      'receiverPlateNumber': receiverPlateNumber,
      'receiverLocation': {
        'latitude': receiverLocation.latitude,
        'longitude': receiverLocation.longitude,
      },
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString().split('.').last,
      'message': message,
    };
  }
}
