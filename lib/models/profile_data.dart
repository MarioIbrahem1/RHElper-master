import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileData {
  final String name;
  final String email;
  final String? phone;
  final String? address;
  String? profileImage;
  final String? carModel;
  final String? carColor;
  final String? plateNumber;

  // Keys for SharedPreferences
  static const String _profileDataKey = 'cached_profile_data';
  static const String _profileImageKey = 'cached_profile_image';
  static const String _profileLastFetchedKey = 'profile_last_fetched';

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

  // Save profile data to SharedPreferences
  Future<void> saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileDataKey, jsonEncode(toJson()));

      // Save the profile image URL separately for quick access
      if (profileImage != null && profileImage!.isNotEmpty) {
        await prefs.setString(_profileImageKey, profileImage!);
      }

      // Save the timestamp when the data was cached
      await prefs.setInt(
          _profileLastFetchedKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error saving profile data to cache: $e');
    }
  }

  // Load profile data from SharedPreferences
  static Future<ProfileData?> loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_profileDataKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> json = jsonDecode(jsonString);
        return ProfileData.fromJson(json);
      }
      return null;
    } catch (e) {
      debugPrint('Error loading profile data from cache: $e');
      return null;
    }
  }

  // Get cached profile image URL
  static Future<String?> getCachedImageUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // First try to get from the profile data
      final jsonString = prefs.getString(_profileDataKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> json = jsonDecode(jsonString);
        return json['profile_image'];
      }

      // If not found in profile data, try the direct key
      return prefs.getString('cached_profile_image');
    } catch (e) {
      debugPrint('Error getting cached profile image URL: $e');
      return null;
    }
  }

  // Check if cached data exists and is not too old (24 hours)
  static Future<bool> hasFreshCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetched = prefs.getInt(_profileLastFetchedKey);

      if (lastFetched == null) return false;

      final now = DateTime.now().millisecondsSinceEpoch;
      final difference = now - lastFetched;

      // Return true if data was cached less than 24 hours ago
      return difference < const Duration(hours: 24).inMilliseconds;
    } catch (e) {
      debugPrint('Error checking cached data freshness: $e');
      return false;
    }
  }

  // Clear cached profile data
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileDataKey);
      await prefs.remove(_profileImageKey);
      await prefs.remove(_profileLastFetchedKey);
    } catch (e) {
      debugPrint('Error clearing profile data cache: $e');
    }
  }
}
