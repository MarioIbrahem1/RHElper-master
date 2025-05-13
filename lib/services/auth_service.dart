import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة إدارة المصادقة والجلسة
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // مفاتيح SharedPreferences
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _isLoggedInKey = 'is_logged_in';

  /// حفظ بيانات المصادقة بعد تسجيل الدخول
  Future<void> saveAuthData({
    required String token,
    required String userId,
    required String email,
    String? name,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // حفظ بيانات المصادقة
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userIdKey, userId);
      await prefs.setString(_userEmailKey, email);
      if (name != null) {
        await prefs.setString(_userNameKey, name);
      }

      // تعيين حالة تسجيل الدخول
      await prefs.setBool(_isLoggedInKey, true);

      debugPrint('تم حفظ بيانات المصادقة بنجاح');
    } catch (e) {
      debugPrint('خطأ في حفظ بيانات المصادقة: $e');
    }
  }

  /// التحقق مما إذا كان المستخدم مسجل الدخول
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      final token = prefs.getString(_tokenKey);

      debugPrint('=== حالة تسجيل الدخول ===');
      debugPrint('isLoggedIn flag: $isLoggedIn');
      debugPrint('token exists: ${token != null}');
      if (token != null) {
        debugPrint('token is not empty: ${token.isNotEmpty}');
        if (token.isNotEmpty) {
          debugPrint(
              'token value: ${token.substring(0, min(10, token.length))}...');
        }
      }
      debugPrint('========================');

      // التحقق من وجود رمز المصادقة وحالة تسجيل الدخول
      return isLoggedIn && token != null && token.isNotEmpty;
    } catch (e) {
      debugPrint('خطأ في التحقق من حالة تسجيل الدخول: $e');
      return false;
    }
  }

  /// الحصول على رمز المصادقة
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      debugPrint('خطأ في الحصول على رمز المصادقة: $e');
      return null;
    }
  }

  /// الحصول على معرف المستخدم
  Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdKey);
    } catch (e) {
      debugPrint('خطأ في الحصول على معرف المستخدم: $e');
      return null;
    }
  }

  /// الحصول على بريد المستخدم الإلكتروني
  Future<String?> getUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userEmailKey);
    } catch (e) {
      debugPrint('خطأ في الحصول على بريد المستخدم: $e');
      return null;
    }
  }

  /// الحصول على اسم المستخدم
  Future<String?> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userNameKey);
    } catch (e) {
      debugPrint('خطأ في الحصول على اسم المستخدم: $e');
      return null;
    }
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // حذف بيانات المصادقة
      await prefs.remove(_tokenKey);
      await prefs.remove(_userIdKey);
      await prefs.setBool(_isLoggedInKey, false);

      debugPrint('تم تسجيل الخروج بنجاح');
    } catch (e) {
      debugPrint('خطأ في تسجيل الخروج: $e');
    }
  }
}
