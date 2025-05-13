import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:road_helperr/models/profile_data.dart';
import 'package:road_helperr/services/profile_service.dart';

class GeminiChatMessage {
  final String text;
  final bool isUser;

  GeminiChatMessage({required this.text, required this.isUser});
}

class GeminiService {
  // متغيرات ثابتة لتخزين بيانات المستخدم
  static ProfileService profileService = ProfileService();
  static ProfileData? userProfile;

  // دالة لجلب بيانات المستخدم بناءً على البريد الإلكتروني
  static Future<void> fetchUserProfile(String email) async {
    try {
      userProfile = await profileService.getProfileData(email);
      debugPrint('User profile loaded: ${userProfile?.name}');
    } catch (e) {
      debugPrint('Error fetching profile data: $e');
    }
  }

  // قائمة بمفاتيح API المتعددة
  static const List<String> _apiKeys = [
    'AIzaSyCXFfiCkJL5VF3ABb3tIeJahAh2N0DoJgA', // المفتاح الأساسي
    'AIzaSyDNjuCNTRdwPMQZqIRtdk18QliFEUL3FGY', // مفتاح احتياطي 1
    'AIzaSyBppSCjheGWXIMQAHJo3rhISPCWHYG_wug', // مفتاح احتياطي 2
  ];

  // مؤشر للمفتاح الحالي المستخدم
  static int _currentKeyIndex = 0;

  // متغير لتخزين حالة تبديل المفتاح
  static bool _apiKeySwitched = false;

  // الحصول على مفتاح API الحالي
  static String get _currentApiKey => _apiKeys[_currentKeyIndex];

  // تهيئة Gemini بالمفتاح الحالي
  static void _initGemini() {
    Gemini.init(apiKey: _currentApiKey, enableDebugging: true);
  }

  // التبديل إلى المفتاح التالي
  static bool switchToNextApiKey() {
    if (_currentKeyIndex < _apiKeys.length - 1) {
      _currentKeyIndex++;
      _apiKeySwitched = true;
      debugPrint('Switched to API key ${_currentKeyIndex + 1}');
      _initGemini(); // تهيئة Gemini بالمفتاح الجديد
      return true;
    }
    return false; // لا توجد مفاتيح أخرى متاحة
  }

  // التحقق مما إذا تم تبديل المفتاح
  static bool get wasApiKeySwitched => _apiKeySwitched;

  // إعادة تعيين حالة تبديل المفتاح
  static void resetApiKeySwitchFlag() {
    _apiKeySwitched = false;
  }

  // For text-only queries with chat history
  static Future<String?> sendQuery({
    required List<Map<String, dynamic>> data,
    required String userQuery,
    required List<GeminiChatMessage> chatHistory,
    String? systemContext,
    String? responseFormat,
  }) async {
    // إعادة تعيين حالة تبديل المفتاح
    resetApiKeySwitchFlag();

    // تهيئة Gemini
    _initGemini();

    // بناء الاستعلام
    final prompt = _buildSystemPrompt(
      items: data,
      contextDescription: systemContext,
      responseInstructions: responseFormat,
    );

    // بناء سجل المحادثة
    final String conversationHistory = _buildConversationHistory(chatHistory);

    // إنشاء النص الكامل للاستعلام
    final String fullPrompt =
        "$prompt\n\nسجل المحادثة السابقة:\n$conversationHistory\n\nالسؤال الحالي: $userQuery";

    // محاولة إرسال الاستعلام باستخدام المفتاح الحالي
    String? result = await _trySendQuery(fullPrompt);

    // إذا فشلت المحاولة الأولى، حاول استخدام المفاتيح البديلة
    if (result == null || result.contains("حدث خطأ أثناء الاتصال بالخادم")) {
      // محاولة استخدام مفتاح بديل
      if (switchToNextApiKey()) {
        // إضافة رسالة اعتذار
        result = await _trySendQuery(fullPrompt);

        // إذا نجحت المحاولة الثانية، أضف رسالة اعتذار
        if (result != null && !result.contains("حدث خطأ")) {
          result = "عذراً على التأخير، كان هناك مشكلة فنية تم حلها.\n\n$result";
        }
      }
    }

    return result;
  }

