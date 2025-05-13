import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:road_helperr/services/notification_manager.dart';

class UpdateInfo {
  final String version;
  final int versionCode;
  final String downloadUrl;
  final String releaseNotes;
  final bool forceUpdate;

  UpdateInfo({
    required this.version,
    required this.versionCode,
    required this.downloadUrl,
    required this.releaseNotes,
    this.forceUpdate = false,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] ?? '',
      versionCode: json['versionCode'] ?? 0,
      downloadUrl: json['downloadUrl'] ?? '',
      releaseNotes: json['releaseNotes'] ?? '',
      forceUpdate: json['forceUpdate'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'versionCode': versionCode,
      'downloadUrl': downloadUrl,
      'releaseNotes': releaseNotes,
      'forceUpdate': forceUpdate,
    };
  }
}

class UpdateService {
  // Singleton instance
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;

  UpdateService._internal();

  // حفظ معلومات التحديث في التخزين المحلي
  Future<void> saveUpdateInfo(UpdateInfo updateInfo) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('update_version', updateInfo.version);
      await prefs.setInt('update_version_code', updateInfo.versionCode);
      await prefs.setString('update_download_url', updateInfo.downloadUrl);
      await prefs.setString('update_release_notes', updateInfo.releaseNotes);
      await prefs.setBool('update_force_update', updateInfo.forceUpdate);
      await prefs.setBool('update_available', true);
    } catch (e) {
      debugPrint('خطأ في حفظ معلومات التحديث: $e');
    }
  }

  // الحصول على معلومات التحديث من التخزين المحلي
  Future<UpdateInfo?> getUpdateInfo() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool updateAvailable = prefs.getBool('update_available') ?? false;

      if (!updateAvailable) {
        return null;
      }

      return UpdateInfo(
        version: prefs.getString('update_version') ?? '',
        versionCode: prefs.getInt('update_version_code') ?? 0,
        downloadUrl: prefs.getString('update_download_url') ?? '',
        releaseNotes: prefs.getString('update_release_notes') ?? '',
        forceUpdate: prefs.getBool('update_force_update') ?? false,
      );
    } catch (e) {
      debugPrint('خطأ في الحصول على معلومات التحديث: $e');
      return null;
    }
  }

  // التحقق من وجود تحديثات وعرض مربع حوار للمستخدم
  Future<void> checkForUpdatesWithDialog(BuildContext context) async {
    try {
      final UpdateInfo? updateInfo = await getUpdateInfo();

      if (updateInfo != null) {
        // إضافة إشعار التحديث
        await NotificationManager().addUpdateNotification(
          version: updateInfo.version,
          downloadUrl: updateInfo.downloadUrl,
          releaseNotes: updateInfo.releaseNotes,
        );

        if (context.mounted) {
          // عرض مربع حوار للمستخدم
          showUpdateDialog(context, updateInfo);
        }
      }
    } catch (e) {
      debugPrint('خطأ في التحقق من التحديثات: $e');
    }
  }

  // عرض مربع حوار التحديث
  void showUpdateDialog(BuildContext context, UpdateInfo updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: !updateInfo.forceUpdate,
      builder: (context) => AlertDialog(
        title: const Text('تحديث جديد متاح'),
        content:
            Text('هناك إصدار جديد من التطبيق متاح (${updateInfo.version}).\n\n'
                '${updateInfo.releaseNotes}\n\n'
                'هل ترغب في التحديث الآن؟'),
        actions: [
          if (!updateInfo.forceUpdate)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('لاحقاً'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showDownloadDialog(context, updateInfo);
            },
            child: const Text('تحديث الآن'),
          ),
        ],
      ),
    );
  }

  // عرض مربع حوار التنزيل - طريقة مبسطة
  void _showDownloadDialog(BuildContext context, UpdateInfo updateInfo) {
    double progress = 0;
    bool isDownloading = true;
    String statusText = 'جاري تنزيل التحديث...';

    // إنشاء مرجع للدالة setState
    void Function(void Function())? setStateRef;

    // دالة لتحديث حالة مربع الحوار
    void updateDialogState(double newProgress,
        {String? newStatus, bool? newIsDownloading}) {
      if (setStateRef != null) {
        setStateRef!(() {
          if (newStatus != null) statusText = newStatus;
          progress = newProgress;
          if (newIsDownloading != null) isDownloading = newIsDownloading;
        });
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          // حفظ مرجع للدالة setState
          setStateRef = setState;

          return AlertDialog(
            title: const Text('تنزيل التحديث'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(statusText),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: progress),
                Text('${(progress * 100).toStringAsFixed(0)}%'),
                const SizedBox(height: 16),
                if (!isDownloading && progress >= 1.0)
                  const Text(
                    'تم فتح المتصفح لتنزيل التحديث. يرجى تثبيت الملف بعد اكتمال التنزيل.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.green),
                  ),
                if (!isDownloading && progress < 1.0)
                  Column(
                    children: [
                      const Text(
                        'إذا لم يتم فتح المتصفح تلقائيًا، يرجى النقر على الزر أدناه.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.orange),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final Uri uri = Uri.parse(updateInfo.downloadUrl);
                          // محاولة فتح المتصفح بطرق مختلفة
                          bool launched = await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );

                          if (!launched) {
                            if (context.mounted) {
                              launched = await launchUrl(
                                uri,
                                mode: LaunchMode.platformDefault,
                              );
                            }
                          }

                          if (launched && context.mounted) {
                            setState(() {
                              statusText = 'تم فتح المتصفح بنجاح';
                              progress = 1.0;
                              isDownloading = false;
                            });
                          }
                        },
                        child: const Text('تنزيل التحديث'),
                      ),
                    ],
                  ),
              ],
            ),
            actions: [
              if (!isDownloading)
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('إغلاق'),
                ),
              if (isDownloading)
                TextButton(
                  onPressed: () {
                    setState(() {
                      isDownloading = false;
                      statusText = 'تم إلغاء التنزيل';
                      progress = 0;
                    });
                  },
                  child: const Text('إلغاء'),
                ),
            ],
          );
        },
      ),
    );

    // بدء تنزيل التحديث بطريقة مبسطة
    downloadUpdate(
      updateInfo,
      (newProgress) {
        // تحديث شريط التقدم
        if (context.mounted) {
          updateDialogState(
            newProgress,
            newStatus:
                newProgress >= 1.0 ? 'اكتمل التنزيل. جاري فتح المثبت...' : null,
            newIsDownloading: newProgress >= 1.0 ? false : null,
          );
        }
      },
      onError: (error) {
        if (context.mounted) {
          updateDialogState(
            0.0,
            newStatus: 'حدث خطأ: $error',
            newIsDownloading: false,
          );
        }
      },
    );
  }

  // تنزيل التحديث - طريقة مبسطة
  Future<void> downloadUpdate(
    UpdateInfo updateInfo,
    Function(double) onProgress, {
    Function(String)? onError,
  }) async {
    try {
      debugPrint('بدء تنزيل التحديث من: ${updateInfo.downloadUrl}');

      // إظهار تقدم وهمي للتنزيل (لأننا نستخدم المتصفح)
      for (int i = 0; i <= 20; i++) {
        await Future.delayed(const Duration(milliseconds: 50));
        onProgress(i / 20);
      }

      // فتح المتصفح مباشرة لتنزيل التحديث
      final Uri uri = Uri.parse(updateInfo.downloadUrl);
      debugPrint('فتح المتصفح لتنزيل التحديث: $uri');

      // استخدام LaunchMode.externalNonBrowserApplication لفتح متجر التطبيقات أو مدير التنزيلات
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // محاولة ثانية باستخدام وضع مختلف
        launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      }

      if (!launched) {
        const error = 'فشل في فتح رابط التحديث';
        debugPrint(error);
        if (onError != null) onError(error);
      } else {
        debugPrint('تم فتح المتصفح بنجاح');
        onProgress(1.0);
      }
    } catch (e) {
      debugPrint('خطأ في تنزيل التحديث: $e');
      if (onError != null) onError(e.toString());
    }
  }

  // مسح معلومات التحديث
  Future<void> clearUpdateInfo() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('update_available', false);
    } catch (e) {
      debugPrint('خطأ في مسح معلومات التحديث: $e');
    }
  }
}
