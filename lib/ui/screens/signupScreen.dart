import 'package:flutter/material.dart';
import 'package:road_helperr/ui/public_details/validation_form.dart';
import 'package:road_helperr/services/google_auth_service.dart';
import 'package:road_helperr/ui/screens/car_google.dart';
// الدارك/لايت الجديد

class SignupScreen extends StatefulWidget {
  static const String routeName = "signupscreen";
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

Future<Map<String, dynamic>?> signInWithGoogle(BuildContext context) async {
  try {
    // استخدام خدمة المصادقة المخصصة
    debugPrint('بدء عملية تسجيل الدخول باستخدام Google...');

    // إنشاء مثيل من خدمة المصادقة
    final GoogleAuthService authService = GoogleAuthService();

    // محاولة تسجيل الدخول باستخدام الطريقة البديلة
    final Map<String, dynamic>? userData =
        await authService.signInWithGoogleAlternative();

    // إذا تم إلغاء العملية
    if (userData == null) {
      debugPrint('تم إلغاء تسجيل الدخول بواسطة المستخدم');
      return null;
    }

    debugPrint('تم تسجيل الدخول بنجاح: ${userData['email']}');

    // التنقل إلى شاشة إعدادات السيارة لمستخدمي Google
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CarGoogleScreen(
            userData: userData,
          ),
        ),
      );
    }

    return userData;
  } catch (e) {
    // معالجة الأخطاء
    debugPrint('خطأ في تسجيل الدخول باستخدام Google: ${e.toString()}');

    if (context.mounted) {
      if (e.toString().contains('ApiException: 10')) {
        _showErrorDialog(
            context,
            'Configuration Error',
            'Google Sign-In is not properly configured in Firebase. Please check the following:\n\n'
                '1. Make sure SHA-1 certificate fingerprint is added to your Firebase project\n'
                '2. Make sure Google Sign-In is enabled in Firebase Authentication\n'
                '3. Download the latest google-services.json file and add it to your project\n\n'
                'Error details: ${e.toString()}');
      } else if (e.toString().contains('PigeonUserDetails')) {
        // محاولة استخدام المستخدم الحالي إذا كان متاحًا
        final authService = GoogleAuthService();
        if (authService.isUserSignedIn()) {
          final currentUser = authService.getCurrentUser();
          if (currentUser != null) {
            final userData = {
              'email': currentUser.email ?? '',
              'firstName': currentUser.displayName?.split(' ').first ?? '',
              'lastName': (currentUser.displayName?.split(' ').length ?? 0) > 1
                  ? currentUser.displayName?.split(' ').skip(1).join(' ') ?? ''
                  : '',
              'phone': currentUser.phoneNumber ?? '',
              'photoURL': currentUser.photoURL ?? '',
              'uid': currentUser.uid,
              'isGoogleSignIn': true,
            };

            // التنقل إلى شاشة إعدادات السيارة لمستخدمي Google
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CarGoogleScreen(
                  userData: userData,
                ),
              ),
            );

            return userData;
          }
        }

        _showErrorDialog(
            context,
            'Authentication Error',
            'There is a problem with data conversion. Please try again or contact support.\n\n'
                'Error details: ${e.toString()}');
      } else {
        _showErrorDialog(context, 'Sign-in Error',
            'An error occurred while signing in with Google: ${e.toString()}');
      }
    }

    return null;
  }
}

// Helper method to show error dialog
void _showErrorDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

class _SignupScreenState extends State<SignupScreen> {
  @override
  Widget build(BuildContext context) {
    // تقدر تستخدم ألوان الثيم الديناميك من AppColors مباشرة بدل شرط كل مرة
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor:
          isLight ? const Color(0xFF86A5D9) : const Color(0xFF1F3551),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.33,
              decoration: BoxDecoration(
                color:
                    isLight ? const Color(0xFF86A5D9) : const Color(0xFF1F3551),
                image: const DecorationImage(
                  image: AssetImage("assets/images/rafiki.png"),
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.33,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: isLight ? Colors.white : const Color(0xFF01122A),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: const SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: ValidationForm(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
