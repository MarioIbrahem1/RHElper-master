import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:road_helperr/utils/text_strings.dart';

class PlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  static const String _apiKey =
      'AIzaSyDGm9ZQELEZjPCOQWx2lxOOu5DDElcLc4Y'; // استبدل هذا بمفتاح API الخاص بك

  // البحث عن الأماكن القريبة
  static Future<List<Map<String, dynamic>>> searchNearbyPlaces({
    required double latitude,
    required double longitude,
    required double radius,
    required List<String> types,
    String? keyword,
    String? pageToken,
    bool fetchAllPages = true,
  }) async {
    try {
      // إذا كان هناك pageToken، يجب الانتظار قليلاً قبل استخدامه (حسب توثيق Google)
      if (pageToken != null) {
        await Future.delayed(const Duration(seconds: 2));
      }

      // بناء URL الأساسي
      String url =
          '$_baseUrl/nearbysearch/json?location=$latitude,$longitude&radius=$radius&key=$_apiKey';

      // إضافة types إذا كانت متوفرة
      if (types.isNotEmpty) {
        final typesString = types.join('|');
        url += '&type=$typesString';
      }

      // تحسين البحث عن طريق إضافة rankby=distance للحصول على أقرب النتائج
      // ملاحظة: لا يمكن استخدام radius مع rankby=distance حسب توثيق Google
      // لذلك نستخدم هذا فقط في حالات معينة
      if ((types.contains('car_repair') || types.contains('car_dealer')) &&
          keyword != null &&
          (keyword.contains('winch') ||
              keyword.contains('ونش') ||
              keyword.contains('tow') ||
              keyword.contains('سطحة') ||
              keyword.contains('سحب') ||
              keyword.contains('recovery'))) {
        // إزالة radius من URL لأنه لا يمكن استخدامه مع rankby=distance
        url = url.replaceAll(RegExp(r'&radius=\d+'), '');
        url += '&rankby=distance';
      }

      // إضافة keyword إذا كان متوفراً
      if (keyword != null && keyword.isNotEmpty) {
        url += '&keyword=${Uri.encodeComponent(keyword)}';
      }

      // إضافة pageToken إذا كان متوفراً
      if (pageToken != null) {
        url += '&pagetoken=$pageToken';
      }

      print('🔍 Places API Request:');
      print('URL: $url');
      print('Types: $types');
      print('Keyword: $keyword');
      print('Location: $latitude, $longitude');
      print('Radius: $radius meters');
      print('Page Token: $pageToken');

      // إجراء طلب HTTP
      final response = await http.get(Uri.parse(url));

      print('📡 Places API Response:');
      print('Status Code: ${response.statusCode}');

      // التحقق من صحة الاستجابة
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // التحقق من حالة API
        if (data['status'] == 'OK') {
          final results = List<Map<String, dynamic>>.from(data['results']);
          print(
              '✅ Found ${results.length} places for types: $types, keyword: $keyword');

          // طباعة النتيجة الأولى للتصحيح
          if (results.isNotEmpty) {
            print(
                'First result: ${results[0]['name']} at ${results[0]['geometry']['location']}');
          }

          // التحقق من وجود صفحة تالية
          final nextPageToken = data['next_page_token'];

          // إذا كان هناك صفحة تالية وتم طلب جميع الصفحات
          if (nextPageToken != null && fetchAllPages) {
            print('📄 Next page token found: $nextPageToken');

            // الحصول على نتائج الصفحة التالية
            final nextPageResults = await searchNearbyPlaces(
              latitude: latitude,
              longitude: longitude,
              radius: radius,
              types: types,
              keyword: keyword,
              pageToken: nextPageToken,
              fetchAllPages: fetchAllPages,
            );

            // دمج النتائج
            results.addAll(nextPageResults);
            print('📊 Total results after pagination: ${results.length}');
          }

          return results;
        } else {
          print('❌ API Error: ${data['status']}');
          if (data.containsKey('error_message')) {
            print('Error Message: ${data['error_message']}');
          }

          // إرجاع قائمة فارغة في حالة خطأ API
          return [];
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('Response Body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Exception in searchNearbyPlaces: $e');
      return [];
    }
  }

  // الحصول على تفاصيل مكان معين
  static Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    try {
      // إضافة المزيد من الحقول للحصول على معلومات أكثر تفصيلاً
      final url =
          '$_baseUrl/details/json?place_id=$placeId&fields=name,formatted_address,geometry,rating,opening_hours,photos,types,business_status,formatted_phone_number,international_phone_number,website,url,reviews&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final result = data['result'];

          // إضافة معلومات إضافية للتصنيف
          if (result.containsKey('types') && result['types'] is List) {
            final types = result['types'] as List;

            // تحديد نوع المكان بشكل أكثر دقة
            if (types.contains('gas_station')) {
              result['place_category'] = 'محطة بنزين';
            } else if ((types.contains('car_repair') ||
                    types.contains('car_dealer')) &&
                (result['name'].toString().toLowerCase().contains('ونش') ||
                    result['name'].toString().toLowerCase().contains('winch') ||
                    result['name'].toString().toLowerCase().contains('tow') ||
                    result['name'].toString().toLowerCase().contains('سطحة') ||
                    result['name'].toString().toLowerCase().contains('سحب') ||
                    result['name']
                        .toString()
                        .toLowerCase()
                        .contains('recovery'))) {
              result['place_category'] = 'ونش إنقاذ سيارات';
            }
          }

          return result;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting place details: $e');
      return null;
    }
  }

  // الحصول على صورة مكان معين
  static String getPlacePhotoUrl(String photoReference, {int maxWidth = 400}) {
    return '$_baseUrl/photo?maxwidth=$maxWidth&photo_reference=$photoReference&key=$_apiKey';
  }

  // تحويل نوع الفلتر إلى نوع Places API
  static Map<String, dynamic> getPlaceTypeAndKeyword(String filterType) {
    switch (filterType) {
      case TextStrings.homeGas:
        return {
          'type': 'gas_station',
          'keyword': 'petrol station fuel محطة بنزين وقود',
        };
      case TextStrings.homePolice:
        return {
          'type': 'police',
          'keyword': 'police قسم شرطة',
        };
      case TextStrings.homeFire:
        return {
          'type': 'fire_station',
          'keyword': 'fire station مطافي',
        };
      case TextStrings.homeHospital:
        return {
          'type': 'hospital',
          'keyword': 'hospital مستشفى',
        };
      case TextStrings.homeMaintenance:
        return {
          'type': 'car_repair',
          'keyword': 'car repair auto service مركز صيانة ورشة',
        };
      case TextStrings.homeWinch:
        return {
          'type': 'car_dealer',
          'keyword':
              'tow truck winch recovery towing service ونش انقاذ سيارات سطحة سحب',
        };
      default:
        print('❌ Unknown filter type: $filterType');
        return {
          'type': '',
          'keyword': '',
        };
    }
  }

  // للتوافق مع الكود القديم
  static String getPlaceType(String filterType) {
    return getPlaceTypeAndKeyword(filterType)['type'];
  }

  // استخدام Distance Matrix API لحساب المسافة ووقت الوصول
  static Future<Map<String, dynamic>> getDistanceMatrix({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String mode = 'driving', // driving, walking, bicycling, transit
  }) async {
    try {
      final String url =
          'https://maps.googleapis.com/maps/api/distancematrix/json'
          '?origins=$originLat,$originLng'
          '&destinations=$destLat,$destLng'
          '&mode=$mode'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final elements = data['rows'][0]['elements'][0];

          if (elements['status'] == 'OK') {
            return {
              'distance': {
                'text': elements['distance']['text'],
                'value': elements['distance']['value'], // بالمتر
              },
              'duration': {
                'text': elements['duration']['text'],
                'value': elements['duration']['value'], // بالثواني
              },
              'status': 'OK',
            };
          }
        }
      }

      return {
        'status': 'ERROR',
        'message': 'Failed to get distance matrix',
      };
    } catch (e) {
      debugPrint('Error in getDistanceMatrix: $e');
      return {
        'status': 'ERROR',
        'message': 'Exception: $e',
      };
    }
  }

  // استخدام Directions API للحصول على تفاصيل المسار
  static Future<Map<String, dynamic>> getDirections({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String mode = 'driving', // driving, walking, bicycling, transit
  }) async {
    try {
      // First try the new Routes API for better results
      try {
        const String routesUrl =
            'https://routes.googleapis.com/directions/v2:computeRoutes'
            '?key=$_apiKey';

        debugPrint(
            'Getting route from Routes API: $originLat,$originLng to: $destLat,$destLng');

        final Map<String, dynamic> requestBody = {
          'origin': {
            'location': {
              'latLng': {'latitude': originLat, 'longitude': originLng}
            }
          },
          'destination': {
            'location': {
              'latLng': {'latitude': destLat, 'longitude': destLng}
            }
          },
          'travelMode': 'DRIVE',
          'routingPreference': 'TRAFFIC_AWARE',
          'computeAlternativeRoutes': false,
          'routeModifiers': {
            'avoidTolls': false,
            'avoidHighways': false,
            'avoidFerries': false
          },
          'languageCode': 'ar',
          // Request polyline with higher resolution
          'polylineQuality': 'HIGH_QUALITY',
          'polylineEncoding': 'ENCODED_POLYLINE'
        };

        final routesResponse = await http.post(
          Uri.parse(routesUrl),
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': _apiKey,
            'X-Goog-FieldMask':
                'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.legs'
          },
          body: json.encode(requestBody),
        );

        if (routesResponse.statusCode == 200) {
          final routesData = json.decode(routesResponse.body);
          if (routesData.containsKey('routes') &&
              routesData['routes'] is List &&
              (routesData['routes'] as List).isNotEmpty) {
            final route = routesData['routes'][0];
            final polyline = route['polyline']['encodedPolyline'];
            final distanceMeters = route['distanceMeters'];

            // Format distance
            String distanceText;
            if (distanceMeters < 1000) {
              distanceText = '$distanceMeters م';
            } else {
              distanceText = '${(distanceMeters / 1000).toStringAsFixed(1)} كم';
            }

            // Format duration
            String durationText;
            if (route.containsKey('duration')) {
              final seconds =
                  int.tryParse(route['duration'].replaceAll('s', '')) ?? 0;
              durationText = _formatDuration(seconds);
            } else {
              // Estimate duration based on distance (assuming 40 km/h average speed)
              final estimatedSeconds =
                  (distanceMeters / 1000 / 40 * 3600).round();
              durationText = _formatDuration(estimatedSeconds);
            }

            debugPrint('Routes API success: $distanceText, $durationText');

            return {
              'status': 'OK',
              'distance': {
                'text': distanceText,
                'value': distanceMeters,
              },
              'duration': {
                'text': durationText,
                'value': route.containsKey('duration')
                    ? int.tryParse(route['duration'].replaceAll('s', '')) ?? 0
                    : (distanceMeters / 1000 / 40 * 3600).round(),
              },
              'polyline_points': polyline,
              'has_detailed_polyline': true,
            };
          }
        }

        debugPrint('Routes API failed, falling back to Directions API');
      } catch (e) {
        debugPrint('Error with Routes API, falling back to Directions API: $e');
      }

      // Fallback to standard Directions API
      // Add additional parameters for better route results
      final String url = 'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=$originLat,$originLng'
          '&destination=$destLat,$destLng'
          '&mode=$mode'
          '&alternatives=false' // We only want the best route here
          '&language=ar' // Arabic language for text instructions
          '&units=metric' // Use metric units
          '&key=$_apiKey';

      debugPrint('Directions API Request URL: $url');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Directions API Response Status: ${data['status']}');

        if (data['status'] == 'OK' &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          // استخراج معلومات المسار
          final route = data['routes'][0];
          final leg = route['legs'][0];

          // استخراج نقاط المسار لرسم خط المسار
          final points = route['overview_polyline']['points'];

          debugPrint('Route found with ${points.length} encoded characters');
          debugPrint(
              'Distance: ${leg['distance']['text']}, Duration: ${leg['duration']['text']}');

          // Extract detailed path from steps for more accurate route display
          List<String> detailedPolylines = [];
          if (leg.containsKey('steps') &&
              leg['steps'] is List &&
              leg['steps'].isNotEmpty) {
            for (var step in leg['steps']) {
              if (step.containsKey('polyline') &&
                  step['polyline'].containsKey('points')) {
                detailedPolylines.add(step['polyline']['points']);
              }
            }
          }

          // Use detailed polylines if available, otherwise use overview polyline
          final polylineToUse =
              detailedPolylines.isNotEmpty ? detailedPolylines.join() : points;

          debugPrint(
              'Using ${detailedPolylines.isNotEmpty ? "detailed steps polyline" : "overview polyline"} for route');

          return {
            'status': 'OK',
            'distance': leg['distance'],
            'duration': leg['duration'],
            'start_address': leg['start_address'],
            'end_address': leg['end_address'],
            'steps': leg['steps'],
            'polyline_points': polylineToUse,
            'has_detailed_polyline': detailedPolylines.isNotEmpty,
          };
        } else {
          // Log more detailed error information
          debugPrint('Directions API Error: ${data['status']}');
          if (data.containsKey('error_message')) {
            debugPrint('Error Message: ${data['error_message']}');
          }

          return {
            'status': data['status'] ?? 'ERROR',
            'message': data['error_message'] ?? 'Failed to get directions',
          };
        }
      } else {
        debugPrint('HTTP Error: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');

        return {
          'status': 'ERROR',
          'message': 'HTTP Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error in getDirections: $e');
      return {
        'status': 'ERROR',
        'message': 'Exception: $e',
      };
    }
  }

  // Helper method to format duration in seconds to Arabic text
  static String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '$seconds ثانية';
    } else if (seconds < 3600) {
      int minutes = (seconds / 60).floor();
      return '$minutes دقيقة';
    } else {
      int hours = (seconds / 3600).floor();
      int minutes = ((seconds % 3600) / 60).floor();
      return '$hours ساعة ${minutes > 0 ? ' و $minutes دقيقة' : ''}';
    }
  }

  // استخدام Routes API للحصول على مسارات متعددة
  static Future<Map<String, dynamic>> getRoutes({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      // First try the new Routes API
      const String url =
          'https://routes.googleapis.com/directions/v2:computeRoutes'
          '?key=$_apiKey';

      debugPrint(
          'Getting alternative routes from: $originLat,$originLng to: $destLat,$destLng');

      final Map<String, dynamic> requestBody = {
        'origin': {
          'location': {
            'latLng': {'latitude': originLat, 'longitude': originLng}
          }
        },
        'destination': {
          'location': {
            'latLng': {'latitude': destLat, 'longitude': destLng}
          }
        },
        'travelMode': 'DRIVE',
        'routingPreference': 'TRAFFIC_AWARE',
        'computeAlternativeRoutes': true,
        'routeModifiers': {
          'avoidTolls': false,
          'avoidHighways': false,
          'avoidFerries': false
        },
        'languageCode': 'ar',
        // Request polyline with higher resolution
        'polylineQuality': 'HIGH_QUALITY',
        'polylineEncoding': 'ENCODED_POLYLINE'
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask':
              'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.legs'
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('routes') &&
            data['routes'] is List &&
            (data['routes'] as List).isNotEmpty) {
          debugPrint(
              'Routes API returned ${(data['routes'] as List).length} routes');
          return {
            'status': 'OK',
            'routes': data['routes'],
          };
        } else {
          debugPrint(
              'Routes API returned no routes, falling back to Directions API');
        }
      } else {
        debugPrint('Routes API error: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
      }

      // Fallback to Directions API with alternatives if Routes API fails
      final String directionsUrl =
          'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=$originLat,$originLng'
          '&destination=$destLat,$destLng'
          '&mode=driving'
          '&alternatives=true' // Request alternative routes
          '&language=ar'
          '&units=metric'
          '&key=$_apiKey';

      debugPrint('Falling back to Directions API for alternatives');
      final directionsResponse = await http.get(Uri.parse(directionsUrl));

      if (directionsResponse.statusCode == 200) {
        final data = json.decode(directionsResponse.body);

        if (data['status'] == 'OK' &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          debugPrint(
              'Directions API returned ${data['routes'].length} alternative routes');

          // Convert Directions API format to Routes API format for consistency
          List<Map<String, dynamic>> convertedRoutes = [];

          for (var route in data['routes']) {
            final leg = route['legs'][0];

            // Try to get detailed polyline from steps for more accurate route display
            List<String> detailedPolylines = [];
            if (leg.containsKey('steps') &&
                leg['steps'] is List &&
                leg['steps'].isNotEmpty) {
              for (var step in leg['steps']) {
                if (step.containsKey('polyline') &&
                    step['polyline'].containsKey('points')) {
                  detailedPolylines.add(step['polyline']['points']);
                }
              }
            }

            // Use detailed polylines if available, otherwise use overview polyline
            final points = route['overview_polyline']['points'];
            final polylineToUse = detailedPolylines.isNotEmpty
                ? detailedPolylines.join()
                : points;

            debugPrint('Route has ${polylineToUse.length} encoded characters');

            convertedRoutes.add({
              'polyline': {'encodedPolyline': polylineToUse},
              'distanceMeters': leg['distance']['value'],
              'duration': leg['duration']['text'],
              'has_detailed_polyline': detailedPolylines.isNotEmpty,
            });
          }

          return {
            'status': 'OK',
            'routes': convertedRoutes,
          };
        }
      }

      return {
        'status': 'ERROR',
        'message': 'Failed to get routes from both APIs',
      };
    } catch (e) {
      debugPrint('Error in getRoutes: $e');
      return {
        'status': 'ERROR',
        'message': 'Exception: $e',
      };
    }
  }
}
