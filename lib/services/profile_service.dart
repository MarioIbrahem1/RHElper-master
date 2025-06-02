import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile_data.dart';
import 'package:http_parser/http_parser.dart'; // لازم يكون موجود
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class LocationResult {
  final Position? position;
  final String? error;

  LocationResult({this.position, this.error});
}

class ProfileService {
  final String baseUrl = 'http://81.10.91.96:8132/api';
  final Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  Future<ProfileData> getProfileData(String email,
      {bool useCache = true}) async {
    try {
      // Check if we have fresh cached data and should use it
      if (useCache) {
        final hasFreshCache = await ProfileData.hasFreshCachedData();
        if (hasFreshCache) {
          final cachedData = await ProfileData.loadFromCache();
          if (cachedData != null && cachedData.email == email) {
            debugPrint('Using cached profile data for $email');
            return cachedData;
          }
        }
      }

      debugPrint('=== GET PROFILE REQUEST ===');
      debugPrint('URL: $baseUrl/data');
      debugPrint('Method: POST');
      debugPrint('Headers: $headers');
      debugPrint('Body: ${jsonEncode({"email": email})}');
      debugPrint('========================');

      final response = await http.post(
        Uri.parse('$baseUrl/data'),
        headers: headers,
        body: jsonEncode({"email": email}),
      );

      debugPrint('=== GET PROFILE RESPONSE ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('==========================');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == 'success' &&
            jsonResponse['data'] != null) {
          final userData = jsonResponse['data']['user'];
          final carData = jsonResponse['data']['car'];

          // Format car data in a more readable way in Arabic
          final carInfo = 'السيارة: ${carData['carModel']}\n'
              'اللون: ${carData['carColor']}\n'
              'رقم اللوحة: ${carData['letters']} ${carData['plateNumber']}';

          final profileData = ProfileData(
            name: '${userData['firstName']} ${userData['lastName']}'.trim(),
            email: userData['email'],
            phone: userData['phone'],
            address: carInfo,
            carModel: carData['carModel'],
            carColor: carData['carColor'],
            plateNumber: '${carData['letters']} ${carData['plateNumber']}',
          );

          // Cache the profile data for future use
          await profileData.saveToCache();

          return profileData;
        }
      }

      throw Exception('Failed to load profile data');
    } catch (e) {
      debugPrint('Error in getProfileData: $e');
      throw Exception('Failed to load profile data: $e');
    }
  }

  Future<void> updateProfileData(String email, ProfileData profileData,
      {File? profileImageFile}) async {
    try {
      // التحقق من نوع المستخدم (Google أم عادي)
      final prefs = await SharedPreferences.getInstance();
      final isGoogleSignIn = prefs.getBool('is_google_sign_in') ?? false;

      if (isGoogleSignIn) {
        // استخدام endpoint خاص بمستخدمين Google
        await updateGoogleUserProfile(email, profileData,
            profileImageFile: profileImageFile);
      } else {
        // استخدام endpoint العادي للمستخدمين العاديين
        await updateRegularUserProfile(email, profileData);
      }
    } catch (e) {
      debugPrint('Error in updateProfileData: $e');
      throw Exception('Error updating profile data: $e');
    }
  }

  // تحديث بيانات المستخدم العادي
  Future<void> updateRegularUserProfile(
      String email, ProfileData profileData) async {
    try {
      final Map<String, dynamic> requestData = {
        'email': email,
        'firstName': profileData.name.split(' ')[0],
        'lastName': profileData.name.split(' ').length > 1
            ? profileData.name.split(' ').sublist(1).join(' ')
            : '',
        'phone': profileData.phone,
        'carModel': profileData.carModel,
        'carColor': profileData.carColor,
        'plateNumber': profileData.plateNumber,
      };

      final requestBody = json.encode(requestData);

      debugPrint('=== UPDATE REGULAR USER PROFILE REQUEST ===');
      debugPrint('URL: $baseUrl/updateuser');
      debugPrint('Method: PUT');
      debugPrint('Headers: ${{'Content-Type': 'application/json'}}');
      debugPrint('Body: $requestBody');
      debugPrint('==========================================');

      final response = await http.put(
        Uri.parse('$baseUrl/updateuser'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      debugPrint('=== UPDATE REGULAR USER PROFILE RESPONSE ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('============================================');

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update regular user profile data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in updateRegularUserProfile: $e');
      throw Exception('Error updating regular user profile data: $e');
    }
  }

  // تحديث بيانات مستخدم Google
  Future<void> updateGoogleUserProfile(String email, ProfileData profileData,
      {File? profileImageFile}) async {
    try {
      // تحضير البيانات للإرسال
      final Map<String, dynamic> requestData = {
        'email': email,
        'firstName': profileData.name.split(' ')[0],
        'lastName': profileData.name.split(' ').length > 1
            ? profileData.name.split(' ').sublist(1).join(' ')
            : '',
        'phone': profileData.phone,
        'car_model': profileData.carModel,
        'car_color': profileData.carColor,
        'car_number': profileData.plateNumber,
      };

      // إضافة الصورة إذا كانت متوفرة
      if (profileImageFile != null) {
        requestData['profile_picture'] = profileImageFile;
      }

      debugPrint('=== UPDATE GOOGLE USER PROFILE REQUEST ===');
      debugPrint('Email: $email');
      debugPrint('Data: ${requestData.keys.toList()}');
      debugPrint('Has profile image: ${profileImageFile != null}');
      debugPrint('==========================================');

      // استدعاء الدالة الجديدة من ApiService
      final result = await ApiService.updateGoogleUser(requestData);

      debugPrint('=== UPDATE GOOGLE USER PROFILE RESPONSE ===');
      debugPrint('Success: ${result['success']}');
      debugPrint('Message: ${result['message'] ?? result['error']}');
      debugPrint('===========================================');

      if (result['success'] != true) {
        throw Exception(
            result['error'] ?? 'Failed to update Google user profile');
      }
    } catch (e) {
      debugPrint('Error in updateGoogleUserProfile: $e');
      throw Exception('Error updating Google user profile: $e');
    }
  }

  Future<String> uploadProfileImage(String email, File imageFile) async {
    try {
      // Validate email
      if (email.isEmpty) {
        debugPrint('Error: Empty email provided to uploadProfileImage');
        return '';
      }

      email = email.trim(); // Trim any whitespace

      debugPrint('=== UPLOAD IMAGE REQUEST ===');
      debugPrint('URL: $baseUrl/upload');
      debugPrint('Method: POST');
      debugPrint('Email: $email');

      // Check if file exists and is readable
      if (!await imageFile.exists()) {
        debugPrint('Error: Image file does not exist: ${imageFile.path}');
        return '';
      }

      // Check file size
      final fileSize = await imageFile.length();
      debugPrint('File size: $fileSize bytes');

      // If file is too large (> 5MB), warn about it
      if (fileSize > 5 * 1024 * 1024) {
        debugPrint(
            'Warning: File is large (${fileSize / (1024 * 1024)} MB), upload may take longer');
      }

      // Create a multipart request with timeout
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));

      // Add email field
      request.fields['email'] = email;

      // Determine the correct MIME type based on file extension
      String ext = path.extension(imageFile.path).toLowerCase();
      String mimeType = ext == '.png' ? 'png' : 'jpeg';

      // Add the image file to the request
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', mimeType),
        ),
      );

      // Print request details for debugging
      debugPrint('Request fields: ${request.fields}');
      debugPrint(
          'Request files: ${request.files.map((f) => f.filename).toList()}');

      try {
        // Send the request with timeout
        final streamedResponse = await request.send().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            debugPrint('Request timed out for uploadProfileImage');
            throw Exception('Request timed out');
          },
        );

        final response = await http.Response.fromStream(streamedResponse);

        debugPrint('Upload response status code: ${response.statusCode}');
        debugPrint('Upload response: ${response.body}');

        if (response.statusCode != 200) {
          debugPrint('Error: Non-200 status code: ${response.statusCode}');
          return '';
        }

        try {
          // Parse the response
          final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
          debugPrint('Parsed JSON response: $jsonResponse');

          // Check if the response indicates success
          if (jsonResponse['status'] == 'success') {
            debugPrint('Upload successful according to status');

            // Case 1: Server returns image_url directly
            if (jsonResponse['image_url'] != null) {
              String imageUrl = jsonResponse['image_url'];
              debugPrint('Image uploaded. URL: $imageUrl');

              // Validate and fix URL format if needed
              if (!imageUrl.startsWith('http')) {
                debugPrint(
                    'Warning: Image URL does not start with http: $imageUrl');

                // Try to fix the URL if it's a relative path
                if (imageUrl.startsWith('/')) {
                  imageUrl = 'http://81.10.91.96:8132$imageUrl';
                } else {
                  // If it's not a relative path, prepend the base URL without the /api part
                  imageUrl = 'http://81.10.91.96:8132/$imageUrl';
                }

                debugPrint('Fixed image URL: $imageUrl');
              }

              // Add cache-busting parameter to avoid caching issues
              if (!imageUrl.contains('?')) {
                imageUrl =
                    '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}';
              } else {
                imageUrl =
                    '$imageUrl&t=${DateTime.now().millisecondsSinceEpoch}';
              }

              debugPrint('Final image URL with cache busting: $imageUrl');
              return imageUrl;
            }
            // Case 2: Server returns success message but no URL
            // In this case, we'll try to get the image URL by making a request to the images endpoint
            else if (jsonResponse['message'] != null &&
                jsonResponse['message']
                    .toString()
                    .contains('uploaded successfully')) {
              debugPrint(
                  'Server returned success message but no URL. Fetching image URL from API.');

              // Make a request to get the image URL
              final imageUrl = await getProfileImage(email);

              if (imageUrl.isNotEmpty) {
                debugPrint('Retrieved image URL after upload: $imageUrl');
                return imageUrl;
              } else {
                debugPrint(
                    'Could not retrieve image URL after successful upload');
                return '';
              }
            }
            // If we get here, the response was successful but we couldn't determine the URL
            else {
              debugPrint('Upload successful but could not determine image URL');
              debugPrint('Response body: ${response.body}');

              // Try to get the image URL by making a request to the images endpoint
              final imageUrl = await getProfileImage(email);

              if (imageUrl.isNotEmpty) {
                debugPrint('Retrieved image URL after upload: $imageUrl');
                return imageUrl;
              } else {
                debugPrint(
                    'Could not retrieve image URL after successful upload');
                return '';
              }
            }
          } else {
            debugPrint('Upload failed. Response status indicates failure.');
            debugPrint('Response body: ${response.body}');
            return '';
          }
        } catch (parseError) {
          debugPrint('Error parsing JSON response: $parseError');
          debugPrint('Raw response: ${response.body}');
          return '';
        }
      } catch (httpError) {
        debugPrint('HTTP error during upload: $httpError');
        return '';
      }
    } catch (e) {
      debugPrint('Error in uploadProfileImage: $e');
      return '';
    }
  }

  Future<String> getProfileImage(String email, {bool useCache = true}) async {
    try {
      // Check if we have a cached image URL first
      if (useCache) {
        final cachedImageUrl = await ProfileData.getCachedImageUrl();
        if (cachedImageUrl != null && cachedImageUrl.isNotEmpty) {
          debugPrint('Using cached profile image URL for $email');
          return cachedImageUrl;
        }
      }

      // Validate email
      if (email.isEmpty) {
        debugPrint('Error: Empty email provided to getProfileImage');
        return '';
      }

      email = email.trim(); // Trim any whitespace

      // Based on the Postman screenshot, we need to use GET method with email in the body
      debugPrint('=== GET PROFILE IMAGE REQUEST ===');
      debugPrint('URL: $baseUrl/images');
      debugPrint('Method: GET');
      debugPrint('Headers: $headers');
      debugPrint('Body: ${jsonEncode({"email": email})}');
      debugPrint('========================');

      // Create a GET request with a body (which is unusual but seems to be what the API expects)
      final request = http.Request('GET', Uri.parse('$baseUrl/images'));
      request.headers.addAll(headers);
      request.body = jsonEncode({"email": email});

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('Request timed out for getProfileImage');
          throw Exception('Request timed out');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('=== GET PROFILE IMAGE RESPONSE ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('==========================');

      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(response.body);

          if (jsonResponse['status'] == 'success' &&
              jsonResponse['images'] is List &&
              (jsonResponse['images'] as List).isNotEmpty) {
            final firstImage = jsonResponse['images'][0];
            String? imageUrl;

            // Based on the Postman screenshot, the image URL is in the 'imageUrl' field
            if (firstImage is Map<String, dynamic> &&
                firstImage.containsKey('imageUrl')) {
              imageUrl = firstImage['imageUrl'].toString();
              debugPrint('Found image URL in imageUrl field: $imageUrl');
            }
            // Also check for 'filepath' field as seen in the screenshot
            else if (firstImage is Map<String, dynamic> &&
                firstImage.containsKey('filepath')) {
              final filepath = firstImage['filepath'].toString();
              debugPrint('Found filepath: $filepath');
              imageUrl = 'http://81.10.91.96:8132/$filepath';
            }
            // Also check for 'filePath' field (camel case variation)
            else if (firstImage is Map<String, dynamic> &&
                firstImage.containsKey('filePath')) {
              final filepath = firstImage['filePath'].toString();
              debugPrint('Found filePath: $filepath');
              imageUrl = 'http://81.10.91.96:8132/$filepath';
            }

            if (imageUrl != null && imageUrl.isNotEmpty) {
              // Cache the image URL for future use
              // Create a ProfileData instance to save the image URL
              final profileData = await ProfileData.loadFromCache();
              if (profileData != null) {
                profileData.profileImage = imageUrl;
                await profileData.saveToCache();
              } else {
                // If no profile data exists, just save the image URL directly
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('cached_profile_image', imageUrl);
              }

              return imageUrl;
            }
          }
        } catch (e) {
          debugPrint('Error parsing JSON response: $e');
        }
      }

      // If we couldn't get a URL from the API, return empty string
      debugPrint('Could not get profile image URL');
      return '';
    } catch (e) {
      debugPrint('Error in getProfileImage: $e');
      return '';
    }
  }

  Future<void> checkLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      await Permission.location.request();
    }
  }

  Future<LocationResult> getCurrentLocation() async {
    try {
      // تحقق من تفعيل خدمة الموقع
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult(error: 'خدمة الموقع غير مفعلة. يرجى تفعيل GPS.');
      }

      // تحقق من الصلاحية
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult(
              error: 'تم رفض صلاحية الموقع. يرجى السماح للتطبيق.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult(
            error:
                'صلاحية الموقع مرفوضة بشكل دائم. يرجى تفعيلها من الإعدادات.');
      }

      // جلب الموقع
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      return LocationResult(position: position);
    } catch (e) {
      debugPrint('Location error: $e');
      return LocationResult(error: 'حدث خطأ أثناء جلب الموقع: $e');
    }
  }

  // استرجاع بيانات مستخدم Google
  Future<ProfileData> getGoogleUserProfileData(String email,
      {bool useCache = true}) async {
    try {
      // التحقق من وجود بيانات مخزنة مؤقتًا
      if (useCache) {
        final hasFreshCache = await ProfileData.hasFreshCachedData();
        if (hasFreshCache) {
          final cachedData = await ProfileData.loadFromCache();
          if (cachedData != null && cachedData.email == email) {
            debugPrint('Using cached Google user profile data for $email');
            return cachedData;
          }
        }
      }

      debugPrint('=== GET GOOGLE USER PROFILE REQUEST ===');
      debugPrint('URL: ${ApiService.baseUrl}/api/datagoogle');
      debugPrint('Method: POST');
      debugPrint('Body: ${jsonEncode({"email": email})}');
      debugPrint('=======================================');

      // استدعاء الدالة الجديدة من ApiService
      final result = await ApiService.getGoogleUserData(email);

      if (result['success'] == true && result['data'] != null) {
        final userData = result['data']['user'];

        // تنسيق بيانات السيارة بطريقة أكثر قراءة بالعربية
        String carInfo = '';
        String? carModel, carColor, plateNumber;

        if (userData['car_model'] != null) {
          carModel = userData['car_model'];
          carInfo += 'السيارة: $carModel\n';
        }

        if (userData['car_color'] != null) {
          carColor = userData['car_color'];
          carInfo += 'اللون: $carColor\n';
        }

        if (userData['car_number'] != null) {
          plateNumber = userData['car_number'];
          carInfo += 'رقم اللوحة: $plateNumber';
        }

        final profileData = ProfileData(
          name: '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'
              .trim(),
          email: userData['email'] ?? email,
          phone: userData['phone'],
          address: carInfo.isNotEmpty ? carInfo : null,
          profileImage: userData['profile_picture'],
          carModel: carModel,
          carColor: carColor,
          plateNumber: plateNumber,
        );

        // تخزين البيانات مؤقتًا للاستخدام المستقبلي
        await profileData.saveToCache();

        return profileData;
      }

      throw Exception('Failed to load Google user profile data');
    } catch (e) {
      debugPrint('Error in getGoogleUserProfileData: $e');
      throw Exception('Failed to load Google user profile data: $e');
    }
  }
}
