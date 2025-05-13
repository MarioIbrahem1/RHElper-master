import 'package:flutter/material.dart';
import 'package:road_helperr/ui/public_details/validation_form.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:road_helperr/ui/screens/OTPscreen.dart';
// الدارك/لايت الجديد

class SignupScreen extends StatefulWidget {
  static const String routeName = "signupscreen";
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}
Future<Map<String, dynamic>?> signInWithGoogle(BuildContext context) async {
  try {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      // User cancelled the sign-in flow
      return null;
    }

    try {
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      // Create registration data map with all required fields
      final String? displayName = userCredential.user?.displayName;
      final List<String> nameParts = displayName?.split(' ') ?? [''];

      final Map<String, dynamic> registrationData = {
        'email': userCredential.user?.email ?? '',
        'firstName': nameParts.isNotEmpty ? nameParts.first : '',
        'lastName': nameParts.length > 1 ? nameParts.skip(1).join(' ') : '',
        'phone': userCredential.user?.phoneNumber ?? '',
        'photoURL': userCredential.user?.photoURL ?? '',
        'uid': userCredential.user?.uid ?? '',
        'isGoogleSignIn': true,
      };

      // Check if the context is still valid before navigating
      if (context.mounted) {
        // Navigate to OTP screen directly with registration data
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Otp(
              email: registrationData['email'] ?? '',
              registrationData: registrationData,
            ),
          ),
        );
      }

      return registrationData;
    } catch (e) {
      // Handle authentication errors
      if (context.mounted) {
        _showErrorDialog(context, 'Authentication Error',
          'Error authenticating with Google: ${e.toString()}');
      }
      return null;
    }
  } catch (e) {
    // Handle Google Sign-In errors
    if (context.mounted) {
      if (e.toString().contains('ApiException: 10')) {
        _showErrorDialog(context, 'Configuration Error',
          'Google Sign-In is not properly configured in Firebase. Please check the following:\n\n'
          '1. Make sure SHA-1 certificate fingerprint is added to Firebase project\n'
          '2. Make sure Google Sign-In is enabled in Firebase Authentication\n'
          '3. Download the latest google-services.json file and add it to your project');
      } else {
        _showErrorDialog(context, 'Sign-In Error',
          'Error signing in with Google: ${e.toString()}');
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
      backgroundColor: isLight
          ? const Color(0xFF86A5D9)
          : const Color(0xFF1F3551),
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
                color: isLight
                    ? const Color(0xFF86A5D9)
                    : const Color(0xFF1F3551),
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
                color: isLight
                    ? Colors.white
                    : const Color(0xFF01122A),
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