  // دالة مساعدة لمحاولة إرسال الاستعلام
  static Future<String?> _trySendQuery(String fullPrompt) async {
    try {
      // استخدام طريقة prompt التي تعتبر أكثر موثوقية
      final gemini = Gemini.instance;
      final response = await gemini.prompt(
        parts: [Part.text(fullPrompt)],
      );

      if (response == null) {
        debugPrint('Empty response from Gemini API');
        return "عذراً، لم أستطع الحصول على إجابة من الخادم. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.";
      }

      final output = response.output;
      debugPrint('Gemini Response: $output');
      return output;
    } catch (e) {
      debugPrint('Gemini Error with key $_currentKeyIndex: ${e.toString()}');
      return "حدث خطأ أثناء الاتصال بالخادم: ${e.toString()}. يرجى المحاولة مرة أخرى.";
    }
  }

  // For image and text queries with chat history
  static Future<String?> sendImageQuery({
    required List<Map<String, dynamic>> data,
    required String userQuery,
    required File imageFile,
    required List<GeminiChatMessage> chatHistory,
    String? systemContext,
    String? responseFormat,
  }) async {
    // إعادة تعيين حالة تبديل المفتاح
    resetApiKeySwitchFlag();

    // تهيئة Gemini
    _initGemini();

    // بناء الاستعلام
    final prompt = _buildSystemPrompt(
      items: data,
      contextDescription: systemContext,
      responseInstructions: responseFormat,
    );

    // بناء سجل المحادثة
    final String conversationHistory = _buildConversationHistory(chatHistory);

    // إنشاء النص الكامل للاستعلام
    final String textPrompt =
        "$prompt\n\nسجل المحادثة السابقة:\n$conversationHistory\n\nالسؤال الحالي: $userQuery";

    // محاولة إرسال الاستعلام باستخدام المفتاح الحالي
    String? result = await _trySendImageQuery(textPrompt, imageFile);

    // إذا فشلت المحاولة الأولى، حاول استخدام المفاتيح البديلة
    if (result == null || result.contains("حدث خطأ")) {
      // محاولة استخدام مفتاح بديل
      if (switchToNextApiKey()) {
        // محاولة ثانية باستخدام المفتاح البديل
        result = await _trySendImageQuery(textPrompt, imageFile);

        // إذا نجحت المحاولة الثانية، أضف رسالة اعتذار
        if (result != null && !result.contains("حدث خطأ")) {
          result = "عذراً على التأخير، كان هناك مشكلة فنية تم حلها.\n\n$result";
        }
      }
    }

    return result;
  }

  // دالة مساعدة لمحاولة إرسال استعلام مع صورة
  static Future<String?> _trySendImageQuery(
      String textPrompt, File imageFile) async {
    try {
      final gemini = Gemini.instance;
      final imageBytes = imageFile.readAsBytesSync();

      // استخدام طريقة prompt مع Parts للتعامل مع النص والصورة
      final response = await gemini.prompt(
        parts: [
          Part.text(textPrompt),
          Part.bytes(imageBytes),
        ],
      );

      if (response == null) {
        debugPrint('Empty response from Gemini API for image query');
        return "عذراً، لم أستطع الحصول على إجابة من الخادم. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.";
      }

      final output = response.output;
      debugPrint('Gemini Image Response: $output');
      return output;
    } catch (e) {
      debugPrint(
          'Gemini Image Error with key $_currentKeyIndex: ${e.toString()}');
      return "حدث خطأ أثناء معالجة الصورة: ${e.toString()}. يرجى المحاولة مرة أخرى.";
    }
  }

  // Helper method to build conversation history string
  static String _buildConversationHistory(List<GeminiChatMessage> chatHistory) {
    final buffer = StringBuffer();

    for (final message in chatHistory) {
      final role = message.isUser ? 'المستخدم' : 'المساعد';
      buffer.write('$role: ${message.text}\n');
    }

    return buffer.toString();
  }

