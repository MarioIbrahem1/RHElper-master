import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:road_helperr/services/update_service.dart';
import 'package:road_helperr/services/local_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مساعد للتعامل مع تحديثات التطبيق
class UpdateHelper {
  // Singleton instance
  static final UpdateHelper _instance = UpdateHelper._internal();
  factory UpdateHelper() => _instance;

  final UpdateService _updateService = UpdateService();
  final LocalNotificationService _notificationService =
      LocalNotificationService();

  UpdateHelper._internal();

  /// تهيئة خدمات التحديث
  Future<void> initialize() async {
    await _notificationService.init();
  }

  /// الحصول على إصدار التطبيق الحالي
  Future<(String version, int versionCode)> _getCurrentAppVersion() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String version = packageInfo.version;

      // استخراج رقم الإصدار من سلسلة الإصدار (مثال: 1.0.0+1 -> 1)
      final String buildNumber = packageInfo.buildNumber;
      final int versionCode = int.tryParse(buildNumber) ?? 1;

      debugPrint('=== إصدار التطبيق الحالي ===');
      debugPrint('الإصدار: $version');
      debugPrint('رقم الإصدار: $versionCode');
      debugPrint('===========================');

      return (version, versionCode);
    } catch (e) {
      debugPrint('خطأ في الحصول على إصدار التطبيق: $e');
      return ('1.0.0', 1); // القيمة الافتراضية
    }
  }

  /// التحقق من وجود تحديثات من الخادم
  Future<void> checkForUpdatesFromServer(BuildContext context) async {
    try {
      // الحصول على إصدار التطبيق الحالي
      final (_, currentVersionCode) = await _getCurrentAppVersion();

      // رابط ملف JSON للتحديثات (يمكن تغييره حسب الحاجة)
      const String updateJsonUrl =
          'https://firebasestorage.googleapis.com/v0/b/road-helper-fed8f.firebasestorage.app/o/version.json?alt=media&token=c94e6602-2e9e-4d6f-8b42-c0f9e3a39ea6';

      // الحصول على معلومات التحديث من الخادم
      final response = await http.get(Uri.parse(updateJsonUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes));

        // إنشاء كائن UpdateInfo من البيانات
        final UpdateInfo updateInfo = UpdateInfo(
          version: data['version'],
          versionCode: data['versionCode'],
          downloadUrl: data['downloadUrl'],
          releaseNotes: data['releaseNotes'],
          forceUpdate: data['forceUpdate'] ?? false,
        );

        debugPrint('=== معلومات التحديث من الخادم ===');
        debugPrint('الإصدار: ${updateInfo.version}');
        debugPrint('رقم الإصدار: ${updateInfo.versionCode}');
        debugPrint('================================');

        // التحقق مما إذا كان هناك تحديث جديد
        final bool hasUpdate = updateInfo.versionCode > currentVersionCode;

        debugPrint('هل يوجد تحديث جديد؟ $hasUpdate');

        if (hasUpdate) {
          // حفظ معلومات التحديث في التخزين المحلي فقط إذا كان هناك تحديث جديد
          await _updateService.saveUpdateInfo(updateInfo);

          // عرض مربع حوار التحديث إذا كان التطبيق في المقدمة
          if (context.mounted) {
            await _updateService.checkForUpdatesWithDialog(context);
          }

          // إرسال إشعار بالتحديث
          await _notificationService.checkForUpdateAndNotify();
        } else {
          // مسح معلومات التحديث إذا لم يكن هناك تحديث جديد
          await _updateService.clearUpdateInfo();
          debugPrint('لا يوجد تحديث جديد، تم مسح معلومات التحديث السابقة');
        }
      }
    } catch (e) {
      debugPrint('خطأ في التحقق من التحديثات من الخادم: $e');
    }
  }

  /// التحقق من وجود تحديثات عند بدء التطبيق
  Future<void> checkForUpdatesOnStartup(BuildContext context) async {
    try {
      // التحقق من وجود تحديثات محفوظة محليًا
      if (context.mounted) {
        await _updateService.checkForUpdatesWithDialog(context);
      }

      // التحقق من وجود تحديثات جديدة من الخادم
      if (context.mounted) {
        await checkForUpdatesFromServer(context);
      }
    } catch (e) {
      debugPrint('خطأ في التحقق من التحديثات عند بدء التطبيق: $e');
    }
  }

  /// التحقق من وجود تحديثات بشكل دوري
  Future<void> setupPeriodicUpdateCheck(BuildContext context) async {
    try {
      // الحصول على وقت آخر تحقق من التحديثات
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int lastCheckTime = prefs.getInt('last_update_check_time') ?? 0;
      final int currentTime = DateTime.now().millisecondsSinceEpoch;

      // التحقق من التحديثات إذا مر أكثر من 24 ساعة منذ آخر تحقق
      if (currentTime - lastCheckTime > 24 * 60 * 60 * 1000) {
        if (context.mounted) {
          await checkForUpdatesFromServer(context);
        }

        // تحديث وقت آخر تحقق
        await prefs.setInt('last_update_check_time', currentTime);
      }
    } catch (e) {
      debugPrint('خطأ في إعداد التحقق الدوري من التحديثات: $e');
    }
  }
}
