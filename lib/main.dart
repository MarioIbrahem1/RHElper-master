import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:road_helperr/providers/settings_provider.dart';
import 'package:road_helperr/providers/signup_provider.dart';
import 'package:road_helperr/services/auth_service.dart';
import 'package:road_helperr/ui/screens/about_screen.dart';
import 'package:road_helperr/ui/screens/ai_chat.dart';
import 'package:road_helperr/ui/screens/ai_welcome_screen.dart';
import 'package:road_helperr/ui/screens/bottomnavigationbar_screes/home_screen.dart';
import 'package:road_helperr/ui/screens/bottomnavigationbar_screes/map_screen.dart';
import 'package:road_helperr/ui/screens/bottomnavigationbar_screes/notification_screen.dart';
import 'package:road_helperr/ui/screens/bottomnavigationbar_screes/profile_screen.dart'
    as profile;
import 'package:road_helperr/ui/screens/edit_profile_screen.dart';
import 'package:road_helperr/ui/screens/email_screen.dart';
import 'package:road_helperr/ui/screens/on_boarding.dart';
import 'package:road_helperr/ui/screens/onboarding.dart';
import 'package:road_helperr/ui/screens/otp_expired_screen.dart';
import 'package:road_helperr/ui/screens/otp_screen.dart';
import 'package:road_helperr/ui/screens/signin_screen.dart';
import 'package:road_helperr/ui/screens/signupScreen.dart';
import 'package:road_helperr/ui/screens/emergency_contacts.dart';
import 'package:road_helperr/models/profile_data.dart';
import 'package:road_helperr/utils/theme_provider.dart';
import 'utils/location_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:road_helperr/utils/update_helper.dart';
import 'package:road_helperr/services/firebase_notification_new.dart';

// Global navigator key for accessing the navigator from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // التحقق من حالة تسجيل الدخول قبل بدء التطبيق
  final authService = AuthService();
  final isLoggedIn = await authService.isLoggedIn();

  debugPrint('=== حالة تسجيل الدخول عند بدء التطبيق ===');
  debugPrint('المستخدم مسجل الدخول: $isLoggedIn');
  debugPrint('=========================================');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SignupProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MyApp(isUserLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool isUserLoggedIn;

  const MyApp({super.key, required this.isUserLoggedIn});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final LocationService _locationService = LocationService();
  final UpdateHelper _updateHelper = UpdateHelper();
  final FirebaseNotification _firebaseNotification = FirebaseNotification();

  // المسار الأولي للتطبيق
  late String _initialRoute;

  @override
  void initState() {
    super.initState();
    // تعيين المسار الأولي بناءً على حالة تسجيل الدخول
    _initialRoute = widget.isUserLoggedIn
        ? HomeScreen.routeName
        : OnboardingScreen.routeName;

    debugPrint('=== المسار الأولي للتطبيق ===');
    debugPrint('المستخدم مسجل الدخول: ${widget.isUserLoggedIn}');
    debugPrint('المسار الأولي: $_initialRoute');
    debugPrint('============================');

    _checkLocation();
    _initializeUpdateHelper();
    _initializeFirebaseNotifications();

    // Delay update check to ensure the app is fully loaded
    Future.delayed(const Duration(seconds: 2), () {
      _checkForUpdates();
    });
  }

  Future<void> _initializeFirebaseNotifications() async {
    await _firebaseNotification.initNotification();
  }

  Future<void> _initializeUpdateHelper() async {
    await _updateHelper.initialize();
  }

  Future<void> _checkLocation() async {
    await _locationService.checkLocationPermission();
    bool isLocationEnabled = await _locationService.isLocationServiceEnabled();
    if (!isLocationEnabled) {
      _showLocationDisabledMessage();
    }
  }

  Future<void> _checkForUpdates() async {
    if (mounted) {
      await _updateHelper.checkForUpdatesOnStartup(context);

      // إعداد التحقق الدوري من التحديثات
      if (mounted) {
        await _updateHelper.setupPeriodicUpdateCheck(context);
      }
    }
  }

  void _showLocationDisabledMessage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Required'),
        content: const Text('Please enable location services to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      navigatorKey: navigatorKey, // إضافة مفتاح التنقل للإشعارات
      debugShowCheckedModeBanner: false,
      title: 'Road Helper App',
      theme: ThemeProvider.lightTheme,
      darkTheme: ThemeProvider.darkTheme,
      themeMode: themeProvider.themeMode,

      // Localization setup
      locale: Locale(settingsProvider.currentLocale),
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: AppLocalizations.localizationsDelegates,

      routes: {
        AboutScreen.routeName: (context) => const AboutScreen(),
        SignupScreen.routeName: (context) => const SignupScreen(),
        SignInScreen.routeName: (context) => const SignInScreen(),
        AiWelcomeScreen.routeName: (context) => const AiWelcomeScreen(),
        AiChat.routeName: (context) => const AiChat(),
        HomeScreen.routeName: (context) => const HomeScreen(),
        MapScreen.routeName: (context) => const MapScreen(),
        NotificationScreen.routeName: (context) => const NotificationScreen(),
        profile.ProfileScreen.routeName: (context) =>
            const profile.ProfileScreen(),
        OtpScreen.routeName: (context) => const OtpScreen(),
        OnBoarding.routeName: (context) => const OnBoarding(),
        OnboardingScreen.routeName: (context) => const OnboardingScreen(),
        OtpExpiredScreen.routeName: (context) => const OtpExpiredScreen(),
        // 'carGoogle': (context) => const CarGoogleScreen(
        //   registrationData: {},
        // ),

        EditProfileScreen.routeName: (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return EditProfileScreen(
            email: args['email'] as String,
            initialData: args['initialData'] as ProfileData?,
          );
        },
        EmailScreen.routeName: (context) => const EmailScreen(),
        EmergencyContactsScreen.routeName: (context) =>
            const EmergencyContactsScreen(),
      },
      initialRoute: _initialRoute,
    );
  }
}
