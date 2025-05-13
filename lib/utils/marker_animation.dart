import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:road_helperr/models/user_location.dart';

class MarkerAnimation {
  // Cache for previous positions
  static final Map<String, LatLng> _previousPositions = {};
  
  // Cache for animation timers
  static final Map<String, Timer> _animationTimers = {};
  
  // Dispose all animation timers
  static void disposeAll() {
    _animationTimers.forEach((_, timer) => timer.cancel());
    _animationTimers.clear();
  }
  
  // Animate marker movement
  static Future<Marker> animateMarkerMovement({
    required UserLocation user,
    required UserLocation previousUser,
    required BitmapDescriptor icon,
    required Function(Marker) onMarkerUpdated,
  }) async {
    // If no previous position, just return the marker at the current position
    if (previousUser.position == user.position) {
      return Marker(
        markerId: MarkerId(user.userId),
        position: user.position,
        infoWindow: InfoWindow(
          title: user.userName,
          snippet: user.carModel ?? (user.isOnline ? 'Online' : 'Offline'),
        ),
        icon: icon,
        rotation: _calculateRotation(previousUser.position, user.position),
      );
    }
    
    // Store the previous position
    _previousPositions[user.userId] = previousUser.position;
    
    // Cancel any existing animation for this user
    _animationTimers[user.userId]?.cancel();
    
    // Create a new marker at the current position
    final marker = Marker(
      markerId: MarkerId(user.userId),
      position: previousUser.position,
      infoWindow: InfoWindow(
        title: user.userName,
        snippet: user.carModel ?? (user.isOnline ? 'Online' : 'Offline'),
      ),
      icon: icon,
      rotation: _calculateRotation(previousUser.position, user.position),
    );
    
    // Start animation
    const totalSteps = 10;
    const animationDuration = Duration(milliseconds: 1000);
    const stepDuration = Duration(milliseconds: 100);
    
    final latDiff = (user.position.latitude - previousUser.position.latitude) / totalSteps;
    final lngDiff = (user.position.longitude - previousUser.position.longitude) / totalSteps;
    
    int step = 0;
    
    _animationTimers[user.userId] = Timer.periodic(stepDuration, (timer) {
      step++;
      
      if (step <= totalSteps) {
        final newLat = previousUser.position.latitude + (latDiff * step);
        final newLng = previousUser.position.longitude + (lngDiff * step);
        final newPosition = LatLng(newLat, newLng);
        
        final updatedMarker = Marker(
          markerId: MarkerId(user.userId),
          position: newPosition,
          infoWindow: InfoWindow(
            title: user.userName,
            snippet: user.carModel ?? (user.isOnline ? 'Online' : 'Offline'),
          ),
          icon: icon,
          rotation: _calculateRotation(previousUser.position, user.position),
        );
        
        onMarkerUpdated(updatedMarker);
      } else {
        // Animation complete
        timer.cancel();
        _animationTimers.remove(user.userId);
      }
    });
    
    return marker;
  }
  
  // Calculate rotation angle based on movement direction
  static double _calculateRotation(LatLng from, LatLng to) {
    if (from == to) return 0;
    
    final double deltaLng = to.longitude - from.longitude;
    final double deltaLat = to.latitude - from.latitude;
    
    // Calculate bearing angle in radians
    final double bearing = Math.atan2(deltaLng, deltaLat);
    
    // Convert to degrees
    double bearingDegrees = bearing * 180 / Math.pi;
    
    // Normalize to 0-360
    if (bearingDegrees < 0) {
      bearingDegrees += 360;
    }
    
    return bearingDegrees;
  }
}

// Math utilities
class Math {
  static double pi = 3.1415926535897932;
  
  static double atan2(double y, double x) {
    if (x > 0) {
      return _atan(y / x);
    } else if (x < 0) {
      return y >= 0 ? _atan(y / x) + pi : _atan(y / x) - pi;
    } else {
      return y > 0 ? pi / 2 : -pi / 2;
    }
  }
  
  static double _atan(double x) {
    // Simple atan implementation using Taylor series
    if (x.abs() > 1) {
      return (pi / 2) * x.sign - _atan(1 / x);
    }
    
    double result = 0;
    double term = x;
    double x2 = x * x;
    double denominator = 1;
    
    for (int i = 0; i < 10; i++) {
      result += term / denominator;
      term = -term * x2;
      denominator += 2;
    }
    
    return result;
  }
}
