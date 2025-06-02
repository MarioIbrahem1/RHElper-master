import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:road_helperr/models/user_location.dart';
import 'package:road_helperr/models/help_request.dart';
import 'package:road_helperr/models/user_rating.dart';
import 'package:road_helperr/services/auth_service.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

class ApiService {
  static const String baseUrl = 'http://81.10.91.96:8132';

  // Get token from auth service
  static Future<String> _getToken() async {
    final authService = AuthService();
    final token = await authService.getToken() ?? '';
    debugPrint(
        'Retrieved token: ${token.isNotEmpty ? 'Token exists' : 'Token is empty'}');
    return token;
  }

  // Check internet connectivity
  static Future<bool> _checkConnectivity() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      bool hasConnection = connectivityResult != ConnectivityResult.none;
      debugPrint('Internet connection available: $hasConnection');
      return hasConnection;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return false;
    }
  }

  // Login API
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    if (!await _checkConnectivity()) {
      return {
        'error':
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى'
      };
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // حفظ بيانات المصادقة
        if (responseData['token'] != null) {
          final authService = AuthService();
          await authService.saveAuthData(
            token: responseData['token'],
            userId: responseData['user_id'] ?? '',
            email: email,
            name: responseData['name'],
          );
          debugPrint('تم حفظ بيانات المصادقة بعد تسجيل الدخول');
        }

        return responseData;
      } else {
        final errorBody = json.decode(response.body);
        return {
          'error':
              'فشل تسجيل الدخول: ${errorBody['message'] ?? 'خطأ غير معروف'} (كود الخطأ: ${response.statusCode})'
        };
      }
    } catch (e) {
      if (e is http.ClientException) {
        return {
          'error':
              'فشل الاتصال بالخادم: ${e.message}. تأكد من صحة عنوان الخادم والبورت'
        };
      }
      return {'error': 'حدث خطأ غير متوقع: $e'};
    }
  }

  // Send OTP API
  static Future<Map<String, dynamic>> sendOTP(String email) async {
    if (!await _checkConnectivity()) {
      return {
        'success': false,
        'error':
            'No internet connection. Please check your connection and try again'
      };
    }

    try {
      final requestData = {'email': email};
      print('Sending OTP request to: $baseUrl/otp/send');
      print('Request data: ${jsonEncode(requestData)}');
      print(
          'Request headers: {"Content-Type": "application/json", "Accept": "application/json"}');

      final response = await http.post(
        Uri.parse('$baseUrl/otp/send'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      print('Response status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'OTP sent successfully'
        };
      } else if (response.statusCode == 404) {
        // إذا كان البريد الإلكتروني غير موجود
        return {
          'success': false,
          'error': 'This email is not registered in our system'
        };
      } else if (response.statusCode == 400) {
        // إذا كان هناك خطأ في تنسيق البريد الإلكتروني
        return {'success': false, 'error': 'Invalid email format'};
      } else {
        // أي خطأ آخر من الخادم
        return {
          'success': false,
          'error':
              responseData['message'] ?? 'Server error. Please try again later'
        };
      }
    } catch (e) {
      print('Error in sendOTP: $e');
      if (e is http.ClientException) {
        return {
          'success': false,
          'error':
              'Connection error. Please check your internet connection and try again'
        };
      }
      return {
        'success': false,
        'error':
            'An unexpected error occurred while sending OTP. Please try again'
      };
    }
  }

  // Send OTP Without Verification (for signup only)
  static Future<Map<String, dynamic>> sendOTPWithoutVerification(
      String email) async {
    if (!await _checkConnectivity()) {
      return {
        'success': false,
        'error':
            'No internet connection. Please check your connection and try again'
      };
    }

    try {
      final requestData = {'email': email};
      print(
          'Sending OTP without verification request to: $baseUrl/otp/send-without-verification');
      print('Request data: ${jsonEncode(requestData)}');

      final response = await http.post(
        Uri.parse('$baseUrl/otp/send-without-verification'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'OTP sent successfully'
        };
      } else if (response.statusCode == 400) {
        return {'success': false, 'error': 'Invalid email format'};
      } else {
        return {
          'success': false,
          'error':
              responseData['message'] ?? 'Server error. Please try again later'
        };
      }
    } catch (e) {
      print('Error in sendOTPWithoutVerification: $e');
      if (e is http.ClientException) {
        return {
          'success': false,
          'error':
              'Connection error. Please check your internet connection and try again'
        };
      }
      return {
        'success': false,
        'error':
            'An unexpected error occurred while sending OTP. Please try again'
      };
    }
  }

  // Register API - Updated to verify OTP first
  static Future<Map<String, dynamic>> register(
      Map<String, dynamic> userData, String otp) async {
    if (!await _checkConnectivity()) {
      return {
        'error':
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى'
      };
    }

    try {
      // First verify the OTP
      final String email = userData['email'];
      print('Verifying OTP before registration for email: $email');
      print('OTP being verified: $otp');

      final verifyResult = await verifyOTP(email, otp);
      print('OTP verification result: $verifyResult');

      // If OTP verification failed, return the error immediately
      if (!verifyResult.containsKey('success') ||
          verifyResult['success'] != true) {
        return {
          'error': 'فشل التحقق من رمز OTP. يرجى التأكد من الرمز وإعادة المحاولة'
        };
      }

      // Only proceed with registration if OTP verification was successful
      print('OTP verified successfully, proceeding with registration');
      print('Registration data being sent: $userData');

      final response = await http.post(
        Uri.parse('$baseUrl/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      print('Registration response status: ${response.statusCode}');
      print('Registration response body: ${response.body}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
          'message': 'تم التسجيل بنجاح'
        };
      } else {
        final errorBody = json.decode(response.body);
        return {
          'error':
              'فشل التسجيل: ${errorBody['message'] ?? 'خطأ غير معروف'} (كود الخطأ: ${response.statusCode})'
        };
      }
    } catch (e) {
      debugPrint('Error during registration process: $e');
      if (e is http.ClientException) {
        return {
          'error':
              'فشل الاتصال بالخادم: ${e.message}. تأكد من صحة عنوان الخادم والبورت'
        };
      }
      return {'error': 'حدث خطأ غير متوقع: $e'};
    }
  }

  // Verify OTP API - Improved with better error handling
  static Future<Map<String, dynamic>> verifyOTP(
      String email, String otp) async {
    if (!await _checkConnectivity()) {
      return {'error': 'لا يوجد اتصال بالإنترنت'};
    }

    try {
      debugPrint('Verifying OTP request to: $baseUrl/otp/verify');
      debugPrint('Data being sent: email=$email, otp=$otp');

      final response = await http.post(
        Uri.parse('$baseUrl/otp/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response headers: ${response.headers}');
      debugPrint('Response body: ${response.body}');

      try {
        final responseData = jsonDecode(response.body);
        debugPrint('Decoded response: $responseData');

        if (response.statusCode == 200) {
          return {
            'success': true,
            'message': responseData['message'] ?? 'تم التحقق بنجاح'
          };
        } else if (response.statusCode == 400 || response.statusCode == 401) {
          return {'error': responseData['message'] ?? 'رمز التحقق غير صحيح'};
        } else {
          return {
            'error': 'حدث خطأ في التحقق من الرمز (${response.statusCode})'
          };
        }
      } catch (e) {
        debugPrint('Error decoding response: $e');
        return {'error': 'تنسيق استجابة غير صالح من الخادم'};
      }
    } catch (e) {
      debugPrint('Error in verifyOTP: $e');
      return {'error': 'حدث خطأ أثناء التحقق من الرمز: $e'};
    }
  }

  // Check if email exists using the API endpoint
  static Future<Map<String, dynamic>> checkEmailExists(String email) async {
    try {
      // Check connectivity first
      if (!await _checkConnectivity()) {
        debugPrint('=== فحص البريد الإلكتروني ===');
        debugPrint('❌ لا يوجد اتصال بالإنترنت');
        debugPrint('============================');
        return {
          'success': false,
          'exists': false,
          'message': 'No internet connection',
        };
      }

      // تحضير بيانات الطلب
      final Map<String, dynamic> requestData = {'email': email};

      // Send GET request with email in body (using http.Request for more control)
      final request =
          http.Request('GET', Uri.parse('$baseUrl/api/check-email'));
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'application/json';
      request.body = jsonEncode(requestData);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);

          // Based on the Postman screenshot, we expect:
          // {"status": "success", "message": "Email does not exist"} when email doesn't exist

          if (data.containsKey('status')) {
            // Get the message from the response
            final message = data['message'] ?? '';
            final status = data['status'];

            // Exactly as shown in Postman:
            // If status is "success" and message is "Email does not exist", email doesn't exist
            if (status == 'success' && message == 'Email does not exist') {
              return {
                'success': true,
                'exists': false,
                'message': 'البريد الإلكتروني غير موجود في النظام',
                'message_en': 'Email does not exist in the system',
              };
            }
            // If status is not success or message indicates email exists
            else {
              return {
                'success': true,
                'exists': true,
                'message': 'هذا البريد الإلكتروني مرتبط بحساب موجود بالفعل',
                'message_en':
                    'This email is already associated with an existing account',
              };
            }
          }

          // Fallback for other response formats
          return {
            'success': true,
            'exists': false,
            'message': 'تم التحقق من البريد الإلكتروني',
            'message_en': 'Email check completed',
          };
        } catch (e) {
          return {
            'success': false,
            'exists': false,
            'message': 'حدث خطأ أثناء تحليل استجابة الخادم',
            'message_en': 'Invalid response format from server',
          };
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'exists': false,
            'message':
                errorData['message'] ?? 'فشل التحقق من وجود البريد الإلكتروني',
            'message_en':
                errorData['message'] ?? 'Failed to check email existence',
          };
        } catch (e) {
          return {
            'success': false,
            'exists': false,
            'message': 'فشل التحقق من وجود البريد الإلكتروني',
            'message_en': 'Failed to check email existence',
          };
        }
      }
    } catch (e) {
      if (e is http.ClientException) {
        return {
          'success': false,
          'exists': false,
          'message': 'خطأ في الاتصال بالخادم',
          'message_en': 'Connection error',
        };
      }
      return {
        'success': false,
        'exists': false,
        'message': 'حدث خطأ أثناء التحقق من البريد الإلكتروني',
        'message_en': 'An error occurred while checking email',
      };
    }
  }

  static Future<Map<String, dynamic>> resetPassword(
      String email, String newPassword) async {
    if (!await _checkConnectivity()) {
      return {
        'error':
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى'
      };
    }

    try {
      debugPrint(
          'Sending reset password request to: $baseUrl/api/reset-password');
      debugPrint(
          'Data being sent: {"email": "$email", "password": "$newPassword"}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/reset-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': newPassword,
        }),
      );

      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'تم إعادة تعيين كلمة المرور بنجاح'
        };
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage =
            errorData['message'] ?? 'فشل في إعادة تعيين كلمة المرور';

        // تحسين رسائل الخطأ
        if (response.statusCode == 404) {
          errorMessage = 'البريد الإلكتروني غير مسجل في النظام';
        } else if (response.statusCode == 400) {
          errorMessage = 'كلمة المرور الجديدة غير صالحة';
        } else if (response.statusCode == 500) {
          errorMessage = 'حدث خطأ في الخادم. يرجى المحاولة مرة أخرى لاحقاً';
        }

        return {'error': errorMessage};
      }
    } catch (e) {
      debugPrint('Error in resetPassword: $e');
      if (e is http.ClientException) {
        return {
          'error':
              'فشل الاتصال بالخادم. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى'
        };
      }
      return {
        'error':
            'حدث خطأ غير متوقع أثناء إعادة تعيين كلمة المرور. يرجى المحاولة مرة أخرى'
      };
    }
  }

  // Update user's location
  static Future<void> updateUserLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Check connectivity first
      if (!await _checkConnectivity()) {
        debugPrint('No internet connection when updating location');
        throw Exception('No internet connection available');
      }

      // Get token and check if it's valid
      final token = await _getToken();
      if (token.isEmpty) {
        debugPrint('Empty token when updating location');
        throw Exception('Authentication token is empty');
      }

      debugPrint('Sending location update to server: $latitude, $longitude');

      final response = await http.post(
        Uri.parse('$baseUrl/update-location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      debugPrint('Location update response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint(
            'Failed to update location. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to update location: ${response.statusCode}');
      }

      debugPrint('Location updated successfully');
    } catch (e) {
      debugPrint('Error updating location: $e');
      throw Exception('Error updating location: $e');
    }
  }

  // Get nearby users
  static Future<List<UserLocation>> getNearbyUsers({
    required double latitude,
    required double longitude,
    required double radius,
  }) async {
    try {
      // Check connectivity first
      if (!await _checkConnectivity()) {
        debugPrint('No internet connection when fetching nearby users');
        throw Exception('No internet connection available');
      }

      // Get token and check if it's valid
      final token = await _getToken();
      if (token.isEmpty) {
        debugPrint('Empty token when fetching nearby users');
        throw Exception('Authentication token is empty');
      }

      debugPrint(
          'Fetching nearby users at: $latitude, $longitude with radius: $radius meters');

      final url =
          '$baseUrl/nearby-users?latitude=$latitude&longitude=$longitude&radius=$radius';
      debugPrint('Request URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Nearby users response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = response.body;
        debugPrint('Response body length: ${responseBody.length}');

        if (responseBody.isEmpty) {
          debugPrint('Empty response body');
          return [];
        }

        try {
          final List<dynamic> data = jsonDecode(responseBody);
          debugPrint('Found ${data.length} nearby users in response');

          final users =
              data.map((json) => UserLocation.fromJson(json)).toList();

          // Log each user's details for debugging
          for (var user in users) {
            debugPrint(
                'User: ${user.userName}, Position: ${user.position.latitude}, ${user.position.longitude}');
          }

          return users;
        } catch (parseError) {
          debugPrint('Error parsing nearby users response: $parseError');
          throw Exception('Failed to parse nearby users response: $parseError');
        }
      } else {
        debugPrint(
            'Failed to fetch nearby users. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to fetch nearby users: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching nearby users: $e');
      throw Exception('Error fetching nearby users: $e');
    }
  }

  // Get user data by email
  static Future<Map<String, dynamic>> getUserData(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/data'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"email": email}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch user data');
      }
    } catch (e) {
      throw Exception('Error fetching user data: $e');
    }
  }

  // Send help request
  static Future<Map<String, dynamic>> sendHelpRequest({
    required String receiverId,
    required LatLng senderLocation,
    required LatLng receiverLocation,
    String? message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/help-request/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getToken()}',
        },
        body: jsonEncode({
          'receiverId': receiverId,
          'senderLocation': {
            'latitude': senderLocation.latitude,
            'longitude': senderLocation.longitude,
          },
          'receiverLocation': {
            'latitude': receiverLocation.latitude,
            'longitude': receiverLocation.longitude,
          },
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to send help request');
      }
    } catch (e) {
      throw Exception('Error sending help request: $e');
    }
  }

  // Respond to help request
  static Future<Map<String, dynamic>> respondToHelpRequest({
    required String requestId,
    required bool accept,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/help-request/respond'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getToken()}',
        },
        body: jsonEncode({
          'requestId': requestId,
          'accept': accept,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to respond to help request');
      }
    } catch (e) {
      throw Exception('Error responding to help request: $e');
    }
  }

  // Get pending help requests
  static Future<List<HelpRequest>> getPendingHelpRequests() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/help-request/pending'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => HelpRequest.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch pending help requests');
      }
    } catch (e) {
      throw Exception('Error fetching pending help requests: $e');
    }
  }

  // Get help request by ID
  static Future<HelpRequest> getHelpRequestById(String requestId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/help-request/$requestId'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return HelpRequest.fromJson(data);
      } else {
        throw Exception('Failed to fetch help request');
      }
    } catch (e) {
      throw Exception('Error fetching help request: $e');
    }
  }

  // Rate a user
  static Future<Map<String, dynamic>> rateUser({
    required String userId,
    required double rating,
    String? comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/rate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getToken()}',
        },
        body: jsonEncode({
          'userId': userId,
          'rating': rating,
          'comment': comment,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to rate user');
      }
    } catch (e) {
      throw Exception('Error rating user: $e');
    }
  }

  // Get user ratings
  static Future<List<UserRating>> getUserRatings(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId/ratings'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => UserRating.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch user ratings');
      }
    } catch (e) {
      throw Exception('Error fetching user ratings: $e');
    }
  }

  // Get user average rating
  static Future<double> getUserAverageRating(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId/average-rating'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['averageRating'].toDouble();
      } else {
        throw Exception('Failed to fetch user average rating');
      }
    } catch (e) {
      throw Exception('Error fetching user average rating: $e');
    }
  }

  static Future<Map<String, dynamic>> registerGoogleUser(
      Map<String, dynamic> userData) async {
    if (!await _checkConnectivity()) {
      return {
        'success': false,
        'error':
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى',
      };
    }

    try {
      debugPrint('Registering Google user with data: $userData');

      // 1. إنشاء طلب متعدد الأجزاء (لرفع الملف)
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/SignUpGoogle'),
      );

      // 2. إضافة الحقول النصية (بنفس الأسماء كما في Postman)
      request.fields['firstName'] = userData['firstName'] ?? '';
      request.fields['lastName'] = userData['lastName'] ?? '';
      request.fields['email'] = userData['email'] ?? '';
      request.fields['phone'] = userData['phone'] ?? '';
      request.fields['car_number'] =
          userData['Car Number'] ?? ''; // مطلوب في Postman
      request.fields['car_color'] =
          userData['car_color'] ?? ''; // مطلوب في Postman
      request.fields['car_model'] =
          userData['car_model'] ?? ''; // مطلوب في Postman

      // 3. رفع الصورة كملف (إذا كانت متوفرة)
      if (userData['photoURL'] != null && userData['photoURL'].isNotEmpty) {
        try {
          // تنزيل الصورة من رابط Google
          var imageResponse = await http.get(Uri.parse(userData['photoURL']));
          if (imageResponse.statusCode == 200) {
            // حفظ الصورة مؤقتًا
            final tempDir = await path_provider.getTemporaryDirectory();
            final filePath =
                '${tempDir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final file = File(filePath);
            await file.writeAsBytes(imageResponse.bodyBytes);

            // إضافة الملف إلى الطلب (باسم profile_picture كما في Postman)
            request.files.add(
              await http.MultipartFile.fromPath(
                'profile_picture', // اسم الحقل في الخادم
                file.path,
              ),
            );
            debugPrint('تم إرفاق صورة البروفايل كملف');
          }
        } catch (e) {
          debugPrint('فشل تحميل الصورة: $e');
        }
      }

      // 4. إرسال الطلب
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      debugPrint('Google registration response status: ${response.statusCode}');
      debugPrint('Google registration response body: $responseData');

      if (response.statusCode == 200) {
        // حفظ بيانات المستخدم في الجلسة (إذا كان الخادم يُرجع token أو user data)
        if (jsonResponse['data'] != null &&
            jsonResponse['data']['user'] != null) {
          final user = jsonResponse['data']['user'];
          final authService = AuthService();
          await authService.saveAuthData(
            token: jsonResponse['token'] ?? '',
            userId: user['id'].toString(),
            email: user['email'] ?? '',
            name: '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}',
          );
        }

        return {
          'success': true,
          'data': jsonResponse['data'],
          'message': jsonResponse['message'] ?? 'تم التسجيل بنجاح',
        };
      } else {
        return {
          'success': false,
          'error':
              jsonResponse['message'] ?? 'فشل التسجيل (${response.statusCode})',
        };
      }
    } catch (e) {
      debugPrint('Error during Google registration: $e');
      return {
        'success': false,
        'error': 'حدث خطأ غير متوقع: ${e.toString()}',
      };
    }
  }

  // استرجاع بيانات المستخدم الذي قام بالتسجيل أو تسجيل الدخول باستخدام Google
  static Future<Map<String, dynamic>> getGoogleUserData(String email) async {
    if (!await _checkConnectivity()) {
      return {
        'success': false,
        'error':
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى',
      };
    }

    try {
      debugPrint('Fetching Google user data for email: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/api/datagoogle'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      debugPrint('Google user data response status: ${response.statusCode}');
      debugPrint('Google user data response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // التحقق من نجاح الاستجابة
        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          return {
            'success': true,
            'data': responseData['data'],
          };
        } else {
          return {
            'success': false,
            'error':
                responseData['message'] ?? 'لم يتم العثور على بيانات المستخدم',
          };
        }
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ??
              'فشل استرجاع بيانات المستخدم (${response.statusCode})',
        };
      }
    } catch (e) {
      debugPrint('Error fetching Google user data: $e');
      if (e is http.ClientException) {
        return {
          'success': false,
          'error':
              'فشل الاتصال بالخادم. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى',
        };
      }
      return {
        'success': false,
        'error':
            'حدث خطأ غير متوقع أثناء استرجاع بيانات المستخدم: ${e.toString()}',
      };
    }
  }

  // تحديث بيانات المستخدم الذي قام بالتسجيل أو تسجيل الدخول باستخدام Google
  static Future<Map<String, dynamic>> updateGoogleUser(
      Map<String, dynamic> userData) async {
    if (!await _checkConnectivity()) {
      return {
        'success': false,
        'error':
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى',
      };
    }

    try {
      debugPrint('Updating Google user with data: $userData');

      // إنشاء طلب متعدد الأجزاء (form-data) كما هو موضح في Postman
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/api/updateusergoogle'),
      );

      // إضافة الحقول النصية (بنفس الأسماء كما في Postman)
      if (userData['email'] != null) {
        request.fields['email'] = userData['email'].toString();
      }
      if (userData['firstName'] != null) {
        request.fields['firstName'] = userData['firstName'].toString();
      }
      if (userData['lastName'] != null) {
        request.fields['lastName'] = userData['lastName'].toString();
      }
      if (userData['phone'] != null) {
        request.fields['phone'] = userData['phone'].toString();
      }
      if (userData['car_number'] != null) {
        request.fields['car_number'] = userData['car_number'].toString();
      }
      if (userData['car_color'] != null) {
        request.fields['car_color'] = userData['car_color'].toString();
      }
      if (userData['car_model'] != null) {
        request.fields['car_model'] = userData['car_model'].toString();
      }

      // رفع الصورة كملف (إذا كانت متوفرة)
      if (userData['profile_picture'] != null &&
          userData['profile_picture'] is File) {
        try {
          final file = userData['profile_picture'] as File;
          if (await file.exists()) {
            request.files.add(
              await http.MultipartFile.fromPath(
                'profile_picture', // اسم الحقل في الخادم
                file.path,
              ),
            );
            debugPrint('تم إرفاق صورة البروفايل كملف');
          }
        } catch (e) {
          debugPrint('فشل إرفاق الصورة: $e');
        }
      }

      debugPrint('=== UPDATE GOOGLE USER REQUEST ===');
      debugPrint('URL: ${request.url}');
      debugPrint('Method: ${request.method}');
      debugPrint('Fields: ${request.fields}');
      debugPrint('Files: ${request.files.map((f) => f.field).toList()}');
      debugPrint('===================================');

      // إرسال الطلب
      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      debugPrint('=== UPDATE GOOGLE USER RESPONSE ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: $responseData');
      debugPrint('===================================');

      if (response.statusCode == 200) {
        try {
          var jsonResponse = json.decode(responseData);

          return {
            'success': true,
            'data': jsonResponse,
            'message': jsonResponse['message'] ?? 'تم تحديث البيانات بنجاح',
          };
        } catch (e) {
          // إذا لم يكن الرد JSON، نعتبر العملية ناجحة إذا كان status code 200
          return {
            'success': true,
            'message': 'تم تحديث البيانات بنجاح',
          };
        }
      } else {
        try {
          var jsonResponse = json.decode(responseData);
          return {
            'success': false,
            'error': jsonResponse['message'] ??
                'فشل تحديث البيانات (${response.statusCode})',
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'فشل تحديث البيانات (${response.statusCode})',
          };
        }
      }
    } catch (e) {
      debugPrint('Error during Google user update: $e');
      return {
        'success': false,
        'error': 'حدث خطأ غير متوقع: ${e.toString()}',
      };
    }
  }
}
