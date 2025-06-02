import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:road_helperr/ui/screens/ai_welcome_screen.dart';
import 'package:road_helperr/ui/screens/bottomnavigationbar_screes/map_screen.dart';
import 'package:road_helperr/ui/screens/bottomnavigationbar_screes/profile_screen.dart';
import 'package:road_helperr/utils/app_colors.dart';
import 'package:road_helperr/utils/text_strings.dart';
import 'notification_screen.dart';
import 'package:road_helperr/services/notification_service.dart';
import 'package:road_helperr/services/places_service.dart';
import 'package:road_helperr/ui/widgets/profile_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const String routeName = "home";

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // static const int _selectedIndex = 0; // تم إزالته لأنه غير مستخدم
  int pressCount = 0;

  final Map<String, bool> serviceStates = {
    TextStrings.homeGas: false,
    TextStrings.homePolice: false,
    TextStrings.homeFire: false,
    TextStrings.homeHospital: false,
    TextStrings.homeMaintenance: false,
    TextStrings.homeWinch: false,
  };
  double? currentLatitude;
  double? currentLongitude;

  int selectedServicesCount = 0;
  String location = "Fetching location...";
  String userEmail = ""; // متغير لتخزين البريد الإلكتروني للمستخدم

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _getUserEmail(); // استدعاء دالة للحصول على البريد الإلكتروني للمستخدم
  }

  // دالة للحصول على البريد الإلكتروني للمستخدم من التخزين المحلي
  Future<void> _getUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('logged_in_email');
      if (email != null && email.isNotEmpty) {
        setState(() {
          userEmail = email;
        });
      }
    } catch (e) {
      // تجاهل الأخطاء
    }
  }

  void toggleFilter(String key, bool value) {
    setState(() {
      serviceStates[key] = value;
    });
    debugPrint("Filter changed: $key -> $value");
  }

  Future<void> getFilteredServices() async {
    // جمع الفلاتر المختارة من الخدمة
    List<String> selectedKeys = serviceStates.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    debugPrint("Selected filters: $selectedKeys");

    if (selectedKeys.isEmpty) {
      NotificationService.showValidationError(
        context,
        'Please select at least one service!',
      );
      return;
    }

    // استخدام الدالة الجديدة للحصول على نوع المكان والكلمات المفتاحية
    List<Map<String, dynamic>> selectedFilters = selectedKeys
        .map((key) => PlacesService.getPlaceTypeAndKeyword(key))
        .toList();

    debugPrint('🔍 Selected filters with keywords: $selectedFilters');

    // الحصول على الموقع الحالي الفعلي
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      // تحديث الموقع الحالي
      setState(() {
        currentLatitude = position.latitude;
        currentLongitude = position.longitude;
        debugPrint(
            '📍 Current location updated: $currentLatitude, $currentLongitude');
      });

      // تحديث عنوان الموقع (يمكن إضافة هذه الوظيفة لاحقًا إذا لزم الأمر)
    } catch (e) {
      debugPrint('❌ Error getting current location: $e');
      if (currentLatitude == null || currentLongitude == null) {
        if (mounted) {
          NotificationService.showValidationError(
            context,
            'Location not available. Please try again.',
          );
        }
        return;
      }
    }

    // زيادة نصف قطر البحث للحصول على نتائج أكثر
    const double searchRadius = 10000; // 10 كيلومتر بدلاً من 5

    Set<Marker> allMarkers = {};

    // معالجة كل نوع فلتر على حدة للحصول على نتائج أفضل
    for (var filter in selectedFilters) {
      final type = filter['type'] as String;
      final keyword = filter['keyword'] as String;

      debugPrint('🔍 Fetching places for type: $type, keyword: $keyword');

      try {
        // استخدام الميزات الجديدة في PlacesService
        final places = await PlacesService.searchNearbyPlaces(
          latitude: currentLatitude!,
          longitude: currentLongitude!,
          radius: searchRadius,
          types: [type],
          keyword: keyword,
          fetchAllPages: true, // الحصول على جميع الصفحات
        );

        debugPrint(
            '✅ Found ${places.length} places for type: $type, keyword: $keyword');

        // إضافة العلامات للنتائج
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

            allMarkers.add(
              Marker(
                markerId: MarkerId(placeId),
                position: LatLng(lat, lng),
                infoWindow: InfoWindow(
                  title: name,
                  snippet: vicinity,
                ),
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

    debugPrint('📊 Total markers: ${allMarkers.length}');

    // يمكن استخدام العلامات هنا إذا لزم الأمر
    // setState(() {
    //   // تحديث العلامات على الخريطة
    // });
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        currentLatitude = position.latitude;
        currentLongitude = position.longitude;
      });

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          location = "${place.locality}, ${place.country}";
        });
      }
    } catch (e) {
      setState(() {
        location = "Location not available";
      });
    }
  }

  void _showWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        var lang = AppLocalizations.of(context)!;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(lang.warning),
          content: Text(lang.pleaseSelectBetween1To3Services),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(lang.ok),
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToMap(BuildContext context) async {
    Map<String, bool> activeFilters = {};
    if (serviceStates[TextStrings.homeHospital] ?? false) {
      activeFilters['Hospital'] = true;
    }
    if (serviceStates[TextStrings.homePolice] ?? false) {
      activeFilters['Police'] = true;
    }
    if (serviceStates[TextStrings.homeMaintenance] ?? false) {
      activeFilters['Maintenance center'] = true;
    }
    if (serviceStates[TextStrings.homeWinch] ?? false) {
      activeFilters['Winch'] = true;
    }
    if (serviceStates[TextStrings.homeGas] ?? false) {
      activeFilters['Gas Station'] = true;
    }
    if (serviceStates[TextStrings.homeFire] ?? false) {
      activeFilters['Fire Station'] = true;
    }

    if (activeFilters.isEmpty) {
      final lang = AppLocalizations.of(context);
      NotificationService.showValidationError(
        context,
        lang?.pleaseSelectAtLeastOneService ??
            'Please select at least one service!',
      );
      return;
    }

    // التأكد من تحديث الموقع الحالي قبل الانتقال إلى الخريطة
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // تحديث الموقع الحالي
      setState(() {
        currentLatitude = position.latitude;
        currentLongitude = position.longitude;
      });

      if (mounted) {
        Navigator.pushNamed(
          this.context,
          MapScreen.routeName,
          arguments: {
            'filters': activeFilters,
            'latitude': currentLatitude,
            'longitude': currentLongitude,
          },
        );
      }
    } catch (e) {
      // في حالة فشل الحصول على الموقع الحالي
      if (currentLatitude != null && currentLongitude != null) {
        if (mounted) {
          // استخدام آخر موقع معروف إذا كان متاحًا
          Navigator.pushNamed(
            this.context,
            MapScreen.routeName,
            arguments: {
              'filters': activeFilters,
              'latitude': currentLatitude,
              'longitude': currentLongitude,
            },
          );
        }
      } else {
        if (mounted) {
          final lang = AppLocalizations.of(this.context);
          NotificationService.showValidationError(
            this.context,
            lang?.fetchingLocation ??
                'Location not available. Please try again.',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final size = MediaQuery.of(context).size;
              final isTablet = constraints.maxWidth > 600;
              final isDesktop = constraints.maxWidth > 1200;

              double titleSize = size.width *
                  (isDesktop
                      ? 0.03
                      : isTablet
                          ? 0.04
                          : 0.055);
              double iconSize = size.width *
                  (isDesktop
                      ? 0.03
                      : isTablet
                          ? 0.04
                          : 0.05);
              double padding = size.width *
                  (isDesktop
                      ? 0.02
                      : isTablet
                          ? 0.03
                          : 0.04);

              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.white
                      : null,
                  image: DecorationImage(
                    image: AssetImage(
                        Theme.of(context).brightness == Brightness.light
                            ? "assets/images/homeLight.png"
                            : "assets/images/home background.png"),
                    fit: Theme.of(context).brightness == Brightness.light
                        ? BoxFit.none
                        : BoxFit.cover,
                    alignment: Theme.of(context).brightness == Brightness.light
                        ? const Alignment(0.9, -0.9)
                        : Alignment.center,
                    scale: Theme.of(context).brightness == Brightness.light
                        ? 1.2
                        : 1.0,
                  ),
                ),
                child: _buildScaffold(
                    context, constraints, size, titleSize, iconSize, padding),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, BoxConstraints constraints,
      Size size, double titleSize, double iconSize, double padding) {
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return _buildCupertinoScaffold(
          context, constraints, size, titleSize, iconSize, padding);
    } else {
      return _buildMaterialScaffold(
          context, constraints, size, titleSize, iconSize, padding);
    }
  }

  Widget _buildMaterialScaffold(
      BuildContext context,
      BoxConstraints constraints,
      Size size,
      double titleSize,
      double iconSize,
      double padding) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.location_on_outlined,
            color: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFF0F4797)
                : Colors.white,
            size: iconSize * 1.2,
          ),
          onPressed: () {},
        ),
        title: Text(
          location,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFF0F4797)
                : Colors.white,
            fontSize: titleSize,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.all(padding),
            child: userEmail.isNotEmpty
                ? ProfileImageWidget(
                    email: userEmail,
                    size: titleSize * 2,
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.light
                            ? const Color(0xFF86A5D9)
                            : Colors.white,
                    iconColor: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF0F4797)
                        : Colors.white,
                    onTap: () {
                      Navigator.pushNamed(context, ProfileScreen.routeName);
                    },
                  )
                : CircleAvatar(
                    backgroundImage:
                        const AssetImage('assets/images/Ellipse 42.png'),
                    radius: titleSize,
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: _buildBody(
            context, constraints, size, titleSize, iconSize, padding),
      ),
      bottomNavigationBar: _buildBottomNavBar(context, iconSize),
    );
  }

  Widget _buildCupertinoScaffold(
      BuildContext context,
      BoxConstraints constraints,
      Size size,
      double titleSize,
      double iconSize,
      double padding) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.location,
            color: Colors.white,
            size: iconSize * 1.2,
          ),
          onPressed: () {},
        ),
        middle: Text(
          location,
          style: TextStyle(
            color: Colors.white,
            fontSize: titleSize,
            fontFamily: '.SF Pro Text',
          ),
        ),
        trailing: Padding(
          padding: EdgeInsets.all(padding),
          child: userEmail.isNotEmpty
              ? ProfileImageWidget(
                  email: userEmail,
                  size: titleSize * 2,
                  backgroundColor: Colors.white,
                  iconColor: Colors.white,
                  onTap: () {
                    Navigator.pushNamed(context, ProfileScreen.routeName);
                  },
                )
              : CircleAvatar(
                  backgroundImage:
                      const AssetImage('assets/images/Ellipse 42.png'),
                  radius: titleSize,
                ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildBody(
                  context, constraints, size, titleSize, iconSize, padding),
              _buildBottomNavBar(context, iconSize),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, BoxConstraints constraints, Size size,
      double titleSize, double iconSize, double padding) {
    final platform = Theme.of(context).platform;
    final isIOS =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    final lang = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang?.getYouBackOnTrack ?? TextStrings.homeGetYouBack,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFF0F4797)
                  : Colors.white,
              fontSize: titleSize * 1.2,
              fontWeight: FontWeight.bold,
              fontFamily: isIOS ? '.SF Pro Text' : null,
            ),
          ),
          SizedBox(height: size.height * 0.02),
          Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1F3551)
                  : const Color(0xFF86A5D9),
              borderRadius: BorderRadius.circular(isIOS ? 10 : 15),
            ),
            child: Column(
              children: [
                _buildServiceGrid(constraints, iconSize, titleSize, padding),
                SizedBox(height: size.height * 0.02),
                _buildGetServiceButton(context, size, titleSize),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceGrid(BoxConstraints constraints, double iconSize,
      double titleSize, double padding) {
    final isDesktop = constraints.maxWidth > 1200;
    final isTablet = constraints.maxWidth > 600;

    return GridView.count(
      crossAxisCount: isDesktop
          ? 4
          : isTablet
              ? 3
              : 2,
      mainAxisSpacing: padding,
      crossAxisSpacing: padding,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: serviceStates.entries.map((entry) {
        return ServiceCard(
          title: entry.key,
          iconPath: getServiceIconPath(entry.key),
          isSelected: entry.value,
          iconSize: iconSize,
          fontSize: titleSize * 0.8,
          onToggle: (value) {
            setState(() {
              if (value) {
                if (selectedServicesCount < 3) {
                  serviceStates[entry.key] = value;
                  selectedServicesCount++;
                } else {
                  _showWarningDialog(context);
                }
              } else {
                serviceStates[entry.key] = value;
                selectedServicesCount--;
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildGetServiceButton(
      BuildContext context, Size size, double titleSize) {
    final platform = Theme.of(context).platform;
    final isIOS =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    final lang = AppLocalizations.of(context);

    if (isIOS) {
      return SizedBox(
        width: double.infinity,
        height: size.height * 0.06,
        child: CupertinoButton(
          color: const Color(0xFF023A87),
          borderRadius: BorderRadius.circular(8),
          onPressed: () => _navigateToMap(context),
          child: Text(
            lang?.getYourServices ?? TextStrings.homeGetYourService,
            style: TextStyle(
              color: Colors.white,
              fontSize: titleSize,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: size.height * 0.06,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF023A87),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () => _navigateToMap(context),
        child: Text(
          lang?.getYourServices ?? TextStrings.homeGetYourService,
          style: TextStyle(
            color: Colors.white,
            fontSize: titleSize,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, double iconSize) {
    final platform = Theme.of(context).platform;
    final isIOS =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

    if (isIOS) {
      return CupertinoTabBar(
        backgroundColor: AppColors.getBackgroundColor(context),
        activeColor: Colors.white,
        inactiveColor: Colors.white.withOpacity(0.6),
        height: iconSize * 3,
        items: [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home, size: iconSize),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.location, size: iconSize),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chat_bubble, size: iconSize),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.bell, size: iconSize),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person, size: iconSize),
            label: 'Profile',
          ),
        ],
        onTap: (index) => _handleNavigation(context, index),
      );
    }

    return Container(
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
        index: 0,
        letIndexChange: (index) => true,
        items: const [
          Icon(Icons.home_outlined, size: 18, color: Colors.white),
          Icon(Icons.location_on_outlined, size: 18, color: Colors.white),
          Icon(Icons.textsms_outlined, size: 18, color: Colors.white),
          Icon(Icons.notifications_outlined, size: 18, color: Colors.white),
          Icon(Icons.person_2_outlined, size: 18, color: Colors.white),
        ],
        onTap: (index) => _handleNavigation(context, index),
      ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    final routes = [
      HomeScreen.routeName,
      MapScreen.routeName,
      AiWelcomeScreen.routeName,
      NotificationScreen.routeName,
      ProfileScreen.routeName,
    ];
    if (index < routes.length) {
      Navigator.pushNamed(context, routes[index]);
    }
  }

  String getServiceIconPath(String title) {
    switch (title) {
      case TextStrings.homeGas:
        return 'assets/home_icon/gas_station.png';
      case TextStrings.homePolice:
        return 'assets/home_icon/Police.png';
      case TextStrings.homeFire:
        return 'assets/home_icon/Fire_extinguisher.png';
      case TextStrings.homeHospital:
        return 'assets/home_icon/Hospital.png';
      case TextStrings.homeMaintenance:
        return 'assets/home_icon/Maintenance_center.png';
      case TextStrings.homeWinch:
        return 'assets/home_icon/Winch.png';
      default:
        return 'assets/home_icon/gas_station.png'; // fallback
    }
  }
}

class ServiceCard extends StatelessWidget {
  final String title;
  final String iconPath;
  final bool isSelected;
  final ValueChanged<bool> onToggle;
  final double iconSize;
  final double fontSize;

  const ServiceCard({
    super.key,
    required this.title,
    required this.iconPath,
    required this.isSelected,
    required this.onToggle,
    required this.iconSize,
    required this.fontSize,
  });

  String _getTranslatedTitle(BuildContext context, String title) {
    final lang = AppLocalizations.of(context);

    if (lang == null) return title;

    switch (title) {
      case TextStrings.homeGas:
        return lang.gasStation;
      case TextStrings.homePolice:
        return lang.policeDepartment;
      case TextStrings.homeFire:
        return lang.fireExtinguisher;
      case TextStrings.homeHospital:
        return lang.hospital;
      case TextStrings.homeMaintenance:
        return lang.maintenanceCenter;
      case TextStrings.homeWinch:
        return lang.winch;
      default:
        return title;
    }
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final isIOS =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

    // Get translated title
    final translatedTitle = _getTranslatedTitle(context, title);

    return LayoutBuilder(
      builder: (context, constraints) {
        double padding = constraints.maxWidth * 0.1;

        return Container(
          decoration: BoxDecoration(
            gradient: Theme.of(context).brightness == Brightness.dark &&
                    isSelected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF01122A),
                      Color(0xFF033E90),
                    ],
                  )
                : Theme.of(context).brightness == Brightness.light && isSelected
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF033E90),
                          Color(0xFF86A5D9),
                        ],
                      )
                    : null,
            color: Theme.of(context).brightness == Brightness.dark
                ? (isSelected ? null : const Color(0xFFB7BCC2))
                : (isSelected ? null : const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(isIOS ? 15 : 20),
          ),
          child: Stack(
            children: [
              Positioned(
                top: padding,
                right: padding,
                child: Transform.scale(
                  scale: constraints.maxWidth / 200,
                  child: isIOS
                      ? CupertinoSwitch(
                          value: isSelected,
                          onChanged: onToggle,
                          activeColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF033E90)
                                  : const Color(0xFF01122A),
                          trackColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF808080)
                                  : const Color(0xFF808080),
                        )
                      : Switch(
                          value: isSelected,
                          onChanged: onToggle,
                          activeColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.white,
                          activeTrackColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF033E90)
                                  : const Color(0xFF3575CE),
                          inactiveThumbColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.white,
                          inactiveTrackColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF808080)
                                  : const Color(0xFF808080),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          splashRadius: 0.0,
                        ),
                ),
              ),
              Center(
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        iconPath,
                        width: iconSize,
                        height: iconSize,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Error loading icon: $iconPath - $error');
                          return Container(
                            width: iconSize,
                            height: iconSize,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: iconSize * 0.6,
                            ),
                          );
                        },
                      ),
                      SizedBox(height: padding / 2),
                      Text(
                        translatedTitle,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.getTextStackColor(context),
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          fontFamily: isIOS ? '.SF Pro Text' : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
