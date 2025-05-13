# دليل توزيع التطبيق باستخدام Firebase App Distribution

هذا الدليل يشرح كيفية توزيع تطبيق Road Helper باستخدام Firebase App Distribution، مما يسمح للمستخدمين بتلقي التحديثات دون الحاجة إلى إعادة تثبيت التطبيق.

## المتطلبات الأساسية

1. **Node.js**: قم بتثبيته من [nodejs.org](https://nodejs.org/)
2. **Firebase CLI**: قم بتثبيته باستخدام npm:
   ```
   npm install -g firebase-tools
   ```

## خطوات الإعداد

### 1. تسجيل الدخول إلى Firebase

```
firebase login
```

### 2. بناء التطبيق

قم ببناء نسخة release من التطبيق:

```
flutter clean
flutter pub get
flutter build apk --release
```

### 3. توزيع التطبيق

استخدم السكريبت المرفق لتوزيع التطبيق:

```
distribute.bat
```

أو قم بالتوزيع يدويًا:

```
cd android
gradlew.bat appDistributionUploadRelease
```

## إعداد Firebase App Distribution في لوحة تحكم Firebase

1. انتقل إلى [لوحة تحكم Firebase](https://console.firebase.google.com/)
2. اختر مشروعك: "road-helper-fed8f"
3. في القائمة الجانبية اليسرى، انقر على "App Distribution"
4. انقر على "Get started" إذا كانت هذه هي المرة الأولى التي تستخدم فيها App Distribution
5. قم بإنشاء مجموعة توزيع جديدة باسم "testers"
6. أضف المختبرين عن طريق عناوين البريد الإلكتروني

## اختبار التحديثات التلقائية

التطبيق الآن يتضمن وظيفة التحديث التلقائي التي ستقوم بما يلي:

1. التحقق من وجود تحديثات عند بدء تشغيل التطبيق
2. عرض مربع حوار للمستخدم عند توفر التحديثات
3. السماح للمستخدم بتنزيل وتثبيت التحديثات دون الحاجة إلى إعادة تثبيت التطبيق

## استكشاف الأخطاء وإصلاحها

### المشكلات الشائعة:

1. **عدم العثور على Firebase CLI**: تأكد من تثبيت Node.js و Firebase CLI بشكل صحيح.

2. **مشكلات المصادقة**: قم بتنفيذ `firebase logout` ثم `firebase login` مرة أخرى.

3. **فشل البناء**: تأكد من أن التطبيق يبنى بشكل صحيح باستخدام `flutter build apk --release`.

4. **فشل التوزيع**: تحقق من أن معرف التطبيق صحيح في أمر التوزيع.

5. **عدم ظهور التحديثات**: تأكد من زيادة رقم الإصدار في `pubspec.yaml`.

## تحديث أرقام الإصدار

لإصدار نسخة جديدة، قم بتحديث الإصدار في `pubspec.yaml`:

```yaml
version: 1.0.0+1 # قم بتغييره إلى 1.0.1+2 على سبيل المثال
```

الصيغة هي `versionName+versionCode` حيث:

- `versionName` هو الإصدار المرئي للمستخدم (مثل 1.0.1)
- `versionCode` هو رقم صحيح يجب أن يزداد مع كل تحديث (مثل 2)

## إضافة مختبرين

1. انتقل إلى [لوحة تحكم Firebase](https://console.firebase.google.com/)
2. اختر مشروعك
3. انتقل إلى "App Distribution" في القائمة الجانبية
4. انقر على "Testers & Groups"
5. أضف عناوين البريد الإلكتروني للمختبرين

عندما تقوم بتوزيع إصدار جديد، سيتلقى المختبرون بريدًا إلكترونيًا يحتوي على رابط لتنزيل التطبيق.

## موارد إضافية

- [توثيق Firebase App Distribution](https://firebase.google.com/docs/app-distribution)
- [توثيق التحديث داخل التطبيق](https://pub.dev/packages/in_app_update)
