import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:road_helperr/models/user_location.dart';
import 'package:road_helperr/services/hybrid_user_location_service.dart';
import 'package:road_helperr/services/places_service.dart';
import 'package:road_helperr/utils/location_service.dart';
import 'package:road_helperr/utils/marker_utils.dart';
import 'package:road_helperr/utils/polyline_utils.dart';
import 'package:url_launcher/url_launcher.dart';

/// Controller class to manage map logic and state
class MapController {
  // Map controller
  GoogleMapController? _mapController;

  // Current location
  LatLng _currentLocation = const LatLng(30.0444, 31.2357); // Cairo default

  // Markers
  Set<Marker> _markers = {};
  Set<Marker> _userMarkers = {};
  Marker? _nearestPlaceMarker;

  // Store previous user locations for animation
  final Map<String, UserLocation> _previousUserLocations = {};

  // Polylines for routes
  Set<Polyline> _polylines = {};

  // Filters
  Map<String, bool>? _filters;

  // Nearest place data
  Map<String, dynamic>? _nearestPlace;
  double? _nearestPlaceDistance;
  String? _nearestPlaceTravelTime;

  // Selected place data (when user taps on a marker)
  Map<String, dynamic>? _selectedPlace;

  // Route data
  Map<String, dynamic>? _routeData;
  bool _isShowingRoute = false;

  // Timers
  Timer? _locationUpdateTimer;
  Timer? _usersUpdateTimer;

  // Loading state
  final bool _isLoading = true;

  // Location service
  final LocationService _locationService = LocationService();

  // Getters
  LatLng get currentLocation => _currentLocation;
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;
  bool get isLoading => _isLoading;
  bool get isShowingRoute => _isShowingRoute;
  Map<String, dynamic>? get nearestPlace => _nearestPlace;
  Map<String, dynamic>? get selectedPlace => _selectedPlace;
  double? get nearestPlaceDistance => _nearestPlaceDistance;
  String? get nearestPlaceTravelTime => _nearestPlaceTravelTime;
  Map<String, dynamic>? get routeData => _routeData;

  // Callbacks
  final Function(bool) onLoadingChanged;
  final Function(Set<Marker>) onMarkersChanged;
  final Function(Set<Polyline>) onPolylinesChanged;
  final Function(LatLng) onLocationChanged;
  final Function(String, String) onError;
  final Function(Map<String, dynamic>) onPlaceSelected;
  final Function(Map<String, dynamic>?, double?, String?)?
      onNearestPlaceChanged;
  final Function(Map<String, dynamic>?)? onRouteChanged;
  final Function(UserLocation)? onUserSelected;
  final Function(UserLocation, double, String)? onUserRouteCreated;

  MapController({
    required this.onLoadingChanged,
    required this.onMarkersChanged,
    required this.onPolylinesChanged,
    required this.onLocationChanged,
    required this.onError,
    required this.onPlaceSelected,
    this.onNearestPlaceChanged,
    this.onRouteChanged,
    this.onUserSelected,
    this.onUserRouteCreated,
  });

  /// Initialize map and location
  Future<void> initializeMap() async {
    try {
      await _getCurrentLocation();
      onLoadingChanged(false);
    } catch (e) {
      onError('Location Error', 'Could not initialize map: $e');
      onLoadingChanged(false);
    }
  }

  /// Set map controller
  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  /// Set filters and update places
  void setFilters(Map<String, bool>? filters) {
    _filters = filters;
    if (_filters != null) {
      _fetchNearbyPlaces(_currentLocation.latitude, _currentLocation.longitude);
    }
  }

