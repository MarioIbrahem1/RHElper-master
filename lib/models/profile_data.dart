class ProfileData {
  final String name;
  final String email;
  final String? phone;
  final String? address;
  String? profileImage;
  final String? carModel;
  final String? carColor;
  final String? plateNumber;

  ProfileData({
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.profileImage,
    this.carModel,
    this.carColor,
    this.plateNumber,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      profileImage: json['profile_image'],
      carModel: json['car_model'],
      carColor: json['car_color'],
      plateNumber: json['plate_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'profile_image': profileImage,
      'car_model': carModel,
      'car_color': carColor,
      'plate_number': plateNumber,
    };
  }
}
