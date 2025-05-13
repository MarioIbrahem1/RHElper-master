import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/profile_data.dart';
import 'package:http_parser/http_parser.dart'; // لازم يكون موجود
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

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

  Future<ProfileData> getProfileData(String email) async {
    try {
      print('=== GET PROFILE REQUEST ===');
      print('URL: $baseUrl/data');
      print('Method: POST');
      print('Headers: $headers');
      print('Body: ${jsonEncode({"email": email})}');
      print('========================');

      final response = await http.post(
        Uri.parse('$baseUrl/data'),
        headers: headers,
        body: jsonEncode({"email": email}),
      );

      print('=== GET PROFILE RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('==========================');

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

          return ProfileData(
            name: '${userData['firstName']} ${userData['lastName']}'.trim(),
            email: userData['email'],
            phone: userData['phone'],
            address: carInfo,
            carModel: carData['carModel'],
            carColor: carData['carColor'],
            plateNumber: '${carData['letters']} ${carData['plateNumber']}',
          );
        }
      }

      throw Exception('Failed to load profile data');
    } catch (e) {
      print('Error in getProfileData: $e');
      throw Exception('Failed to load profile data: $e');
    }
  }

  Future<void> updateProfileData(String email, ProfileData profileData) async {
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

      print('=== UPDATE PROFILE REQUEST ===');
      print('URL: $baseUrl/updateuser');
      print('Method: PUT');
      print('Headers: ${{'Content-Type': 'application/json'}}');
      print('Body: $requestBody');
      print('============================');

      final response = await http.put(
        Uri.parse('$baseUrl/updateuser'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      print('=== UPDATE PROFILE RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('==============================');

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update profile data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateProfileData: $e');
      throw Exception('Error updating profile data: $e');
    }
  }

  Future<String> uploadProfileImage(String email, File imageFile) async {
    try {
      // Validate email
      if (email.isEmpty) {
        print('Error: Empty email provided to uploadProfileImage');
        return '';
      }

      email = email.trim(); // Trim any whitespace

      print('=== UPLOAD IMAGE REQUEST ===');
      print('URL: $baseUrl/upload');
      print('Method: POST');
      print('Email: $email');

      // Check if file exists and is readable
      if (!await imageFile.exists()) {
        print('Error: Image file does not exist: ${imageFile.path}');
        return '';
      }

      // Check file size
      final fileSize = await imageFile.length();
      print('File size: $fileSize bytes');

      // If file is too large (> 5MB), warn about it
      if (fileSize > 5 * 1024 * 1024) {
        print(
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
      print('Request fields: ${request.fields}');
      print('Request files: ${request.files.map((f) => f.filename).toList()}');

      try {
        // Send the request with timeout
        final streamedResponse = await request.send().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            print('Request timed out for uploadProfileImage');
            throw Exception('Request timed out');
          },
        );

        final response = await http.Response.fromStream(streamedResponse);

        print('Upload response status code: ${response.statusCode}');
        print('Upload response: ${response.body}');

        if (response.statusCode != 200) {
          print('Error: Non-200 status code: ${response.statusCode}');
          return '';
        }

        try {
          // Parse the response
          final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
          print('Parsed JSON response: $jsonResponse');

          // Check if the response indicates success
          if (jsonResponse['status'] == 'success') {
            print('Upload successful according to status');

            // Case 1: Server returns image_url directly
            if (jsonResponse['image_url'] != null) {
              String imageUrl = jsonResponse['image_url'];
              print('Image uploaded. URL: $imageUrl');

              // Validate and fix URL format if needed
              if (!imageUrl.startsWith('http')) {
                print('Warning: Image URL does not start with http: $imageUrl');

                // Try to fix the URL if it's a relative path
                if (imageUrl.startsWith('/')) {
                  imageUrl = 'http://81.10.91.96:8132$imageUrl';
                } else {
                  // If it's not a relative path, prepend the base URL without the /api part
                  imageUrl = 'http://81.10.91.96:8132/$imageUrl';
                }

                print('Fixed image URL: $imageUrl');
              }

              // Add cache-busting parameter to avoid caching issues
              if (!imageUrl.contains('?')) {
                imageUrl =
                    '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}';
              } else {
                imageUrl =
                    '$imageUrl&t=${DateTime.now().millisecondsSinceEpoch}';
              }

              print('Final image URL with cache busting: $imageUrl');
              return imageUrl;
            }
            // Case 2: Server returns success message but no URL
            // In this case, we'll try to get the image URL by making a request to the images endpoint
            else if (jsonResponse['message'] != null &&
                jsonResponse['message']
                    .toString()
                    .contains('uploaded successfully')) {
              print(
                  'Server returned success message but no URL. Fetching image URL from API.');

              // Make a request to get the image URL
              final imageUrl = await getProfileImage(email);

              if (imageUrl.isNotEmpty) {
                print('Retrieved image URL after upload: $imageUrl');
                return imageUrl;
              } else {
                print('Could not retrieve image URL after successful upload');
                return '';
              }
            }
            // If we get here, the response was successful but we couldn't determine the URL
            else {
              print('Upload successful but could not determine image URL');
              print('Response body: ${response.body}');

              // Try to get the image URL by making a request to the images endpoint
              final imageUrl = await getProfileImage(email);

              if (imageUrl.isNotEmpty) {
                print('Retrieved image URL after upload: $imageUrl');
                return imageUrl;
              } else {
                print('Could not retrieve image URL after successful upload');
                return '';
              }
            }
          } else {
            print('Upload failed. Response status indicates failure.');
            print('Response body: ${response.body}');
            return '';
          }
        } catch (parseError) {
          print('Error parsing JSON response: $parseError');
          print('Raw response: ${response.body}');
          return '';
        }
      } catch (httpError) {
        print('HTTP error during upload: $httpError');
        return '';
      }
    } catch (e) {
      print('Error in uploadProfileImage: $e');
      return '';
    }
  }

  Future<String> getProfileImage(String email) async {
    try {
      // Validate email
      if (email.isEmpty) {
        print('Error: Empty email provided to getProfileImage');
        return '';
      }

      email = email.trim(); // Trim any whitespace

      // Based on the Postman screenshot, we need to use GET method with email in the body
      print('=== GET PROFILE IMAGE REQUEST ===');
      print('URL: $baseUrl/images');
      print('Method: GET');
      print('Headers: $headers');
      print('Body: ${jsonEncode({"email": email})}');
      print('========================');

      // Create a GET request with a body (which is unusual but seems to be what the API expects)
      final request = http.Request('GET', Uri.parse('$baseUrl/images'));
      request.headers.addAll(headers);
      request.body = jsonEncode({"email": email});

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('Request timed out for getProfileImage');
          throw Exception('Request timed out');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      print('=== GET PROFILE IMAGE RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('==========================');

      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(response.body);

          if (jsonResponse['status'] == 'success' &&
              jsonResponse['images'] is List &&
              (jsonResponse['images'] as List).isNotEmpty) {
            final firstImage = jsonResponse['images'][0];

            // Based on the Postman screenshot, the image URL is in the 'imageUrl' field
            if (firstImage is Map<String, dynamic> &&
                firstImage.containsKey('imageUrl')) {
              final imageUrl = firstImage['imageUrl'].toString();
              print('Found image URL in imageUrl field: $imageUrl');
              return imageUrl;
            }

            // Also check for 'filepath' field as seen in the screenshot
            if (firstImage is Map<String, dynamic> &&
                firstImage.containsKey('filepath')) {
              final filepath = firstImage['filepath'].toString();
              print('Found filepath: $filepath');
              return 'http://81.10.91.96:8132/$filepath';
            }

            // Also check for 'filePath' field (camel case variation)
            if (firstImage is Map<String, dynamic> &&
                firstImage.containsKey('filePath')) {
              final filepath = firstImage['filePath'].toString();
              print('Found filePath: $filepath');
              return 'http://81.10.91.96:8132/$filepath';
            }
          }
        } catch (e) {
          print('Error parsing JSON response: $e');
        }
      }

      // If we couldn't get a URL from the API, return empty string
      print('Could not get profile image URL');
      return '';
    } catch (e) {
      print('Error in getProfileImage: $e');
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
      print('Location error: $e');
      return LocationResult(error: 'حدث خطأ أثناء جلب الموقع: $e');
    }
  }
}
