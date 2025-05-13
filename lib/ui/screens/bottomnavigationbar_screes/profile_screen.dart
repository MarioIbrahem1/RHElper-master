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

  static const int _selectedIndex = 4;

  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    // Load user data first, then fetch profile image
    _loadUserData().then((_) {
      if (mounted) {
        _fetchProfileImage();
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
      if (userEmail != null && userEmail.isNotEmpty) {
        email = userEmail;
        // Load profile data from API or local
        final profileData = await _profileService.getProfileData(userEmail);
        // Load profile image from profileData/profileImage
        if (mounted) {
          setState(() {
            _profileData = profileData;
            name = profileData.name;
            email = profileData.email;
            isLoading = false;
          });
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
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _fetchProfileImage() async {
    try {
      // Make sure we have a valid email before trying to fetch the image
      if (email.isEmpty) {
        print('Email is empty, trying to get it from SharedPreferences');
        final prefs = await SharedPreferences.getInstance();
        final userEmail = prefs.getString('logged_in_email');
        if (userEmail != null && userEmail.isNotEmpty) {
          email = userEmail;
          print('Retrieved email from SharedPreferences: $email');
        } else {
          print('Could not retrieve email from SharedPreferences');
          return; // Exit if we still don't have an email
        }
      }

      // Clear image cache before fetching to ensure we get the latest image
      imageCache.clear();
      imageCache.clearLiveImages();

      print('Fetching profile image for email: $email');

      // Get the image URL from the API using the updated method
      // This will try multiple approaches to get the image
      String imageUrl = await _profileService.getProfileImage(email);
      print('Fetched profile image URL: $imageUrl');

      // If we couldn't get a URL from the API, show a message
      if (imageUrl.isEmpty) {
        print('Empty image URL returned from API');

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
          print('Invalid image URL format: $imageUrl');
          // Try to fix the URL
          if (imageUrl.startsWith('/')) {
            imageUrl = 'http://81.10.91.96:8132$imageUrl';
          } else {
            imageUrl = 'http://81.10.91.96:8132/$imageUrl';
          }
          print('Fixed image URL: $imageUrl');
        }

        // Add cache-busting parameter if not already present
        if (!imageUrl.contains('?')) {
          imageUrl = '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}';
        } else if (!imageUrl.contains('t=')) {
          imageUrl = '$imageUrl&t=${DateTime.now().millisecondsSinceEpoch}';
        }

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
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image loaded successfully')),
        );
      }
    } catch (e) {
      print('Error in _fetchProfileImage: $e');
      // Show error in UI for debugging
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile image: $e')),
        );
      }
    }
  }

  bool _hasRetried = false; // Track if we've retried fetching the image

  void _logout(BuildContext context) async {
    try {
      // Desconectar de Google Sign In
      GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.disconnect();

      // Limpiar SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('logged_in_email');

      // Navegar a la pantalla de inicio de sesión
      if (mounted) {
        Navigator.pushReplacementNamed(context, SignInScreen.routeName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesión: $e')),
        );
      }
    }
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
        print('Selected image path: ${image.path}');
        print('Image file size: ${await imageFile.length()} bytes');

        // Check if email is available
        if (email.isEmpty) {
          final prefs = await SharedPreferences.getInstance();
          final userEmail = prefs.getString('logged_in_email');
          if (userEmail != null && userEmail.isNotEmpty) {
            email = userEmail;
            print('Retrieved email from SharedPreferences: $email');
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
        print('Uploaded image URL: $imageUrl');

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
            isLoading = false;
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile image updated successfully')),
          );

          // Force refresh of the profile image widget
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _fetchProfileImage();
            }
          });
        }
      }
    } catch (e) {
      print('Error in _pickAndUploadImage: $e');
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
