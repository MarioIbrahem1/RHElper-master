import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileImageWidget extends StatefulWidget {
  final String email;
  final double size;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback? onTap;

  const ProfileImageWidget({
    super.key,
    required this.email,
    this.size = 130,
    this.backgroundColor = Colors.white,
    this.iconColor = Colors.white,
    this.onTap,
  });

  @override
  State<ProfileImageWidget> createState() => _ProfileImageWidgetState();
}

class _ProfileImageWidgetState extends State<ProfileImageWidget> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _hasError = false;
  String _timestamp = DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();
    _fetchProfileImage();
  }

  @override
  void didUpdateWidget(ProfileImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.email != widget.email) {
      _fetchProfileImage();
    }
  }

  Future<void> _fetchProfileImage() async {
    if (widget.email.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Generate a new timestamp for cache busting
      _timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // التحقق مما إذا كان المستخدم قد قام بالتسجيل باستخدام Google
      final prefs = await SharedPreferences.getInstance();
      final isGoogleSignIn = prefs.getBool('is_google_sign_in') ?? false;

      // إذا كان المستخدم قد قام بالتسجيل باستخدام Google، نحاول الحصول على صورة البروفايل من API الخاص بمستخدمي Google
      if (isGoogleSignIn) {
        debugPrint(
            'This is a Google user, trying to fetch Google profile image');

        // استدعاء API لجلب بيانات مستخدم Google
        final response = await http.post(
          Uri.parse('http://81.10.91.96:8132/api/datagoogle'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'email': widget.email.trim(),
          }),
        );

        debugPrint('Google API response status code: ${response.statusCode}');
        debugPrint('Google API response body: ${response.body}');

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);

          if (jsonResponse['status'] == 'success' &&
              jsonResponse['data'] != null) {
            final userData = jsonResponse['data']['user'];

            if (userData['profile_picture'] != null) {
              String imageUrl = userData['profile_picture'].toString();
              debugPrint('Found Google user profile image: $imageUrl');

              // التأكد من أن الرابط صحيح
              if (!imageUrl.startsWith('http')) {
                if (imageUrl.startsWith('/')) {
                  imageUrl = 'http://81.10.91.96:8132$imageUrl';
                } else {
                  imageUrl = 'http://81.10.91.96:8132/$imageUrl';
                }
                debugPrint('Fixed Google user image URL: $imageUrl');
              }

              // إضافة معلمة لمنع التخزين المؤقت
              if (!imageUrl.contains('?')) {
                imageUrl = '$imageUrl?t=$_timestamp';
              } else if (!imageUrl.contains('t=')) {
                imageUrl = '$imageUrl&t=$_timestamp';
              }

              // تحميل الصورة من الرابط
              _fetchImageFromUrl(imageUrl);
              return;
            }
          }
        }
      }

      // إذا لم نتمكن من الحصول على صورة البروفايل من API الخاص بمستخدمي Google، نستخدم الطريقة العادية
      debugPrint('Fetching profile image for email: ${widget.email}');

      // Create a GET request with a body
      final request =
          http.Request('GET', Uri.parse('http://81.10.91.96:8132/api/images'));
      request.headers.addAll({'Content-Type': 'application/json'});
      request.body = jsonEncode({"email": widget.email.trim()});

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('Request timed out for profile image');
          throw Exception('Request timed out');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final imageUrl = _extractImageUrlFromResponse(response);
        if (imageUrl.isNotEmpty) {
          return; // Success!
        }
      }

      // If we get here, the request failed
      debugPrint('Failed to get profile image');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    } catch (e) {
      debugPrint('Error fetching profile image: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  // Helper method to extract image URL from response and load the image
  String _extractImageUrlFromResponse(http.Response response) {
    try {
      final jsonResponse = jsonDecode(response.body);
      debugPrint('Response: ${response.body}');

      // Check if the response has the expected structure
      if (jsonResponse['status'] == 'success' &&
          jsonResponse['images'] is List &&
          (jsonResponse['images'] as List).isNotEmpty) {
        // Get the first image from the list
        final firstImage = jsonResponse['images'][0];
        debugPrint('First image: $firstImage');

        // Check for imageUrl field
        if (firstImage is Map<String, dynamic>) {
          String? imageUrl;

          // Try to find URL in various possible fields
          if (firstImage.containsKey('imageUrl')) {
            imageUrl = firstImage['imageUrl'].toString();
            debugPrint('Found image URL in imageUrl field: $imageUrl');
          } else if (firstImage.containsKey('filepath')) {
            final filepath = firstImage['filepath'].toString();
            imageUrl = 'http://81.10.91.96:8132/$filepath';
            debugPrint('Found image URL in filepath field: $imageUrl');
          } else if (firstImage.containsKey('filePath')) {
            final filepath = firstImage['filePath'].toString();
            imageUrl = 'http://81.10.91.96:8132/$filepath';
            debugPrint('Found image URL in filePath field: $imageUrl');
          } else {
            // Look for any field that might contain a URL or path
            for (var key in firstImage.keys) {
              if (key.toLowerCase().contains('url') ||
                  key.toLowerCase().contains('path')) {
                imageUrl = firstImage[key].toString();
                debugPrint('Found image URL in $key field: $imageUrl');
                break;
              }
            }
          }

          // If we found a URL, try to fetch the image
          if (imageUrl != null && imageUrl.isNotEmpty) {
            // Make sure URL is properly formatted
            if (!imageUrl.startsWith('http')) {
              imageUrl = 'http://81.10.91.96:8132/$imageUrl';
            }

            // Add cache busting
            if (!imageUrl.contains('?')) {
              imageUrl = '$imageUrl?t=$_timestamp';
            } else {
              imageUrl = '$imageUrl&t=$_timestamp';
            }

            debugPrint('Fetching image from URL: $imageUrl');

            _fetchImageFromUrl(imageUrl);
            return imageUrl;
          }
        }
      }

      return '';
    } catch (e) {
      debugPrint('Error parsing JSON: $e');
      // If it's not JSON, assume it's binary image data
      setState(() {
        _imageBytes = response.bodyBytes;
        _isLoading = false;
      });
      return 'binary-data';
    }
  }

  // Helper method to fetch image from URL
  Future<void> _fetchImageFromUrl(String imageUrl) async {
    try {
      final imageResponse = await http.get(Uri.parse(imageUrl));
      if (imageResponse.statusCode == 200) {
        if (mounted) {
          setState(() {
            _imageBytes = imageResponse.bodyBytes;
            _isLoading = false;
          });
        }
      } else {
        debugPrint('Failed to fetch image: ${imageResponse.statusCode}');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching image from URL: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ?? (_hasError ? _fetchProfileImage : null),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.backgroundColor,
        ),
        child: ClipOval(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).primaryColor,
                  ),
                )
              : _hasError || _imageBytes == null
                  ? Icon(
                      Icons.person,
                      size: widget.size * 0.5,
                      color: widget.iconColor,
                    )
                  : Image.memory(
                      _imageBytes!,
                      fit: BoxFit.cover,
                      key: ValueKey(
                          'profile_image_$_timestamp'), // Force refresh when timestamp changes
                    ),
        ),
      ),
    );
  }
}
