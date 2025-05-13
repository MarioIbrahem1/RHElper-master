import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Get a more accurate position stream with better settings
  Stream<Position> get positionStream => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update if moved 10 meters
          timeLimit: Duration(seconds: 15),
        ),
      );

  // Check and request location permission with better error handling
  Future<LocationPermission> checkLocationPermission() async {
    debugPrint('Checking location permission...');

    // First check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled');
      return Future.error(
          'Location services are disabled. Please enable GPS in your device settings.');
    }

    // Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();
    debugPrint('Current location permission status: $permission');

    // Request permission if denied
    if (permission == LocationPermission.denied) {
      debugPrint('Location permission denied, requesting permission...');
      permission = await Geolocator.requestPermission();
      debugPrint('New location permission status: $permission');

      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    // Handle permanently denied permission
    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permission permanently denied');
      return Future.error(
          'Location permissions are permanently denied. Please enable them in app settings.');
    }

    debugPrint('Location permission granted: $permission');
    return permission;
  }

  // Check if location service is enabled
  Future<bool> isLocationServiceEnabled() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    debugPrint('Location services enabled: $enabled');
    return enabled;
  }

  // Get current position with better error handling
  Future<Position> getCurrentPosition() async {
    debugPrint('Getting current position...');

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );

      debugPrint(
          'Current position: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('Error getting current position: $e');
      rethrow;
    }
  }
}
