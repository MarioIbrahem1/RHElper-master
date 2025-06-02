import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:road_helperr/providers/settings_provider.dart';
import 'package:road_helperr/ui/screens/ai_welcome_screen.dart';
import 'package:road_helperr/ui/screens/bottomnavigationbar_screes/map_screen.dart';

import '../../../utils/theme_switch.dart';
import '../about_screen.dart';
import 'home_screen.dart';
import 'notification_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:road_helperr/ui/screens/signin_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:road_helperr/services/profile_service.dart';
import 'package:road_helperr/services/api_service.dart';
import 'package:road_helperr/models/profile_data.dart';
import 'package:road_helperr/ui/widgets/profile_image.dart';
import '../edit_profile_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ProfileScreen extends StatefulWidget {
  static const String routeName = "profscreen";
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = "";
  String email = "";
  String selectedLanguage = "English";
  String currentTheme = "System";
  ProfileData? _profileData;
  bool isLoading = true;
  bool _hasLoadedImageBefore = false;
  String _lastLoadedImageUrl = "";

  static const int _selectedIndex = 4;

  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    // Load user data first, then fetch profile image
    _loadUserData().then((_) {
      if (mounted) {
        _fetchProfileImage();

        // إضافة تأخير قصير ثم إعادة تحميل صورة البروفايل مرة أخرى
        // هذا يساعد في حالة مستخدمي Google حيث قد تكون الصورة غير متاحة فورًا
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _fetchProfileImage();
          }
        });
      }
    });
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('logged_in_email');
      final isGoogleSignIn = prefs.getBool('is_google_sign_in') ?? false;

      if (userEmail != null && userEmail.isNotEmpty) {
        email = userEmail;

        // First check if we have cached profile data
        bool loadedFromCache = false;
        final hasFreshCache = await ProfileData.hasFreshCachedData();

        if (hasFreshCache) {
          final cachedData = await ProfileData.loadFromCache();
          if (cachedData != null && cachedData.email == userEmail) {
            debugPrint('Using cached profile data for $userEmail');
            if (mounted) {
              setState(() {
                _profileData = cachedData;
                name = cachedData.name;
                email = cachedData.email;

                // If we have a cached image URL, update tracking variables
                if (cachedData.profileImage != null &&
                    cachedData.profileImage!.isNotEmpty) {
                  _hasLoadedImageBefore = true;
                  _lastLoadedImageUrl = cachedData.profileImage!;
                }

                isLoading = false;
              });
            }
            loadedFromCache = true;
          }
        }

        // If we couldn't load from cache, load from API
        if (!loadedFromCache) {
          ProfileData profileData;

          // استخدام API مختلف حسب نوع تسجيل الدخول (Google أو عادي)
          if (isGoogleSignIn) {
            debugPrint('Loading Google user profile data for $userEmail');
            try {
              profileData =
                  await _profileService.getGoogleUserProfileData(userEmail);
            } catch (googleError) {
              debugPrint('Error loading Google user data: $googleError');
              // إذا فشل تحميل بيانات Google، جرب الطريقة العادية
              debugPrint('Falling back to regular user profile data');
              profileData = await _profileService.getProfileData(userEmail);
            }
          } else {
            debugPrint('Loading regular user profile data for $userEmail');
            profileData = await _profileService.getProfileData(userEmail);
          }

          if (mounted) {
            setState(() {
              _profileData = profileData;
              name = profileData.name;
              email = profileData.email;
              isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
          Navigator.pushReplacementNamed(context, SignInScreen.routeName);
        }
      }
    } catch (e) {
      debugPrint('Critical error in _loadUserData: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });

        // تحديد رسالة الخطأ بناءً على نوع المستخدم
        final prefs = await SharedPreferences.getInstance();
        final isGoogleSignIn = prefs.getBool('is_google_sign_in') ?? false;

        String errorMessage;
        if (isGoogleSignIn) {
          errorMessage =
              'فشل في تحميل بيانات مستخدم Google. يرجى المحاولة مرة أخرى.';
        } else {
          errorMessage =
              'فشل في تحميل بيانات الملف الشخصي. يرجى المحاولة مرة أخرى.';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'إعادة المحاولة',
                textColor: Colors.white,
                onPressed: () {
                  _loadUserData();
                },
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _fetchProfileImage() async {
    try {
      // Make sure we have a valid email before trying to fetch the image
      if (email.isEmpty) {
        debugPrint('Email is empty, trying to get it from SharedPreferences');
        final prefs = await SharedPreferences.getInstance();
        final userEmail = prefs.getString('logged_in_email');
        if (userEmail != null && userEmail.isNotEmpty) {
          email = userEmail;
          debugPrint('Retrieved email from SharedPreferences: $email');
        } else {
          debugPrint('Could not retrieve email from SharedPreferences');
          return; // Exit if we still don't have an email
        }
      }

      // Check if we already have the image URL in memory and it's valid
      if (_hasLoadedImageBefore &&
          _lastLoadedImageUrl.isNotEmpty &&
          _lastLoadedImageUrl.startsWith('http')) {
        debugPrint('Using already loaded image URL: $_lastLoadedImageUrl');
        return;
      }

      // التحقق مما إذا كان المستخدم قد قام بالتسجيل باستخدام Google
      final prefs = await SharedPreferences.getInstance();
      final isGoogleSignIn = prefs.getBool('is_google_sign_in') ?? false;

      // إذا كان المستخدم قد قام بالتسجيل باستخدام Google، نقوم بتحديث بياناته أولاً
      if (isGoogleSignIn) {
        debugPrint('Fetching Google user data for profile image');

        try {
          // استدعاء API لجلب بيانات مستخدم Google
          final result = await ApiService.getGoogleUserData(email);

          if (result['success'] == true && result['data'] != null) {
            final userData = result['data']['user'];

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
                imageUrl =
                    '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}';
              } else if (!imageUrl.contains('t=')) {
                imageUrl =
                    '$imageUrl&t=${DateTime.now().millisecondsSinceEpoch}';
              }

              if (mounted) {
                setState(() {
                  if (_profileData != null) {
                    _profileData = ProfileData(
                      name: _profileData!.name,
                      email: _profileData!.email,
                      phone: _profileData!.phone,
                      address: _profileData!.address,
                      profileImage: imageUrl,
                      carModel: _profileData!.carModel,
                      carColor: _profileData!.carColor,
                      plateNumber: _profileData!.plateNumber,
                    );
                  } else {
                    _profileData = ProfileData(
                      name: name,
                      email: email,
                      profileImage: imageUrl,
                    );
                  }

                  // تحديث متغيرات التتبع
                  _hasLoadedImageBefore = true;
                  _lastLoadedImageUrl = imageUrl;
                });

                // حفظ البيانات في التخزين المؤقت
                _profileData!.saveToCache();
                return;
              }
            }
          }
        } catch (googleError) {
          debugPrint('Error fetching Google user data: $googleError');
          // استمر في المحاولة بالطرق الأخرى
        }
      }

      // Check if we have a cached image URL
      bool loadedFromCache = false;
      String? cachedImageUrl = await ProfileData.getCachedImageUrl();

      if (cachedImageUrl != null && cachedImageUrl.isNotEmpty) {
        debugPrint('Using cached profile image URL: $cachedImageUrl');

        // Validate the URL format
        if (!cachedImageUrl.startsWith('http')) {
          debugPrint('Invalid cached image URL format: $cachedImageUrl');
          // Try to fix the URL
          if (cachedImageUrl.startsWith('/')) {
            cachedImageUrl = 'http://81.10.91.96:8132$cachedImageUrl';
          } else {
            cachedImageUrl = 'http://81.10.91.96:8132/$cachedImageUrl';
          }
          debugPrint('Fixed cached image URL: $cachedImageUrl');
        }

        // Add cache-busting parameter if not already present
        if (!cachedImageUrl.contains('?')) {
          cachedImageUrl =
              '$cachedImageUrl?t=${DateTime.now().millisecondsSinceEpoch}';
        } else if (!cachedImageUrl.contains('t=')) {
          cachedImageUrl =
              '$cachedImageUrl&t=${DateTime.now().millisecondsSinceEpoch}';
        }

        if (mounted) {
          setState(() {
            if (_profileData != null) {
              _profileData = ProfileData(
                name: _profileData!.name,
                email: _profileData!.email,
                phone: _profileData!.phone,
                address: _profileData!.address,
                profileImage: cachedImageUrl,
                carModel: _profileData!.carModel,
                carColor: _profileData!.carColor,
                plateNumber: _profileData!.plateNumber,
              );
            } else {
              _profileData = ProfileData(
                name: name,
                email: email,
                profileImage: cachedImageUrl,
              );
            }

            // Update tracking variables
            _hasLoadedImageBefore = true;
            _lastLoadedImageUrl = cachedImageUrl!;
          });

          loadedFromCache = true;
        }
      }

      // If we couldn't load from cache or memory, fetch from API
      if (!loadedFromCache) {
        // Clear image cache before fetching to ensure we get the latest image
        imageCache.clear();
        imageCache.clearLiveImages();

        debugPrint('Fetching profile image for email: $email');

        String imageUrl = '';

        // إذا كان المستخدم قد قام بالتسجيل باستخدام Google، فقد تم بالفعل تحميل صورة البروفايل
        // في دالة getGoogleUserProfileData
        if (isGoogleSignIn &&
            _profileData != null &&
            _profileData!.profileImage != null) {
          imageUrl = _profileData!.profileImage!;
          debugPrint('Using Google user profile image: $imageUrl');
        } else {
          // استخدام الطريقة العادية للحصول على صورة البروفايل
          imageUrl =
              await _profileService.getProfileImage(email, useCache: false);
          debugPrint('Fetched profile image URL from API: $imageUrl');
        }

        // If we couldn't get a URL from the API, show a message
        if (imageUrl.isEmpty) {
          debugPrint('Empty image URL returned from API');

          // If we couldn't get the image, retry after a delay (but only once)
          if (mounted && !_hasRetried) {
            _hasRetried = true;
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                _fetchProfileImage();
              }
            });
          } else if (mounted) {
            // Show error message if retry also failed
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Could not load profile image. Please try again later.')),
            );
          }
          return;
        }

        if (mounted) {
          // Validate the URL format
          if (!imageUrl.startsWith('http')) {
            debugPrint('Invalid image URL format: $imageUrl');
            // Try to fix the URL
            if (imageUrl.startsWith('/')) {
              imageUrl = 'http://81.10.91.96:8132$imageUrl';
            } else {
              imageUrl = 'http://81.10.91.96:8132/$imageUrl';
            }
            debugPrint('Fixed image URL: $imageUrl');
          }

          // Add cache-busting parameter if not already present
          if (!imageUrl.contains('?')) {
            imageUrl = '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}';
          } else if (!imageUrl.contains('t=')) {
            imageUrl = '$imageUrl&t=${DateTime.now().millisecondsSinceEpoch}';
          }

          // Check if this is a new image URL or first load
          bool isNewImage =
              !_hasLoadedImageBefore || _lastLoadedImageUrl != imageUrl;

          // Update the state with the new image URL
          setState(() {
            if (_profileData != null) {
              _profileData = ProfileData(
                name: _profileData!.name,
                email: _profileData!.email,
                phone: _profileData!.phone,
                address: _profileData!.address,
                profileImage: imageUrl,
                carModel: _profileData!.carModel,
                carColor: _profileData!.carColor,
                plateNumber: _profileData!.plateNumber,
              );

              // Save the updated profile data to cache
              _profileData!.saveToCache();
            } else {
              _profileData = ProfileData(
                name: name,
                email: email,
                profileImage: imageUrl,
              );

              // Save the profile data to cache
              _profileData!.saveToCache();
            }

            // Update tracking variables
            _hasLoadedImageBefore = true;
            _lastLoadedImageUrl = imageUrl;
          });

          // Only show success message if this is a new image loaded from API
          if (isNewImage) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Profile image loaded successfully')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error in _fetchProfileImage: $e');
      // Show error in UI for debugging
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile image: $e')),
        );
      }
    }
  }

  bool _hasRetried = false; // Track if we've retried fetching the image

  void _logout(BuildContext context) {
    // Store context values before async operations
    final lang = AppLocalizations.of(context);
    final logoutText = lang?.logout ?? 'Logging out...';
    final errorText = lang?.error ?? 'Error';

    // Show loading indicator before async operations
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(logoutText)),
    );

    // Execute logout in a separate function to avoid context issues
    _executeLogout().then((_) {
      // Success - navigate to sign-in screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, SignInScreen.routeName);
      }
    }).catchError((e) {
      debugPrint('Logout error: $e');

      // Show error and navigate anyway
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$errorText: $e')),
        );

        // Navigate to sign-in screen even if there was an error
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, SignInScreen.routeName);
          }
        });
      }
    });
  }

  // Separate async function to handle the actual logout process
  Future<void> _executeLogout() async {
    final prefs = await SharedPreferences.getInstance();
    final isGoogleSignIn = prefs.getBool('is_google_sign_in') ?? false;

    if (isGoogleSignIn) {
      // Handle Google Sign In logout
      try {
        GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
        // We don't use disconnect() as it causes the PlatformException
      } catch (googleError) {
        debugPrint('Google Sign Out error (non-critical): $googleError');
        // Continue with logout even if Google sign out fails
      }
    }

    // Clear SharedPreferences
    await prefs.remove('logged_in_email');
    await prefs.remove('is_google_sign_in');

    // Clear any other auth-related preferences
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.setBool('is_logged_in', false);

    // Clear cached profile data
    await ProfileData.clearCache();
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          email: email,
          initialData: _profileData,
        ),
      ),
    );
    if (result != null && result is ProfileData) {
      setState(() {
        _profileData = result;
        name = result.name;
        email = result.email;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final lang = AppLocalizations.of(context);

    // Update selectedLanguage based on the current locale
    selectedLanguage =
        settingsProvider.currentLocale == 'en' ? "English" : "العربية";

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : const Color(0xFF01122A),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(top: 25.0, left: 10),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          centerTitle: true,
          title: Padding(
            padding: const EdgeInsets.only(top: 25.0),
            child: Text(
              lang?.profile ?? 'Profile',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF86A5D9)
                        : const Color(0xFF1F3551),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                ),
                Positioned(
                  top: 120,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _buildProfileImage(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 230),
                  child: Column(
                    children: [
                      const SizedBox(height: 25),
                      Text(
                        name,
                        style: TextStyle(
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? Colors.black
                                  : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        email,
                        style: TextStyle(
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? Colors.black.withOpacity(0.7)
                                  : Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 35),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildListTile(
                                icon: Icons.edit_outlined,
                                title:
                                    AppLocalizations.of(context)?.editProfile ??
                                        "Edit Profile",
                                onTap: _navigateToEditProfile,
                              ),
                              const SizedBox(height: 5),
                              _buildLanguageSelector(),
                              const SizedBox(height: 5),
                              _buildThemeSelector(),
                              const SizedBox(height: 5),
                              _buildListTile(
                                icon: Icons.info_outline,
                                title: AppLocalizations.of(context)?.about ??
                                    "About",
                                onTap: () {
                                  Navigator.of(context)
                                      .pushNamed(AboutScreen.routeName);
                                },
                              ),
                              const SizedBox(height: 5),
                              _buildListTile(
                                icon: Icons.logout,
                                title: AppLocalizations.of(context)?.logout ??
                                    "Logout",
                                onTap: () => _logout(context),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(bottom: 0),
        child: CurvedNavigationBar(
          backgroundColor: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : const Color(0xFF01122A),
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1F3551)
              : const Color(0xFF023A87),
          buttonBackgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1F3551)
              : const Color(0xFF023A87),
          animationDuration: const Duration(milliseconds: 300),
          height: 45,
          index: _selectedIndex,
          items: const [
            Icon(Icons.home_outlined, size: 18, color: Colors.white),
            Icon(Icons.location_on_outlined, size: 18, color: Colors.white),
            Icon(Icons.textsms_outlined, size: 18, color: Colors.white),
            Icon(Icons.notifications_outlined, size: 18, color: Colors.white),
            Icon(Icons.person_2_outlined, size: 18, color: Colors.white),
          ],
          onTap: (index) => _handleNavigation(context, index),
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon,
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.black
              : Colors.white),
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.black
              : Colors.white,
          fontSize: 16,
        ),
      ),
      trailing: trailing ??
          Icon(Icons.arrow_forward_ios,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.black
                  : Colors.white,
              size: 16),
      onTap: onTap,
    );
  }

  Widget _buildLanguageSelector() {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final lang = AppLocalizations.of(context);

    return _buildListTile(
      icon: Icons.language,
      title: lang?.language ?? "Language",
      trailing: PopupMenuButton<String>(
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedLanguage,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black.withOpacity(0.7)
                    : Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.black
                  : Colors.white,
              size: 16,
            ),
          ],
        ),
        color: const Color(0xFF1F3551),
        onSelected: (String value) {
          setState(() {
            selectedLanguage = value;
            // Change the app locale using the SettingsProvider
            if (value == "English") {
              settingsProvider.changeLocale('en');
            } else {
              settingsProvider.changeLocale('ar');
            }
          });
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: "English",
            child: Text(
              lang?.english ?? 'English',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          PopupMenuItem<String>(
            value: "العربية",
            child: Text(
              lang?.arabic ?? 'العربية',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      onTap: () {},
    );
  }

  Widget _buildThemeSelector() {
    final lang = AppLocalizations.of(context);
    return _buildListTile(
      icon: Theme.of(context).platform == TargetPlatform.iOS
          ? CupertinoIcons.paintbrush
          : Icons.palette_outlined,
      title: lang?.darkMode ?? "Theme",
      trailing: const ThemeSwitch(),
      onTap: () {},
    );
  }

  Widget _buildProfileImage() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // إذا كان لدينا صورة بروفايل في _profileData، نعرضها مباشرة
        if (_profileData != null &&
            _profileData!.profileImage != null &&
            _profileData!.profileImage!.isNotEmpty &&
            _profileData!.profileImage!.startsWith('http'))
          CircleAvatar(
            radius: 65,
            backgroundColor: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFF86A5D9)
                : Colors.white,
            backgroundImage: NetworkImage(
              // إضافة معلمة لمنع التخزين المؤقت
              _profileData!.profileImage!.contains('?')
                  ? '${_profileData!.profileImage!}&t=${DateTime.now().millisecondsSinceEpoch}'
                  : '${_profileData!.profileImage!}?t=${DateTime.now().millisecondsSinceEpoch}',
            ),
            onBackgroundImageError: (exception, stackTrace) {
              debugPrint('Error loading profile image: $exception');
              // في حالة حدوث خطأ، نستخدم ProfileImageWidget
              if (mounted) {
                setState(() {
                  _hasLoadedImageBefore = false;
                });
              }
            },
          )
        else
          ProfileImageWidget(
            email: email,
            size: 130,
            backgroundColor: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFF86A5D9)
                : Colors.white,
            iconColor: Colors.white,
            onTap: () {
              // Allow manual retry on tap if there's an error
              _fetchProfileImage();
            },
          ),
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFF023A87)
                  : const Color(0xFF1F3551),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
              onPressed: _pickAndUploadImage,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickAndUploadImage() async {
    try {
      // Show a dialog to choose between camera and gallery
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Image Source'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) {
        return; // User canceled the dialog
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80, // Reduce image quality to improve upload speed
        maxWidth: 800, // Limit image width to reduce file size
      );

      if (image != null) {
        setState(() {
          isLoading = true;
        });

        final File imageFile = File(image.path);
        debugPrint('Selected image path: ${image.path}');
        debugPrint('Image file size: ${await imageFile.length()} bytes');

        // Check if email is available
        if (email.isEmpty) {
          final prefs = await SharedPreferences.getInstance();
          final userEmail = prefs.getString('logged_in_email');
          if (userEmail != null && userEmail.isNotEmpty) {
            email = userEmail;
            debugPrint('Retrieved email from SharedPreferences: $email');
          } else {
            if (mounted) {
              setState(() {
                isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('User email not found. Please log in again.')),
              );
            }
            return;
          }
        }

        // Show uploading progress
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uploading image...')),
          );
        }

        // Upload the image
        final String imageUrl =
            await _profileService.uploadProfileImage(email, imageFile);
        debugPrint('Uploaded image URL: $imageUrl');

        if (mounted) {
          if (imageUrl.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Failed to upload image. Please try again.')),
            );
            setState(() {
              isLoading = false;
            });
            return;
          }

          // Clear image cache
          imageCache.clear();
          imageCache.clearLiveImages();

          // Check if this is a new image URL
          bool isNewImage = _lastLoadedImageUrl != imageUrl;

          setState(() {
            if (_profileData != null) {
              _profileData = ProfileData(
                name: _profileData!.name,
                email: _profileData!.email,
                phone: _profileData!.phone,
                address: _profileData!.address,
                profileImage: imageUrl,
                carModel: _profileData!.carModel,
                carColor: _profileData!.carColor,
                plateNumber: _profileData!.plateNumber,
              );
            } else {
              _profileData = ProfileData(
                name: name,
                email: email,
                profileImage: imageUrl,
              );
            }

            // Update tracking variables
            _hasLoadedImageBefore = true;
            _lastLoadedImageUrl = imageUrl;
            isLoading = false;
          });

          // Only show success message if this is a new image
          if (isNewImage) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Profile image updated successfully')),
            );
          }

          // Force refresh of the profile image widget
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _fetchProfileImage();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error in _pickAndUploadImage: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }

    // No need to fetch the image again, the ProfileImageWidget will handle it
  }

  void _handleNavigation(BuildContext context, int index) {
    if (index != _selectedIndex) {
      final routes = [
        HomeScreen.routeName,
        MapScreen.routeName,
        AiWelcomeScreen.routeName,
        NotificationScreen.routeName,
        ProfileScreen.routeName,
      ];
      Navigator.pushReplacementNamed(context, routes[index]);
    }
  }
}