  /// Start periodic location updates
  void startLocationUpdates() {
    _locationUpdateTimer?.cancel();
    // Update location more frequently (every 10 seconds)
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateUserLocation();
    });
  }

  /// Start periodic nearby users updates
  void startUsersUpdates() {
    _usersUpdateTimer?.cancel();
    // Update nearby users more frequently (every 15 seconds)
    _usersUpdateTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _fetchNearbyUsers();
    });
  }

  /// Update user location to server
  Future<void> _updateUserLocation() async {
    try {
      debugPrint('Starting to update user location to server...');

      // Check location permission first
      await _locationService.checkLocationPermission();

      // Get current position using the improved location service
      Position position = await _locationService.getCurrentPosition();

      // Update current location in the controller
      _currentLocation = LatLng(position.latitude, position.longitude);
      onLocationChanged(_currentLocation);

      // Send location update to server (hybrid)
      await HybridUserLocationService().updateUserLocation(
        LatLng(position.latitude, position.longitude),
      );
      debugPrint('Successfully updated user location to server');
    } catch (e) {
      debugPrint('Error updating user location: $e');
      if (e is Exception) {
        debugPrint('Exception details: ${e.toString()}');
      }
    }
  }

  /// Fetch nearby users (محسن للاستجابة السريعة)
  Future<void> _fetchNearbyUsers() async {
    try {
      debugPrint('Starting to fetch nearby users...');

      // Check location permission first
      await _locationService.checkLocationPermission();

      // Get current position using the improved location service
      Position position = await _locationService.getCurrentPosition();

      // Update current location in the controller
      _currentLocation = LatLng(position.latitude, position.longitude);
      onLocationChanged(_currentLocation);

      // Increase radius to 10000 meters (10 km) for better user discovery
      const double searchRadius = 10000; // 10 km radius for nearby users

      debugPrint('Fetching users within $searchRadius meters radius');

      // استخدام الخدمة الهجينة للحصول على المستخدمين القريبين (Real-time)
      final nearbyUsersStream = HybridUserLocationService().listenToNearbyUsers(
        LatLng(position.latitude, position.longitude),
        searchRadius / 1000, // تحويل إلى كيلومتر
      );

      // الاستماع للـ stream بشكل مستمر بدلاً من أخذ أول نتيجة فقط
      nearbyUsersStream.listen((List<UserLocation> nearbyUsers) {
        _processNearbyUsers(nearbyUsers);
      }, onError: (error) {
        debugPrint('Error in nearby users stream: $error');
      });

      // أيضاً احصل على أول نتيجة للعرض الفوري
      List<UserLocation> nearbyUsers = await nearbyUsersStream.first;
      _processNearbyUsers(nearbyUsers);
    } catch (e) {
      debugPrint('Error fetching nearby users: $e');
    }
  }

  /// معالجة المستخدمين القريبين وإنشاء العلامات
  void _processNearbyUsers(List<UserLocation> nearbyUsers) async {
    try {
      debugPrint('Processing ${nearbyUsers.length} nearby users');

      // Create car markers for each user
      Set<Marker> userMarkers = {};
      for (var user in nearbyUsers) {
        // Create a car marker icon
        BitmapDescriptor carIcon;
        try {
          carIcon = await MarkerUtils.createCarMarkerFromAsset(
            'assets/images/carDark.png',
            width: 60,
            height: 60,
          );
        } catch (e) {
          // Fallback to default marker if custom icon fails
          carIcon = BitmapDescriptor.defaultMarkerWithHue(
            user.isOnline ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          );
          debugPrint('Error creating car marker icon: $e');
        }

        // Create a user with the marker icon
        final userWithIcon = user.copyWith(markerIcon: carIcon);

        // Check if we have a previous location for this user
        if (_previousUserLocations.containsKey(user.userId)) {
          final previousUser = _previousUserLocations[user.userId]!;

          // Only animate if the position has changed
          if (previousUser.position != user.position) {
            // Add marker with animation
            final marker = Marker(
              markerId: MarkerId(user.userId),
              position: user.position,
              infoWindow: InfoWindow(
                title: user.userName,
                snippet:
                    user.carModel ?? (user.isOnline ? 'Online' : 'Offline'),
              ),
              icon: carIcon,
              // Calculate rotation based on movement direction
              rotation:
                  _calculateRotation(previousUser.position, user.position),
              onTap: () => _handleUserMarkerTap(userWithIcon),
            );

            userMarkers.add(marker);
          } else {
            // No movement, just add the marker at the current position
            userMarkers.add(
              Marker(
                markerId: MarkerId(user.userId),
                position: user.position,
                infoWindow: InfoWindow(
                  title: user.userName,
                  snippet:
                      user.carModel ?? (user.isOnline ? 'Online' : 'Offline'),
                ),
                icon: carIcon,
                onTap: () => _handleUserMarkerTap(userWithIcon),
              ),
            );
          }
        } else {
          // First time seeing this user, just add the marker
          userMarkers.add(
            Marker(
              markerId: MarkerId(user.userId),
              position: user.position,
              infoWindow: InfoWindow(
                title: user.userName,
                snippet:
                    user.carModel ?? (user.isOnline ? 'Online' : 'Offline'),
              ),
              icon: carIcon,
              onTap: () => _handleUserMarkerTap(userWithIcon),
            ),
          );
        }

        // Update previous location for next time
        _previousUserLocations[user.userId] = userWithIcon;
      }

      _userMarkers = userMarkers;
      _updateMarkers();
    } catch (e) {
      debugPrint('Error processing nearby users: $e');
    }
  }

  /// Calculate rotation angle based on movement direction
  double _calculateRotation(LatLng from, LatLng to) {
    if (from.latitude == to.latitude && from.longitude == to.longitude) {
      return 0;
    }

    final double deltaLng = to.longitude - from.longitude;
    final double deltaLat = to.latitude - from.latitude;

    // Calculate bearing angle in radians
    final double bearing = atan2(deltaLng, deltaLat);

    // Convert to degrees
    double bearingDegrees = bearing * 180 / pi;

    // Normalize to 0-360
    if (bearingDegrees < 0) {
      bearingDegrees += 360;
    }

    return bearingDegrees;
  }

  /// Handle user marker tap
  void _handleUserMarkerTap(UserLocation user) {
    // We need to use a callback to show the bottom sheet
    // This will be called from the map screen
    if (user.userId.isNotEmpty) {
      debugPrint('User tapped: ${user.userName}');

      // Call the callback if provided
      if (onUserSelected != null) {
        onUserSelected!(user);
      }
    }
  }

  // Function to show user details bottom sheet (to be called from map screen)
  void showUserDetails(BuildContext context, String userId) {
    // Find the user by ID
    final userMarker = _userMarkers.firstWhere(
      (marker) => marker.markerId.value == userId,
      orElse: () => const Marker(markerId: MarkerId('not_found')),
    );

    if (userMarker.markerId.value != 'not_found') {
      // Get user data and show bottom sheet
      // This is a placeholder - the actual implementation will depend on how user data is stored
      debugPrint('Showing details for user: ${userMarker.infoWindow.title}');
    }
  }

  /// Create a route to another user
  Future<bool> createRouteToUser(UserLocation otherUser) async {
    try {
      // Get current location
      Position position = await Geolocator.getCurrentPosition();
      final currentLocation = LatLng(position.latitude, position.longitude);

      // Calculate route
      final result = await PlacesService.getDirections(
        originLat: currentLocation.latitude,
        originLng: currentLocation.longitude,
        destLat: otherUser.position.latitude,
        destLng: otherUser.position.longitude,
      );

      if (result['status'] == 'OK') {
        // Extract route information
        final points = PolylineUtils.decodePolyline(result['points']);
        final distance = result['distance']['value'] as int;
        final duration = result['duration']['text'] as String;

        // Create polyline
        final polyline = Polyline(
          polylineId: const PolylineId('user_route'),
          points: points,
          color: Colors.blue,
          width: 5,
        );

        // Update polylines
        _polylines = {polyline};
        onPolylinesChanged(_polylines);

        // Notify about route creation
        if (onUserRouteCreated != null) {
          onUserRouteCreated!(otherUser, distance.toDouble(), duration);
        }

        return true;
      } else {
        debugPrint('Failed to get directions: ${result['status']}');
        return false;
      }
    } catch (e) {
      debugPrint('Error creating route to user: $e');
      return false;
    }
  }

  /// Clear the route to user
  void clearUserRoute() {
    _polylines = {};
    onPolylinesChanged(_polylines);
  }

  /// Get current location
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        onLoadingChanged(false);
        onError(
          'Location Error',
          'Could not get your current location. Please check your GPS signal and try again.',
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          onLoadingChanged(false);
          onError(
            'Location Error',
            'Location permission denied. Please allow location access.',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        onLoadingChanged(false);
        onError(
          'Location Error',
          'Location permission permanently denied. Please enable it from settings.',
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      ).timeout(
        const Duration(seconds: 35),
        onTimeout: () {
          throw TimeoutException('Location request timed out');
        },
      );

      _currentLocation = LatLng(position.latitude, position.longitude);
      onLocationChanged(_currentLocation);

      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _currentLocation, zoom: 15.0),
          ),
        );
      }

      if (_filters != null) {
        await _fetchNearbyPlaces(position.latitude, position.longitude);
      }
    } catch (e) {
      onLoadingChanged(false);
      onError(
        'Location Error',
        'Could not get your current location. Please try again.',
      );
    }
  }

  /// Fetch nearby places based on filters
  Future<void> _fetchNearbyPlaces(double latitude, double longitude) async {
    try {
      if (_filters == null || _filters!.isEmpty) return;

      // التأكد من استخدام الموقع الحالي الفعلي
      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // استخدام الموقع الحالي الفعلي بدلاً من الموقع المرسل
      latitude = currentPosition.latitude;
      longitude = currentPosition.longitude;

      // تحديث الموقع الحالي
      _currentLocation = LatLng(latitude, longitude);
      onLocationChanged(_currentLocation);

      // تحريك الكاميرا إلى الموقع الحالي
      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _currentLocation, zoom: 15.0),
          ),
        );
      }

      // Debug: Print filters and location
      debugPrint('Filters: $_filters');
      debugPrint('Current Location: $latitude, $longitude');

      // تحسين أسماء الفلاتر وإضافة كلمات مفتاحية
      Map<String, Map<String, dynamic>> filterMapping = {
        'Hospital': {
          'type': 'hospital',
          'keyword': 'hospital مستشفى',
          'hue': BitmapDescriptor.hueRed,
        },
        'Police': {
          'type': 'police',
          'keyword': 'police قسم شرطة',
          'hue': BitmapDescriptor.hueBlue,
        },
        'Maintenance center': {
          'type': 'car_repair',
          'keyword': 'car repair auto service مركز صيانة ورشة',
          'hue': BitmapDescriptor.hueOrange,
        },
        'Winch': {
          'type': 'ونش_انقاذ',
          'keyword':
              'ونش انقاذ سطحة انقاذ سيارات towing services tow truck recovery',
          'hue': BitmapDescriptor.hueYellow,
        },
        'Gas Station': {
          'type': 'gas_station',
          'keyword': 'petrol station fuel محطة بنزين وقود',
          'hue': BitmapDescriptor.hueGreen,
        },
        'Fire Station': {
          'type': 'fire_station',
          'keyword': 'fire station مطافي',
          'hue': BitmapDescriptor.hueViolet,
        },
      };

      List<Map<String, dynamic>> selectedFilters = [];
      _filters!.forEach((key, value) {
        if (value && filterMapping.containsKey(key)) {
          selectedFilters.add(filterMapping[key]!);
        }
      });

      // Debug: Print selected filters
      debugPrint('Selected filters: $selectedFilters');

      if (selectedFilters.isEmpty) return;

      Set<Marker> placeMarkers = {};

      // زيادة نصف قطر البحث للحصول على نتائج أكثر
      const double searchRadius = 10000; // 10 كيلومتر بدلاً من 5

      // معالجة كل نوع فلتر على حدة
      for (var filter in selectedFilters) {
        final type = filter['type'] as String;
        final keyword = filter['keyword'] as String;
        final markerHue = filter['hue'] as double;

        debugPrint('Fetching places for type: $type, keyword: $keyword');

        try {
          // استخدام الميزات الجديدة في PlacesService
          final places = await PlacesService.searchNearbyPlaces(
            latitude: latitude,
            longitude: longitude,
            radius: searchRadius,
            types: [type],
            keyword: keyword,
            fetchAllPages: true, // الحصول على جميع الصفحات
          );

          debugPrint(
              'Found ${places.length} places for type: $type, keyword: $keyword');

          for (var place in places) {
            try {
              final lat =
                  (place['geometry']['location']['lat'] as num).toDouble();
              final lng =
                  (place['geometry']['location']['lng'] as num).toDouble();
              final name = place['name'] as String? ?? 'Unknown Place';
              final placeId =
                  place['place_id'] as String? ?? DateTime.now().toString();
              final vicinity = place['vicinity'] as String? ?? '';

              debugPrint('Adding marker for place: $name at $lat,$lng');

              placeMarkers.add(
                Marker(
                  markerId: MarkerId(placeId),
                  position: LatLng(lat, lng),
                  infoWindow: InfoWindow(
                    title: name,
                    snippet: vicinity,
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
                  onTap: () async {
                    try {
                      final details =
                          await PlacesService.getPlaceDetails(placeId);
                      if (details != null) {
                        _handlePlaceSelected(details);
                      }
                    } catch (e) {
                      debugPrint('Error getting place details: $e');
                      onError(
                        'Error',
                        'Could not load place details. Please try again.',
                      );
                    }
                  },
                ),
              );
            } catch (e) {
              debugPrint('Error processing place: $e');
              continue;
            }
          }
        } catch (e) {
          debugPrint('Error fetching places for type $type: $e');
        }
      }

      debugPrint('Total markers: ${placeMarkers.length}');

      // تحديث العلامات
      _markers = placeMarkers;

      // Find the nearest place after updating markers
      await _findNearestPlace();

      // Update markers including the nearest place marker
      _updateMarkers();
    } catch (e) {
      debugPrint('Error in _fetchNearbyPlaces: $e');
      onError(
        'Error',
        'Failed to fetch nearby places. Please try again.',
      );
    }
  }

  /// Update markers by combining place markers and user markers
  void _updateMarkers() {
    final combinedMarkers = {..._markers, ..._userMarkers};

    // Add nearest place marker if available
    if (_nearestPlaceMarker != null) {
      combinedMarkers.add(_nearestPlaceMarker!);
    }

    onMarkersChanged(combinedMarkers);
  }

  /// Handle place selection
  Future<void> _handlePlaceSelected(Map<String, dynamic> details) async {
    // Store the selected place
    _selectedPlace = details;

    // Calculate distance and travel time to the selected place
    await _calculateDistanceToPlace(details);

    // Call the callback to show place details in UI
    onPlaceSelected(details);

    // Update the nearest place to be the selected place
    if (_selectedPlace != null && onNearestPlaceChanged != null) {
      onNearestPlaceChanged!(
          _selectedPlace, _nearestPlaceDistance, _nearestPlaceTravelTime);
    }
  }

  /// Calculate distance and travel time to a place
  Future<void> _calculateDistanceToPlace(Map<String, dynamic> place) async {
    try {
      if (place['geometry'] != null && place['geometry']['location'] != null) {
        final lat = (place['geometry']['location']['lat'] as num).toDouble();
        final lng = (place['geometry']['location']['lng'] as num).toDouble();

        // Get the most accurate current location from GPS
        LatLng originLocation;
        try {
          // Try to get the most accurate current location from GPS
          final Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5),
          );
          originLocation = LatLng(position.latitude, position.longitude);

          // Update the current location
          _currentLocation = originLocation;
          onLocationChanged(_currentLocation);

          debugPrint(
              'Using GPS location for distance calculation: ${position.latitude}, ${position.longitude}');
        } catch (e) {
          // Fallback to the stored current location if GPS fails
          originLocation = _currentLocation;
          debugPrint(
              'Using stored location for distance calculation: ${_currentLocation.latitude}, ${_currentLocation.longitude}');
        }

        // First calculate straight-line distance
        final distance = _calculateDistance(originLocation, LatLng(lat, lng));
        _nearestPlaceDistance = distance;

        // Format the straight-line distance as fallback
        String distanceText;
        if (distance < 1000) {
          distanceText = '${distance.toInt()} م';
        } else {
          distanceText = '${(distance / 1000).toStringAsFixed(1)} كم';
        }

        // Add fallback distance to the place data
        place['distance'] = {
          'text': distanceText,
          'value': distance.toInt(),
        };

        // Then try to get more accurate distance and travel time using Distance Matrix API
        try {
          final result = await PlacesService.getDistanceMatrix(
            originLat: originLocation.latitude,
            originLng: originLocation.longitude,
            destLat: lat,
            destLng: lng,
          );

          if (result['status'] == 'OK') {
            final distanceValue = result['distance']['value'] as int;
            final durationText = result['duration']['text'] as String;
            final distanceText = result['distance']['text'] as String;

            debugPrint(
                'Distance Matrix API result: $distanceText, $durationText');

            _nearestPlaceDistance = distanceValue.toDouble();
            _nearestPlaceTravelTime = durationText;

            // Add distance and duration to the place data
            place['distance'] = {
              'text': distanceText,
              'value': distanceValue,
            };
            place['duration'] = {
              'text': durationText,
              'value': result['duration']['value'],
            };
          } else {
            debugPrint('Distance Matrix API error: ${result['status']}');
            // Keep the straight-line distance as fallback
            _nearestPlaceTravelTime = _formatTravelTime(distance);
            place['duration'] = {
              'text': _nearestPlaceTravelTime!,
              'value': _estimateTravelTimeInSeconds(distance),
            };
          }
        } catch (e) {
          debugPrint('Error getting distance matrix: $e');
          // Keep the straight-line distance as fallback
          _nearestPlaceTravelTime = _formatTravelTime(distance);
          place['duration'] = {
            'text': _nearestPlaceTravelTime!,
            'value': _estimateTravelTimeInSeconds(distance),
          };
        }
      }
    } catch (e) {
      debugPrint('Error calculating distance to place: $e');
    }
  }

  /// Format travel time based on distance
  String _formatTravelTime(double distanceInMeters) {
    // Estimate travel time based on average speed of 40 km/h
    final timeInMinutes = (distanceInMeters / 1000 / 40 * 60).round();

    if (timeInMinutes < 1) {
      return 'أقل من دقيقة';
    } else if (timeInMinutes < 60) {
      return '$timeInMinutes دقيقة';
    } else {
      final hours = timeInMinutes ~/ 60;
      final minutes = timeInMinutes % 60;
      if (minutes == 0) {
        return '$hours ساعة';
      } else {
        return '$hours ساعة و $minutes دقيقة';
      }
    }
  }

  /// Estimate travel time in seconds based on distance
  int _estimateTravelTimeInSeconds(double distanceInMeters) {
    // Estimate travel time based on average speed of 40 km/h
    return (distanceInMeters / 1000 / 40 * 3600).round();
  }

  /// Calculate distance between two coordinates in meters
  double _calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
        point1.latitude, point1.longitude, point2.latitude, point2.longitude);
  }

  /// Find the nearest place from the current location using Distance Matrix API
  Future<void> _findNearestPlace() async {
    if (_markers.isEmpty) {
      _nearestPlace = null;
      _nearestPlaceDistance = null;
      _nearestPlaceTravelTime = null;
      _nearestPlaceMarker = null;
      if (onNearestPlaceChanged != null) {
        onNearestPlaceChanged!(null, null, null);
      }
      return;
    }

    // Get the most accurate current location from GPS
    LatLng originLocation;
    try {
      // Try to get the most accurate current location from GPS
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      originLocation = LatLng(position.latitude, position.longitude);

      // Update the current location
      _currentLocation = originLocation;
      onLocationChanged(_currentLocation);

      debugPrint(
          'Using GPS location for finding nearest place: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      // Fallback to the stored current location if GPS fails
      originLocation = _currentLocation;
      debugPrint(
          'Using stored location for finding nearest place: ${_currentLocation.latitude}, ${_currentLocation.longitude}');
    }

    double? minDistance;
    String? travelTime;
    Map<String, dynamic>? nearestPlace;
    Marker? nearestMarker;

    // First, find the approximate nearest place using straight-line distance
    List<Marker> closestMarkers = [];
    for (var marker in _markers) {
      final distance = _calculateDistance(originLocation, marker.position);

      if (closestMarkers.isEmpty || closestMarkers.length < 5) {
        closestMarkers.add(marker);
        closestMarkers.sort((a, b) {
          final distA = _calculateDistance(originLocation, a.position);
          final distB = _calculateDistance(originLocation, b.position);
          return distA.compareTo(distB);
        });
      } else {
        final lastDistance =
            _calculateDistance(originLocation, closestMarkers.last.position);
        if (distance < lastDistance) {
          closestMarkers.removeLast();
          closestMarkers.add(marker);
          closestMarkers.sort((a, b) {
            final distA = _calculateDistance(originLocation, a.position);
            final distB = _calculateDistance(originLocation, b.position);
            return distA.compareTo(distB);
          });
        }
      }
    }

    // Now use Distance Matrix API to get accurate travel distances for the closest markers
    for (var marker in closestMarkers) {
      try {
        final result = await PlacesService.getDistanceMatrix(
          originLat: originLocation.latitude,
          originLng: originLocation.longitude,
          destLat: marker.position.latitude,
          destLng: marker.position.longitude,
        );

        if (result['status'] == 'OK') {
          final distanceValue = result['distance']['value'] as int;
          final durationText = result['duration']['text'] as String;
          final distanceText = result['distance']['text'] as String;

          debugPrint(
              'Distance to ${marker.infoWindow.title}: $distanceText, $durationText');

          if (minDistance == null || distanceValue < minDistance) {
            minDistance = distanceValue.toDouble();
            travelTime = durationText;
            nearestMarker = marker;

            // Extract place data from marker
            final markerId = marker.markerId.value;
            final position = marker.position;
            final title = marker.infoWindow.title ?? 'Unknown Place';
            final snippet = marker.infoWindow.snippet ?? '';

            nearestPlace = {
              'place_id': markerId,
              'name': title,
              'vicinity': snippet,
              'geometry': {
                'location': {
                  'lat': position.latitude,
                  'lng': position.longitude,
                }
              },
              'distance': {
                'text': distanceText,
                'value': distanceValue,
              },
              'duration': {
                'text': durationText,
                'value': result['duration']['value'],
              }
            };
          }
        } else {
          debugPrint(
              'Distance Matrix API error for ${marker.infoWindow.title}: ${result['status']}');
        }
      } catch (e) {
        debugPrint(
            'Error getting distance matrix for ${marker.infoWindow.title}: $e');
        // Fallback to straight-line distance if API fails
        final distance = _calculateDistance(originLocation, marker.position);

        // Format the straight-line distance as fallback
        String distanceText;
        if (distance < 1000) {
          distanceText = '${distance.toInt()} م';
        } else {
          distanceText = '${(distance / 1000).toStringAsFixed(1)} كم';
        }

        // Estimate travel time based on distance
        final estimatedTravelTime = _formatTravelTime(distance);

        if (minDistance == null || distance < minDistance) {
          minDistance = distance;
          travelTime = estimatedTravelTime;
          nearestMarker = marker;

          // Extract place data from marker
          final markerId = marker.markerId.value;
          final position = marker.position;
          final title = marker.infoWindow.title ?? 'Unknown Place';
          final snippet = marker.infoWindow.snippet ?? '';

          nearestPlace = {
            'place_id': markerId,
            'name': title,
            'vicinity': snippet,
            'geometry': {
              'location': {
                'lat': position.latitude,
                'lng': position.longitude,
              }
            },
            'distance': {
              'text': distanceText,
              'value': distance.toInt(),
            },
            'duration': {
              'text': estimatedTravelTime,
              'value': _estimateTravelTimeInSeconds(distance),
            }
          };
        }
      }
    }

    // Create a special marker for the nearest place
    if (nearestMarker != null) {
      _nearestPlaceMarker = Marker(
        markerId: MarkerId('nearest_${nearestMarker.markerId.value}'),
        position: nearestMarker.position,
        infoWindow: InfoWindow(
          title: '${nearestMarker.infoWindow.title} (Nearest Place)',
          snippet: travelTime != null
              ? 'Travel time: $travelTime'
              : nearestMarker.infoWindow.snippet,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        zIndex: 2, // Make it appear above other markers
        onTap: () async {
          if (nearestPlace != null) {
            try {
              final details =
                  await PlacesService.getPlaceDetails(nearestPlace['place_id']);
              if (details != null) {
                _handlePlaceSelected(details);
              } else {
                _handlePlaceSelected(nearestPlace);
              }
            } catch (e) {
              debugPrint('Error getting nearest place details: $e');
              _handlePlaceSelected(nearestPlace);
            }
          }
        },
      );
    }

    _nearestPlace = nearestPlace;
    _nearestPlaceDistance = minDistance;
    _nearestPlaceTravelTime = travelTime;

    // Notify about the nearest place
    if (onNearestPlaceChanged != null) {
      onNearestPlaceChanged!(nearestPlace, minDistance, travelTime);
    }

    // Update markers to include the nearest place marker
    _updateMarkers();
  }

  /// Get directions to the selected place using external Google Maps
  Future<bool> getDirectionsToNearestPlace() async {
    // Use selected place if available, otherwise use nearest place
    final place = _selectedPlace ?? _nearestPlace;
    if (place == null) return false;

    try {
      final lat = (place['geometry']['location']['lat'] as num).toDouble();
      final lng = (place['geometry']['location']['lng'] as num).toDouble();
      final url =
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';

      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error opening directions to place: $e');
      onError(
          'Navigation Error', 'Could not open directions. Please try again.');
      return false;
    }
  }

  /// Show route to the selected place on the map
  Future<bool> showRouteToNearestPlace() async {
    // Use selected place if available, otherwise use nearest place
    final place = _selectedPlace ?? _nearestPlace;
    if (place == null) return false;

    try {
      // Clear existing polylines
      _polylines = {};

      // Get destination coordinates
      final destLat = (place['geometry']['location']['lat'] as num).toDouble();
      final destLng = (place['geometry']['location']['lng'] as num).toDouble();

      // Get the most accurate current location from GPS
      LatLng originLocation;
      try {
        // Try to get the most accurate current location from GPS
        final Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
        originLocation = LatLng(position.latitude, position.longitude);

        // Update the current location
        _currentLocation = originLocation;
        onLocationChanged(_currentLocation);

        debugPrint(
            'Using GPS location for route: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        // Fallback to the stored current location if GPS fails
        originLocation = _currentLocation;
        debugPrint(
            'Using stored location for route: ${_currentLocation.latitude}, ${_currentLocation.longitude}');
      }

      debugPrint(
          'Getting directions from: ${originLocation.latitude},${originLocation.longitude} to: $destLat,$destLng');

      // Get directions using Directions API
      final directions = await PlacesService.getDirections(
        originLat: originLocation.latitude,
        originLng: originLocation.longitude,
        destLat: destLat,
        destLng: destLng,
      );

      if (directions['status'] == 'OK') {
        // Store route data
        _routeData = directions;

        // Decode polyline points
        final points =
            PolylineUtils.decodePolyline(directions['polyline_points']);

        debugPrint('Route points count: ${points.length}');
        if (points.isEmpty) {
          debugPrint('Warning: No points in polyline');
          onError('Route Error', 'No route points found. Please try again.');
          return false;
        }

        // Log if we're using detailed polyline
        if (directions.containsKey('has_detailed_polyline') &&
            directions['has_detailed_polyline'] == true) {
          debugPrint(
              'Using detailed polyline from route steps for better accuracy');
        }

        // Create polyline with improved visibility
        final polyline = Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: Colors.blue,
          width: 10, // Increased width for better visibility
          // Use solid line for main route (no pattern)
          patterns: const [],
          endCap: Cap.roundCap,
          startCap: Cap.roundCap,
          jointType: JointType.round,
          geodesic:
              true, // Follow the curvature of the earth for more accurate routes
        );

        // Add polyline to set
        _polylines = {polyline};

        // Add a marker for the current location (origin of the route)
        final currentLocationMarker = Marker(
          markerId: const MarkerId('current_location'),
          position: originLocation,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(
            title: 'موقعك الحالي',
            snippet: 'نقطة بداية المسار',
          ),
          zIndex: 3, // Make it appear above other markers
        );

        // Update markers to include current location marker
        final updatedMarkers = {..._markers, ..._userMarkers};
        if (_nearestPlaceMarker != null) {
          updatedMarkers.add(_nearestPlaceMarker!);
        }
        updatedMarkers.add(currentLocationMarker);
        onMarkersChanged(updatedMarkers);

        // Update polylines
        onPolylinesChanged(_polylines);

        // Update route state
        _isShowingRoute = true;

        // Notify about route change
        if (onRouteChanged != null) {
          onRouteChanged!(directions);
        }

        // Include origin and destination in the bounds calculation
        List<LatLng> boundPoints = [...points];
        boundPoints.add(_currentLocation); // Add current location
        boundPoints.add(LatLng(destLat, destLng)); // Add destination

        // Move camera to show the entire route with improved bounds calculation
        if (_mapController != null && boundPoints.isNotEmpty) {
          // Calculate bounds
          double minLat = boundPoints.first.latitude;
          double maxLat = boundPoints.first.latitude;
          double minLng = boundPoints.first.longitude;
          double maxLng = boundPoints.first.longitude;

          for (var point in boundPoints) {
            if (point.latitude < minLat) minLat = point.latitude;
            if (point.latitude > maxLat) maxLat = point.latitude;
            if (point.longitude < minLng) minLng = point.longitude;
            if (point.longitude > maxLng) maxLng = point.longitude;
          }

          // Add more padding to ensure the entire route is visible
          final latPadding =
              max((maxLat - minLat) * 0.3, 0.005); // Minimum padding
          final lngPadding =
              max((maxLng - minLng) * 0.3, 0.005); // Minimum padding

          // Create bounds
          final bounds = LatLngBounds(
            southwest: LatLng(minLat - latPadding, minLng - lngPadding),
            northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
          );

          debugPrint(
              'Camera bounds: SW(${bounds.southwest.latitude},${bounds.southwest.longitude}) NE(${bounds.northeast.latitude},${bounds.northeast.longitude})');

          // Animate camera with a delay to ensure the map is ready
          await Future.delayed(const Duration(milliseconds: 300));
          try {
            await _mapController!.animateCamera(
              CameraUpdate.newLatLngBounds(bounds, 100), // Increased padding
            );

            // Add a second camera update with a slight zoom out to ensure visibility
            await Future.delayed(const Duration(milliseconds: 500));
            final currentZoom = await _mapController!.getZoomLevel();
            if (currentZoom > 16) {
              await _mapController!.animateCamera(
                CameraUpdate.zoomTo(16), // Limit maximum zoom
              );
            }
          } catch (e) {
            debugPrint('Error animating camera: $e');
            // Fallback to a simpler camera update
            await _mapController!.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(
                    (minLat + maxLat) / 2,
                    (minLng + maxLng) / 2,
                  ),
                  zoom: 14.0,
                ),
              ),
            );
          }
        }

        return true;
      } else {
        debugPrint('Route API error: ${directions['status']}');
        onError('Route Error', 'Could not find a route to the destination.');
        return false;
      }
    } catch (e) {
      debugPrint('Error showing route to nearest place: $e');
      onError('Route Error', 'Could not show route. Please try again.');
      return false;
    }
  }

  /// Clear the route from the map
  void clearRoute() {
    _polylines = {};
    _isShowingRoute = false;
    _routeData = null;

    // Update polylines
    onPolylinesChanged(_polylines);

    // Remove the current location marker
    final updatedMarkers = {..._markers, ..._userMarkers};
    if (_nearestPlaceMarker != null) {
      updatedMarkers.add(_nearestPlaceMarker!);
    }
    // Note: we're not adding the current_location marker here
    onMarkersChanged(updatedMarkers);

    // Notify about route change
    if (onRouteChanged != null) {
      onRouteChanged!(null);
    }
  }

  /// Show alternative routes to the selected place
  Future<bool> showAlternativeRoutes() async {
    // Use selected place if available, otherwise use nearest place
    final place = _selectedPlace ?? _nearestPlace;
    if (place == null) return false;

    try {
      // Clear existing polylines
      _polylines = {};

      // Get destination coordinates
      final destLat = (place['geometry']['location']['lat'] as num).toDouble();
      final destLng = (place['geometry']['location']['lng'] as num).toDouble();

      // Get the most accurate current location from GPS
      LatLng originLocation;
      try {
        // Try to get the most accurate current location from GPS
        final Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
        originLocation = LatLng(position.latitude, position.longitude);

        // Update the current location
        _currentLocation = originLocation;
        onLocationChanged(_currentLocation);

        debugPrint(
            'Using GPS location for alternative routes: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        // Fallback to the stored current location if GPS fails
        originLocation = _currentLocation;
        debugPrint(
            'Using stored location for alternative routes: ${_currentLocation.latitude}, ${_currentLocation.longitude}');
      }

      debugPrint(
          'Getting alternative routes from: ${originLocation.latitude},${originLocation.longitude} to: $destLat,$destLng');

      // Get routes using Routes API
      final routesResult = await PlacesService.getRoutes(
        originLat: originLocation.latitude,
        originLng: originLocation.longitude,
        destLat: destLat,
        destLng: destLng,
      );

      if (routesResult['status'] == 'OK' &&
          routesResult['routes'] != null &&
          routesResult['routes'] is List &&
          (routesResult['routes'] as List).isNotEmpty) {
        // Store route data
        _routeData = routesResult;

        // Create polylines for each route
        final routes = routesResult['routes'] as List;
        Set<Polyline> polylines = {};

        debugPrint('Found ${routes.length} alternative routes');

        // Colors for different routes
        final colors = [
          Colors.blue,
          Colors.green,
          Colors.red,
        ];

        // All points from all routes for bounds calculation
        List<LatLng> allPoints = [];

        for (int i = 0; i < routes.length && i < colors.length; i++) {
          final route = routes[i];
          final encodedPolyline =
              route['polyline']['encodedPolyline'] as String;
          final points = PolylineUtils.decodePolyline(encodedPolyline);

          debugPrint('Route $i has ${points.length} points');

          if (points.isEmpty) {
            debugPrint('Warning: No points in polyline for route $i');
            continue;
          }

          // Log if we're using detailed polyline
          if (route.containsKey('has_detailed_polyline') &&
              route['has_detailed_polyline'] == true) {
            debugPrint(
                'Route $i: Using detailed polyline from steps for better accuracy');
          }

          // Add points to the collection for bounds calculation
          allPoints.addAll(points);

          // Create polyline with improved visibility
          polylines.add(
            Polyline(
              polylineId: PolylineId('route_$i'),
              points: points,
              color: colors[i],
              width: i == 0 ? 10 : 6, // Increased width for better visibility
              patterns: i == 0
                  ? const [] // Main route is solid
                  : [
                      PatternItem.dash(20),
                      PatternItem.gap(10)
                    ], // Alternative routes are dashed
              endCap: Cap.roundCap,
              startCap: Cap.roundCap,
              jointType: JointType.round,
              geodesic:
                  true, // Follow the curvature of the earth for more accurate routes
              zIndex: i == 0 ? 2 : 1, // Make main route appear on top
            ),
          );
        }

        if (polylines.isEmpty) {
          debugPrint('No valid routes found');
          onError('Route Error', 'No valid routes found. Please try again.');
          return false;
        }

        // Update polylines
        _polylines = polylines;
        onPolylinesChanged(_polylines);

        // Add a marker for the current location (origin of the route)
        final currentLocationMarker = Marker(
          markerId: const MarkerId('current_location'),
          position: originLocation,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(
            title: 'موقعك الحالي',
            snippet: 'نقطة بداية ',
          ),
          zIndex: 3, // Make it appear above other markers
        );

        // Update markers to include current location marker
        final updatedMarkers = {..._markers, ..._userMarkers};
        if (_nearestPlaceMarker != null) {
          updatedMarkers.add(_nearestPlaceMarker!);
        }
        updatedMarkers.add(currentLocationMarker);
        onMarkersChanged(updatedMarkers);

        // Update route state
        _isShowingRoute = true;

        // Notify about route change
        if (onRouteChanged != null) {
          onRouteChanged!(routesResult);
        }

        // Include origin and destination in the bounds calculation
        allPoints.add(_currentLocation); // Add current location
        allPoints.add(LatLng(destLat, destLng)); // Add destination

        // Move camera to show all routes
        if (_mapController != null && allPoints.isNotEmpty) {
          // Calculate bounds
          double minLat = allPoints.first.latitude;
          double maxLat = allPoints.first.latitude;
          double minLng = allPoints.first.longitude;
          double maxLng = allPoints.first.longitude;

          for (var point in allPoints) {
            if (point.latitude < minLat) minLat = point.latitude;
            if (point.latitude > maxLat) maxLat = point.latitude;
            if (point.longitude < minLng) minLng = point.longitude;
            if (point.longitude > maxLng) maxLng = point.longitude;
          }

          // Add more padding to ensure all routes are visible
          final latPadding =
              max((maxLat - minLat) * 0.3, 0.005); // Minimum padding
          final lngPadding =
              max((maxLng - minLng) * 0.3, 0.005); // Minimum padding

          // Create bounds
          final bounds = LatLngBounds(
            southwest: LatLng(minLat - latPadding, minLng - lngPadding),
            northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
          );

          debugPrint(
              'Camera bounds for all routes: SW(${bounds.southwest.latitude},${bounds.southwest.longitude}) NE(${bounds.northeast.latitude},${bounds.northeast.longitude})');

          // Animate camera with a delay to ensure the map is ready
          await Future.delayed(const Duration(milliseconds: 300));
          try {
            await _mapController!.animateCamera(
              CameraUpdate.newLatLngBounds(bounds, 100), // Increased padding
            );

            // Add a second camera update with a slight zoom out to ensure visibility
            await Future.delayed(const Duration(milliseconds: 500));
            final currentZoom = await _mapController!.getZoomLevel();
            if (currentZoom > 15) {
              await _mapController!.animateCamera(
                CameraUpdate.zoomTo(
                    15), // Limit maximum zoom for alternative routes
              );
            }
          } catch (e) {
            debugPrint('Error animating camera: $e');
            // Fallback to a simpler camera update
            await _mapController!.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(
                    (minLat + maxLat) / 2,
                    (minLng + maxLng) / 2,
                  ),
                  zoom: 13.0, // Slightly lower zoom for alternative routes
                ),
              ),
            );
          }
        }

        return true;
      } else {
        debugPrint('Route API error: ${routesResult['status']}');
        if (routesResult.containsKey('message')) {
          debugPrint('Error message: ${routesResult['message']}');
        }
        onError('Route Error',
            'Could not find alternative routes to the destination.');
        return false;
      }
    } catch (e) {
      debugPrint('Error showing alternative routes: $e');
      onError('Route Error',
          'Could not show alternative routes. Please try again.');
      return false;
    }
  }

  /// Update camera position
  void onCameraMove(CameraPosition position) {
    _currentLocation = position.target;
    onLocationChanged(_currentLocation);
  }

  /// Update current location manually
  void updateCurrentLocation(LatLng location) {
    _currentLocation = location;
    onLocationChanged(_currentLocation);

    // Actualizar los marcadores basados en la nueva ubicación
    if (_filters != null && _filters!.isNotEmpty) {
      _fetchNearbyPlaces(location.latitude, location.longitude);
    }
  }

  /// Dispose resources
  void dispose() {
    _locationUpdateTimer?.cancel();
    _usersUpdateTimer?.cancel();
    _mapController?.dispose();
  }
}
