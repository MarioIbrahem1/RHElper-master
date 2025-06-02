import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة مخصصة للتعامل مع مصادقة Google
class GoogleAuthService {
  // Singleton pattern
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Google Sign In instance with minimal configuration
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  /// تسجيل الدخول باستخدام Google - طريقة جديدة تتجاوز مشكلة PigeonUserDetails
  Future<Map<String, dynamic>?> signInWithGoogleAlternative() async {
    try {
      // تسجيل الخروج أولاً لتجنب مشاكل الجلسات السابقة
      try {
        await _googleSignIn.signOut();
        debugPrint('تم تسجيل الخروج من الجلسة السابقة');
      } catch (e) {
        debugPrint('لا توجد جلسة سابقة للخروج منها: ${e.toString()}');
      }

      // بدء عملية تسجيل الدخول
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // إذا ألغى المستخدم العملية
      if (googleUser == null) {
        debugPrint('تم إلغاء تسجيل الدخول بواسطة المستخدم');
        return null;
      }

      debugPrint('تم تسجيل الدخول بنجاح باستخدام Google: ${googleUser.email}');

      try {
        // الحصول على تفاصيل المصادقة
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // إنشاء بيانات اعتماد Firebase
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // تسجيل الدخول إلى Firebase
        try {
          final UserCredential userCredential =
              await _auth.signInWithCredential(credential);
          debugPrint(
              'تم تسجيل الدخول بنجاح في Firebase: ${userCredential.user?.email}');

          // استخراج بيانات المستخدم
          final userData = _extractUserData(userCredential);

          // حفظ بيانات المستخدم في التخزين المحلي
          await _saveUserDataLocally(userData);

          return userData;
        } catch (firebaseError) {
          debugPrint(
              'خطأ في تسجيل الدخول إلى Firebase: ${firebaseError.toString()}');

          // إذا كان الخطأ هو مشكلة PigeonUserDetails، نحاول الحصول على المستخدم الحالي
          if (firebaseError.toString().contains('PigeonUserDetails')) {
            // التحقق مما إذا كان المستخدم مسجل الدخول بالفعل
            final User? currentUser = _auth.currentUser;
            if (currentUser != null) {
              debugPrint('تم العثور على مستخدم حالي: ${currentUser.email}');

              // استخراج بيانات المستخدم من المستخدم الحالي
              final userData = _extractUserDataFromUser(currentUser);

              // حفظ بيانات المستخدم في التخزين المحلي
              await _saveUserDataLocally(userData);

              return userData;
            }
          }

          rethrow;
        }
      } catch (authError) {
        debugPrint(
            'خطأ في الحصول على تفاصيل المصادقة: ${authError.toString()}');
        rethrow;
      }
    } catch (e) {
      debugPrint('خطأ في تسجيل الدخول باستخدام Google: ${e.toString()}');
      rethrow;
    }
  }

  /// استخراج بيانات المستخدم من UserCredential
  Map<String, dynamic> _extractUserData(UserCredential userCredential) {
    final User? user = userCredential.user;
    return _extractUserDataFromUser(user);
  }

  /// استخراج بيانات المستخدم من User
  Map<String, dynamic> _extractUserDataFromUser(User? user) {
    if (user == null) {
      return {
        'email': '',
        'firstName': '',
        'lastName': '',
        'phone': '',
        'photoURL': '',
        'uid': '',
        'isGoogleSignIn': true,
      };
    }

    // استخراج اسم المستخدم وتقسيمه إلى اسم أول واسم أخير
    final String? displayName = user.displayName;
    final List<String> nameParts =
        displayName != null ? displayName.split(' ') : [''];

    // إنشاء خريطة بيانات التسجيل
    return {
      'email': user.email ?? '',
      'firstName': nameParts.isNotEmpty ? nameParts.first : '',
      'lastName': nameParts.length > 1 ? nameParts.skip(1).join(' ') : '',
      'phone': user.phoneNumber ?? '',
      'photoURL': user.photoURL ?? '',
      'uid': user.uid,
      'isGoogleSignIn': true,
    };
  }

  /// حفظ بيانات المستخدم في التخزين المحلي
  Future<void> _saveUserDataLocally(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('logged_in_email', userData['email'] ?? '');
      await prefs.setBool('is_google_sign_in', true);

      // يمكن حفظ المزيد من البيانات حسب الحاجة
      debugPrint('تم حفظ بيانات المستخدم في التخزين المحلي');
    } catch (e) {
      debugPrint('خطأ في حفظ بيانات المستخدم: ${e.toString()}');
    }
  }

  /// التحقق مما إذا كان المستخدم مسجل الدخول حاليًا
  bool isUserSignedIn() {
    return _auth.currentUser != null;
  }

  /// الحصول على المستخدم الحالي
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('خطأ في تسجيل الخروج من Google: ${e.toString()}');
    }

    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('خطأ في تسجيل الخروج من Firebase: ${e.toString()}');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('logged_in_email');
      await prefs.remove('is_google_sign_in');
    } catch (e) {
      debugPrint('خطأ في حذف بيانات المستخدم: ${e.toString()}');
    }
  }
}
