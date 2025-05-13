# نظام التحديث المخصص للتطبيق

هذا المستند يشرح كيفية استخدام نظام التحديث المخصص للتطبيق، والذي يسمح بتوزيع التحديثات للمستخدمين عبر Firebase Storage وإشعارات التطبيق.

## نظرة عامة

نظام التحديث المخصص يتكون من المكونات التالية:

1. **خدمة التحديث (UpdateService)**: تتعامل مع التحقق من وجود تحديثات وعرض مربعات حوار التحديث وتنزيل التحديثات.
2. **خدمة الإشعارات المحلية (LocalNotificationService)**: تتعامل مع إرسال إشعارات للمستخدمين عند توفر تحديثات جديدة.
3. **مساعد التحديث (UpdateHelper)**: يوفر واجهة مبسطة للتعامل مع التحديثات والإشعارات.
4. **خدمة تحديث المسؤول (AdminUpdateService)**: تستخدم من قبل المطور لرفع التحديثات وإدارتها.

## كيفية رفع تحديث جديد

### 1. رفع ملف APK إلى Firebase Storage

```dart
import 'dart:io';
import 'package:road_helperr/services/admin_update_service.dart';

Future<void> uploadNewUpdate() async {
  try {
    // إنشاء مثيل من خدمة تحديث المسؤول
    final AdminUpdateService adminService = AdminUpdateService();
    
    // رفع ملف APK إلى Firebase Storage
    final File apkFile = File('/path/to/your/app.apk');
    final String version = '1.0.1';
    final String downloadUrl = await adminService.uploadApkToStorage(apkFile, version);
    
    // إنشاء تحديث جديد
    await adminService.createNewUpdate(
      version: '1.0.1',
      versionCode: 2, // زيادة رقم الإصدار
      downloadUrl: downloadUrl,
      releaseNotes: 'تحسينات في الأداء وإصلاح بعض الأخطاء',
      forceUpdate: false, // اختياري: إجبار المستخدمين على التحديث
    );
    
    // إرسال إشعار للمستخدمين
    await adminService.sendUpdateNotification(
      title: 'تحديث جديد متاح',
      body: 'الإصدار 1.0.1 متاح الآن. انقر للتحديث.',
      downloadUrl: downloadUrl,
    );
    
    print('تم رفع التحديث بنجاح!');
  } catch (e) {
    print('خطأ في رفع التحديث: $e');
  }
}
```

## كيفية استلام التحديثات في التطبيق

### 1. تهيئة نظام التحديث

يتم تهيئة نظام التحديث في ملف `main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:road_helperr/utils/update_helper.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final UpdateHelper _updateHelper = UpdateHelper();

  @override
  void initState() {
    super.initState();
    _initializeUpdateHelper();
    
    // التحقق من التحديثات بعد تأخير قصير
    Future.delayed(const Duration(seconds: 2), () {
      _checkForUpdates();
    });
  }

  Future<void> _initializeUpdateHelper() async {
    await _updateHelper.initialize();
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
  
  // ...
}
```

### 2. التحقق من التحديثات يدويًا

يمكن للمستخدمين التحقق من التحديثات يدويًا من خلال زر في التطبيق:

```dart
ElevatedButton(
  onPressed: () async {
    await UpdateHelper().checkForUpdatesFromServer(context);
  },
  child: Text('التحقق من التحديثات'),
)
```

## آلية عمل النظام

1. **عند بدء التطبيق**:
   - يتم التحقق من وجود تحديثات محفوظة محليًا.
   - يتم التحقق من وجود تحديثات جديدة من الخادم.
   - إذا كان هناك تحديث جديد، يتم عرض مربع حوار للمستخدم.

2. **التحقق الدوري**:
   - يتم التحقق من وجود تحديثات جديدة كل 24 ساعة.
   - إذا كان هناك تحديث جديد، يتم إرسال إشعار للمستخدم.

3. **عند النقر على الإشعار**:
   - يتم فتح التطبيق وعرض مربع حوار التحديث.

4. **عند النقر على "تحديث الآن"**:
   - يتم تنزيل ملف APK وفتحه للتثبيت.

## ملاحظات هامة

1. تأكد من زيادة رقم الإصدار (versionCode) في كل مرة ترفع فيها تحديثًا جديدًا.
2. تأكد من أن لديك الأذونات المناسبة في ملف AndroidManifest.xml:
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
   <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
   ```
3. للتحديثات الإجبارية، اضبط `forceUpdate` على `true` عند إنشاء التحديث.
4. يمكنك تخصيص رسائل الإشعارات ومربعات الحوار حسب احتياجاتك.

## استكشاف الأخطاء وإصلاحها

إذا واجهت مشاكل في نظام التحديث، تحقق من الآتي:

1. تأكد من أن Firebase Storage مكون بشكل صحيح وأن لديك الأذونات المناسبة.
2. تأكد من أن رابط التنزيل صحيح ويمكن الوصول إليه.
3. تأكد من أن لديك الأذونات المناسبة في التطبيق.
4. تحقق من سجلات الأخطاء للحصول على مزيد من المعلومات.

## الخلاصة

باستخدام نظام التحديث المخصص، يمكنك توزيع التحديثات للمستخدمين بسهولة دون الحاجة إلى Google Play Store. يمكن للمستخدمين تلقي إشعارات بالتحديثات الجديدة وتنزيلها وتثبيتها بسهولة.
