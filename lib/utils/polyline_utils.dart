import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Utility class for handling polylines
class PolylineUtils {
  /// Decode an encoded polyline string into a list of LatLng points
  /// This is an improved implementation that handles Google's polyline encoding format
  static List<LatLng> decodePolyline(String encoded) {
    if (encoded.isEmpty) {
      debugPrint('Warning: Empty polyline string provided');
      return [];
    }

    try {
      List<LatLng> poly = [];
      int index = 0, len = encoded.length;
      int lat = 0, lng = 0;

      debugPrint('Decoding polyline with length: ${encoded.length}');

      while (index < len) {
        int b, shift = 0, result = 0;
        do {
          if (index >= len) {
            debugPrint('Warning: Unexpected end of polyline string');
            break;
          }
          b = encoded.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);

        int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lat += dlat;

        shift = 0;
        result = 0;
        do {
          if (index >= len) {
            debugPrint('Warning: Unexpected end of polyline string');
            break;
          }
          b = encoded.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);

        int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lng += dlng;

        double latitude = lat * 1e-5;
        double longitude = lng * 1e-5;

        // Validate coordinates before adding
        if (latitude >= -90 &&
            latitude <= 90 &&
            longitude >= -180 &&
            longitude <= 180) {
          poly.add(LatLng(latitude, longitude));
        } else {
          debugPrint(
              'Warning: Invalid coordinates in polyline: $latitude, $longitude');
        }
      }

      debugPrint('Successfully decoded ${poly.length} points from polyline');

      // Additional validation - ensure we have enough points for a valid route
      if (poly.length < 2) {
        debugPrint(
            'Warning: Not enough points for a valid route (${poly.length} points)');
      }

      // Add additional validation to ensure route is reasonable
      if (poly.length > 2) {
        // Check for any extreme jumps in the route that might indicate encoding issues
        for (int i = 1; i < poly.length; i++) {
          final distance = calculateDistance(poly[i - 1], poly[i]);
          // If any two consecutive points are more than 50km apart, that's suspicious
          if (distance > 50000) {
            debugPrint(
                'Warning: Suspicious jump in route of ${distance / 1000}km between points ${i - 1} and $i');
            // We don't filter these points out as they might be legitimate in some cases
            // but this helps with debugging
          }
        }
      }

      return poly;
    } catch (e) {
      debugPrint('Error decoding polyline: $e');
      return [];
    }
  }

  /// Calculate the distance between two LatLng points in meters
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // meters
    double lat1 = point1.latitude * pi / 180;
    double lat2 = point2.latitude * pi / 180;
    double lon1 = point1.longitude * pi / 180;
    double lon2 = point2.longitude * pi / 180;

    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }

  /// Format distance in meters to a human-readable string
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toInt()} م';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} كم';
    }
  }

  /// Format duration in seconds to a human-readable string
  static String formatDuration(int durationInSeconds) {
    if (durationInSeconds < 60) {
      return '$durationInSeconds ثانية';
    } else if (durationInSeconds < 3600) {
      int minutes = (durationInSeconds / 60).floor();
      return '$minutes دقيقة';
    } else {
      int hours = (durationInSeconds / 3600).floor();
      int minutes = ((durationInSeconds % 3600) / 60).floor();
      return '$hours ساعة ${minutes > 0 ? ' و $minutes دقيقة' : ''}';
    }
  }
}