  static String _buildSystemPrompt({
    required List<Map<String, dynamic>> items,
    String? contextDescription,
    String? responseInstructions,
  }) {
    final buffer = StringBuffer();

    // الاحتفاظ بالسياق الأصلي
    buffer.write(contextDescription ?? 'Analyze this data:\n');

    // إضافة معلومات المستخدم إذا كانت متوفرة
    if (userProfile != null) {
      final userName = userProfile!.name;
      final userCarInfo = userProfile!.carModel != null
          ? 'نوع السيارة: ${userProfile!.carModel ?? "غير معروف"}, '
              'لون السيارة: ${userProfile!.carColor ?? "غير معروف"}, '
              'رقم اللوحة: ${userProfile!.plateNumber ?? "غير معروف"}'
          : '';

      if (userName.isNotEmpty) {
        buffer.write('\n\nمعلومات المستخدم:\n');
        buffer.write('اسم المستخدم: $userName\n');

        if (userCarInfo.isNotEmpty) {
          buffer.write('$userCarInfo\n');
          buffer.write(
              'استخدم هذه المعلومات لتخصيص إجاباتك وجعلها أكثر صلة بسيارة المستخدم عندما يكون ذلك مناسباً.\n');
          buffer.write(
              'خاطب المستخدم باسمه في بداية الرد، مثلاً: "مرحباً $userName، ..." أو "أهلاً $userName، ..."\n');
        }
      }
    }

    // إضافة معلومات عن التطبيق وصفحاته كإضافة وليس كاستبدال
    const appInfo = '''

بالإضافة إلى ذلك، أنت تعرف أنك جزء من تطبيق Road Helper وتستطيع توجيه المستخدمين إلى الصفحات المختلفة في التطبيق:

1. صفحة الرئيسية (Home Screen): تتيح للمستخدمين اختيار خدمات مثل محطات الوقود، المستشفيات، مراكز الصيانة، الونش، وغيرها. يمكن للمستخدمين النقر على "Get your services" للبحث عن الخدمات القريبة.

2. صفحة الخريطة (Map Screen): تعرض خريطة تفاعلية تسمح للمستخدمين بالبحث عن الأماكن القريبة، وطلب المساعدة من مستخدمين آخرين قريبين، ومشاركة الموقع.

3. صفحة الإشعارات (Notification Screen): تعرض طلبات المساعدة والإشعارات الأخرى التي تلقاها المستخدم.

4. صفحة الملف الشخصي (Profile Screen): تتيح للمستخدمين تعديل معلوماتهم الشخصية وتغيير إعدادات التطبيق.

عندما يسأل المستخدم عن خدمة متوفرة في التطبيق، قدم إجابة مفيدة ثم وجهه إلى الصفحة المناسبة في التطبيق باستخدام الصيغة التالية:
"[توجه إلى صفحة الرئيسية](#home)" أو "[توجه إلى صفحة الخريطة](#map)" أو "[توجه إلى صفحة الإشعارات](#notifications)" أو "[توجه إلى صفحة الملف الشخصي](#profile)"

مثال: إذا سأل المستخدم عن أقرب مستشفى، يمكنك الرد: "يمكنك العثور على أقرب مستشفى من خلال [التوجه إلى صفحة الرئيسية](#home) واختيار فلتر المستشفيات ثم النقر على زر Get your services."
''';

    // إضافة معلومات التطبيق بعد السياق الأصلي
    buffer.write('\n$appInfo\n');

    // إضافة البيانات
    for (final item in items) {
      item.forEach((key, value) {
        if (value is List) {
          for (int i = 0; i < value.length; i++) {
            buffer.write('• ${key.toUpperCase()}_${i + 1}: ${value[i]}\n');
          }
        } else {
          buffer.write('• ${key.toUpperCase()}: $value\n');
        }
      });
    }

    // الاحتفاظ بتعليمات الاستجابة الأصلية مع إضافة تعليمات جديدة
    if (responseInstructions != null) {
      buffer.write(responseInstructions);
    } else {
      buffer.write('\nRespond helpfully. ');
      buffer.write(
          'إذا كان سؤال المستخدم يتعلق بخدمة متوفرة في التطبيق، قدم إجابة مفيدة ثم وجهه إلى الصفحة المناسبة في التطبيق باستخدام الروابط المذكورة أعلاه. ');
      buffer.write('أجب بنفس لغة السؤال.');

      // إضافة تعليمات إضافية للتخصيص إذا كانت بيانات المستخدم متوفرة
      if (userProfile != null && userProfile!.name.isNotEmpty) {
        buffer.write(' خاطب المستخدم باسمه في بداية الرد.');

        if (userProfile!.carModel != null) {
          buffer.write(
              ' إذا كان السؤال يتعلق بالسيارات، استخدم معلومات سيارة المستخدم لتقديم إجابة أكثر تخصيصًا.');
        }
      }
    }

    return buffer.toString();
  }
}
