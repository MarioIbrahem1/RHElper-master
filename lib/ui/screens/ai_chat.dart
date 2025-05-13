import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart'; // ✅ استيراد Services للحصول على HapticFeedback
import 'package:image_picker/image_picker.dart'; // ✅ استيراد ImagePicker
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:road_helperr/ui/screens/ai_welcome_screen.dart';
import 'package:road_helperr/ui/screens/bottomnavigationbar_screes/home_screen.dart';
import 'package:road_helperr/ui/screens/bottomnavigationbar_screes/map_screen.dart';
import 'package:road_helperr/ui/screens/bottomnavigationbar_screes/notification_screen.dart';
import '../screens/bottomnavigationbar_screes/profile_screen.dart';
import 'package:road_helperr/utils/text_strings.dart';
import 'package:permission_handler/permission_handler.dart'; // ✅ استيراد permission_handler
import 'dart:io';
import 'dart:convert';
import 'dart:math'; // ✅ استيراد math للحصول على دالة sin
import 'package:road_helperr/services/gemini_service.dart';
import 'package:road_helperr/data/car_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:road_helperr/models/profile_data.dart';
import 'package:road_helperr/services/profile_service.dart';

class AiChat extends StatefulWidget {
  static const String routeName = "ai chat";

  const AiChat({super.key});

  @override
  State<AiChat> createState() => _AiChatState();
}

class _AiChatState extends State<AiChat> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  bool _hasCameraPermission = false;
  String? _tempImagePath;
  bool _showScrollButton = false;

  // User profile data
  ProfileData? _profileData;
  bool _isLoadingProfile = true;

  bool get _showWelcomeMessages => _messages.isEmpty;

  @override
  void initState() {
    super.initState();
    _checkAndRequestCameraPermission();
    _loadMessages(); // استرجاع المحادثات المخزنة
    _loadUserProfile(); // تحميل بيانات المستخدم

    // إضافة مستمع للتمرير لإظهار/إخفاء زر التمرير لأسفل
    _scrollController.addListener(_scrollListener);
  }

  // تحميل بيانات المستخدم
  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('logged_in_email');

      if (userEmail != null && userEmail.isNotEmpty) {
        // استخدام ProfileService لجلب بيانات المستخدم
        final profileService = ProfileService();
        final profileData = await profileService.getProfileData(userEmail);

        // تحميل بيانات المستخدم في GeminiService أيضًا
        await GeminiService.fetchUserProfile(userEmail);

        if (mounted) {
          setState(() {
            _profileData = profileData;
            _isLoadingProfile = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingProfile = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  // مستمع التمرير
  void _scrollListener() {
    // إذا كان المستخدم قد مرر لأعلى بمقدار 200 بكسل على الأقل، أظهر زر التمرير
    if (_scrollController.hasClients &&
        _scrollController.position.pixels <
            _scrollController.position.maxScrollExtent - 200) {
      if (!_showScrollButton) {
        setState(() {
          _showScrollButton = true;
        });
      }
    } else {
      if (_showScrollButton) {
        setState(() {
          _showScrollButton = false;
        });
      }
    }
  }

  // استرجاع المحادثات المخزنة
  Future<void> _loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getString('ai_chat_messages');

      if (messagesJson != null && messagesJson.isNotEmpty) {
        final List<dynamic> decodedMessages = jsonDecode(messagesJson);
        final loadedMessages = decodedMessages
            .map((msgJson) => ChatMessage.fromJson(msgJson))
            .toList();

        if (mounted) {
          setState(() {
            _messages.clear();
            _messages.addAll(loadedMessages);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  // حفظ المحادثات
  Future<void> _saveMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson =
          jsonEncode(_messages.map((msg) => msg.toJson()).toList());
      await prefs.setString('ai_chat_messages', messagesJson);
    } catch (e) {
      debugPrint('Error saving messages: $e');
    }
  }

  Future<void> _checkAndRequestCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      setState(() {
        _hasCameraPermission = true;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = MediaQuery.of(context).size;
        final isTablet = constraints.maxWidth > 600;
        final isDesktop = constraints.maxWidth > 1200;
        final viewInsets = MediaQuery.of(context).viewInsets;

        double titleSize = size.width *
            (isDesktop
                ? 0.02
                : isTablet
                    ? 0.03
                    : 0.04);
        double iconSize = size.width *
            (isDesktop
                ? 0.02
                : isTablet
                    ? 0.025
                    : 0.03);
        double imageSize = size.width *
            (isDesktop
                ? 0.15
                : isTablet
                    ? 0.2
                    : 0.3);
        double spacing = size.height *
            (isDesktop
                ? 0.04
                : isTablet
                    ? 0.05
                    : 0.06);

        return Scaffold(
          backgroundColor: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : const Color(0xFF01122A),
          floatingActionButton:
              null, // سنستخدم حل مخصص بدلاً من FloatingActionButton
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          appBar: AppBar(
            backgroundColor: Theme.of(context).brightness == Brightness.light
                ? Colors.white
                : const Color(0xFF01122A),
            title: Text(
              AppLocalizations.of(context)?.aiChat ?? TextStrings.appBarAiChat,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
                fontSize: titleSize,
                fontFamily:
                    platform == TargetPlatform.iOS ? '.SF Pro Text' : null,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(
                platform == TargetPlatform.iOS
                    ? CupertinoIcons.back
                    : Icons.arrow_back,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
                size: iconSize * 1.2,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_messages.isNotEmpty)
                IconButton(
                  icon: Icon(
                    platform == TargetPlatform.iOS
                        ? CupertinoIcons.delete
                        : Icons.delete_outline,
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.black
                        : Colors.white,
                    size: iconSize,
                  ),
                  onPressed: _showClearChatConfirmation,
                ),
            ],
            elevation: 0,
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(
                        maxWidth: isDesktop ? 1200 : double.infinity),
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.04,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.white
                          : const Color(0xFF01122A),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: spacing / 2),
                        Image.asset(
                          'assets/images/ai.png',
                          width: imageSize,
                          height: imageSize,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: spacing / 2),
                        Expanded(
                          child: Stack(
                            children: [
                              _showWelcomeMessages
                                  ? SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InfoCard(
                                            title: _isLoadingProfile
                                                ? AppLocalizations.of(context)
                                                        ?.answerOfYourQuestions ??
                                                    "Answer of your questions"
                                                : _profileData != null
                                                    ? "هاي ${_profileData!.name}! Road Helper"
                                                    : AppLocalizations.of(
                                                                context)
                                                            ?.answerOfYourQuestions ??
                                                        "Answer of your questions",
                                            subtitle: _isLoadingProfile
                                                ? AppLocalizations.of(context)
                                                        ?.justAskMeAnythingYouLike ??
                                                    "( Just ask me anything you like )"
                                                : _profileData != null &&
                                                        _profileData!
                                                                .carModel !=
                                                            null
                                                    ? "كيف يمكنني مساعدتك اليوم؟"
                                                    : AppLocalizations.of(
                                                                context)
                                                            ?.justAskMeAnythingYouLike ??
                                                        "( Just ask me anything you like )",
                                            isUserMessage: false,
                                            isWelcomeMessage: true,
                                          ),
                                          const SizedBox(height: 8),
                                          InfoCard(
                                            title: AppLocalizations.of(context)
                                                    ?.availableForYouAllDay ??
                                                "Available for you all day",
                                            subtitle: _isLoadingProfile
                                                ? AppLocalizations.of(context)
                                                        ?.feelFreeToAskAnytime ??
                                                    "( Feel free to ask me anytime )"
                                                : _profileData != null &&
                                                        _profileData!
                                                                .carModel !=
                                                            null
                                                    ? "هل تحتاج مساعدة بخصوص سيارتك ${_profileData!.carModel}؟"
                                                    : AppLocalizations.of(
                                                                context)
                                                            ?.feelFreeToAskAnytime ??
                                                        "( Feel free to ask me anytime )",
                                            isUserMessage: false,
                                            isWelcomeMessage: true,
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      controller: _scrollController,
                                      itemCount: _messages.length,
                                      itemBuilder: (context, index) {
                                        final message = _messages[index];
                                        return Padding(
                                          padding: EdgeInsets.only(
                                              bottom: spacing * 0.3),
                                          child: InfoCard(
                                            title: message.message,
                                            subtitle: message.details,
                                            isUserMessage:
                                                message.isUserMessage,
                                            imagePath: message.imagePath,
                                            timestamp: message.timestamp,
                                            isWelcomeMessage: false,
                                          ),
                                        );
                                      },
                                    ),
                              // زر التمرير المخصص مع تأثير حركي
                              if (_showScrollButton && !_showWelcomeMessages)
                                Positioned(
                                  right: 16,
                                  bottom: 120, // موضع أعلى من السابق
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0.0, end: 1.0),
                                    duration: const Duration(milliseconds: 300),
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: 0.8 + (0.2 * value),
                                        child: AnimatedOpacity(
                                          opacity: value,
                                          duration:
                                              const Duration(milliseconds: 200),
                                          child: TweenAnimationBuilder<double>(
                                            tween: Tween<double>(
                                                begin: 0.0, end: 1.0),
                                            duration: const Duration(
                                                milliseconds: 1500),
                                            curve: Curves.easeInOut,
                                            builder: (context, pulseValue, _) {
                                              // تأثير نبض للزر
                                              return Transform.translate(
                                                offset: Offset(
                                                    0,
                                                    sin(pulseValue *
                                                            3 *
                                                            3.14159) *
                                                        3),
                                                child: Container(
                                                  height: 55,
                                                  width: 55,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                      colors: [
                                                        Theme.of(context)
                                                                    .brightness ==
                                                                Brightness.light
                                                            ? const Color(
                                                                0xFF1565C0) // أزرق داكن
                                                            : const Color(
                                                                0xFF4FC3F7), // أزرق فاتح
                                                        Theme.of(context)
                                                                    .brightness ==
                                                                Brightness.light
                                                            ? const Color(
                                                                0xFF0D47A1) // أزرق داكن جداً
                                                            : const Color(
                                                                0xFF2196F3), // أزرق متوسط
                                                      ],
                                                    ),
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: (Theme.of(context)
                                                                        .brightness ==
                                                                    Brightness
                                                                        .light
                                                                ? Colors
                                                                    .blue[700]
                                                                : Colors.blue[
                                                                    300]) ??
                                                            Colors.blue,
                                                        blurRadius: 10,
                                                        spreadRadius: 2,
                                                        offset:
                                                            const Offset(0, 3),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      customBorder:
                                                          const CircleBorder(),
                                                      onTap: () {
                                                        _scrollToBottom();
                                                        // تأثير اهتزاز بسيط عند النقر
                                                        HapticFeedback
                                                            .mediumImpact();
                                                      },
                                                      child: Center(
                                                        child: Icon(
                                                          platform ==
                                                                  TargetPlatform
                                                                      .iOS
                                                              ? CupertinoIcons
                                                                  .arrow_down_circle_fill
                                                              : Icons
                                                                  .keyboard_double_arrow_down,
                                                          color: Colors.white,
                                                          size: 30,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Theme.of(context).scaffoldBackgroundColor
                        : const Color(0xFF01122A),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: SafeArea(
                    bottom: true,
                    maintainBottomViewPadding: true,
                    child: _buildChatInput(
                        context, size, titleSize, iconSize, platform),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: viewInsets.bottom == 0
              ? SafeArea(
                  child: Material(
                    elevation: 8.0,
                    child: Container(
                      constraints: BoxConstraints(
                          maxWidth: isDesktop ? 1200 : double.infinity),
                      margin: const EdgeInsets.only(bottom: 0),
                      child: CurvedNavigationBar(
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.light
                                ? Colors.white
                                : const Color(0xFF01122A),
                        color: Theme.of(context).brightness == Brightness.light
                            ? const Color(0xFF023A87)
                            : const Color(0xFF1F3551),
                        buttonBackgroundColor:
                            Theme.of(context).brightness == Brightness.light
                                ? const Color(0xFF023A87)
                                : const Color(0xFF1F3551),
                        animationDuration: const Duration(milliseconds: 300),
                        height: 45,
                        index: 2,
                        items: [
                          Icon(
                              platform == TargetPlatform.iOS
                                  ? CupertinoIcons.home
                                  : Icons.home_outlined,
                              size: 18,
                              color: Colors.white),
                          Icon(
                              platform == TargetPlatform.iOS
                                  ? CupertinoIcons.location
                                  : Icons.location_on_outlined,
                              size: 18,
                              color: Colors.white),
                          Icon(
                              platform == TargetPlatform.iOS
                                  ? CupertinoIcons.chat_bubble
                                  : Icons.textsms_outlined,
                              size: 18,
                              color: Colors.white),
                          Icon(
                              platform == TargetPlatform.iOS
                                  ? CupertinoIcons.bell
                                  : Icons.notifications_outlined,
                              size: 18,
                              color: Colors.white),
                          Icon(
                              platform == TargetPlatform.iOS
                                  ? CupertinoIcons.person
                                  : Icons.person_2_outlined,
                              size: 18,
                              color: Colors.white),
                        ],
                        onTap: (index) => _handleNavigation(context, index),
                      ),
                    ),
                  ),
                )
              : null,
          resizeToAvoidBottomInset: true,
        );
      },
    );
  }

  Widget _buildChatInput(BuildContext context, Size size, double titleSize,
      double iconSize, TargetPlatform platform) {
    var lang = AppLocalizations.of(context)!;

    final isLightMode = Theme.of(context).brightness == Brightness.light;

    return Container(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.04,
          vertical: 8,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.3,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_tempImagePath != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_tempImagePath!),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: -10,
                        top: -10,
                        child: IconButton(
                          icon: const Icon(Icons.cancel,
                              color: Colors.red, size: 24),
                          onPressed: () {
                            setState(() {
                              _tempImagePath = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Row(
                children: [
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 100),
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        minLines: 1,
                        style: TextStyle(
                          fontSize: titleSize * 0.8,
                          color: Colors.black,
                          fontFamily: platform == TargetPlatform.iOS
                              ? '.SF Pro Text'
                              : null,
                        ),
                        decoration: InputDecoration(
                          hintText: lang.askMeAnything,
                          hintStyle: TextStyle(
                            fontSize: titleSize * 0.8,
                            color: Colors.black54,
                            fontFamily: platform == TargetPlatform.iOS
                                ? '.SF Pro Text'
                                : null,
                          ),
                          filled: true,
                          fillColor: isLightMode
                              ? const Color(0xFFCCC9C9)
                              : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              platform == TargetPlatform.iOS
                                  ? CupertinoIcons.camera
                                  : Icons.camera_alt_outlined,
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? const Color(0xFF023A87)
                                  : const Color(0xFF023A87),
                              size: iconSize,
                            ),
                            onPressed: _showCameraConfirmationDialog,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: size.width * 0.02),
                  Container(
                    height: iconSize * 2.2,
                    width: iconSize * 2.2,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.light
                          ? const Color(0xFF023A87)
                          : const Color(0xFF296FF5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        platform == TargetPlatform.iOS
                            ? CupertinoIcons.arrow_right
                            : Icons.send,
                        color: Colors.white,
                        size: iconSize * 0.8,
                      ),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty && _tempImagePath == null) return;

    final userMessage = message;
    final userImagePath = _tempImagePath;

    // إضافة رسالة المستخدم
    setState(() {
      _messages.add(ChatMessage(
        message: userMessage,
        details: "",
        isUserMessage: true,
        imagePath: userImagePath,
        timestamp: DateTime.now(),
      ));

      // إضافة رسالة "جاري التحميل" مؤقتة
      _messages.add(ChatMessage(
        message: "جاري التفكير...",
        details: "",
        isUserMessage: false,
        timestamp: DateTime.now(),
      ));

      _messageController.clear();
      _tempImagePath = null;
    });

    // حفظ المحادثات بعد إضافة رسالة المستخدم
    // لا نحفظ رسالة "جاري التحميل" لأنها ستتم إزالتها لاحقًا
    final tempMessages = List<ChatMessage>.from(_messages);
    tempMessages.removeLast(); // إزالة رسالة "جاري التحميل"
    final prefs = await SharedPreferences.getInstance();
    final messagesJson =
        jsonEncode(tempMessages.map((msg) => msg.toJson()).toList());
    await prefs.setString('ai_chat_messages', messagesJson);

    // التمرير إلى أسفل الشاشة
    _scrollToBottom();

    // إعداد سياق النظام والتنسيق
    const systemPrompt =
        '       أنت مساعد ذكي متخصص في مساعدة سائقي السيارات. استخدم بيانات السيارات المتوفرة وخبرتك لتقديم نصائح دقيقة حول المواصفات، الأداء، القيمة، المشاكل الشائعة، الصيانة، والإصلاحات الطارئة للسيارات. يمكنك تحليل الصور المرفقة للسيارات أو قطع الغيار وتقديم معلومات عنها. أجب على جميع الأسئلة المتعلقة بالسيارات وقيادتها وصيانتها وإصلاحها، حتى في حالات الطوارئ على الطريق. قدم حلولاً عملية للمشاكل التي قد تواجه السائقين. أجب بنفس لغة السؤال. لا تجيب عن اي رسائل لها علاقة بالامراض ,او الساسة او الانتخابات او الدين او احكام الدين او الافلام والمسلسلات ولا متوسيكلات او ملابس او محلات بيع اي منتجات خارج اطار السيارات ولا تجيب عن اي معلومات خارج اطار السيارات بصفة عامة و صانتها وانواعها والموديلات ومشاكلها واصلاحها  ';
    const responseFormat =
        'قدم إجابات عملية ومفيدة. إذا كانت هناك صورة، قم بتحليلها وتقديم معلومات عن السيارة أو القطعة الظاهرة فيها. إذا كان السؤال عن مشكلة في السيارة، قدم حلولاً عملية يمكن تنفيذها.';

    String? response;

    try {
      // تحويل رسائل الدردشة إلى تنسيق Gemini (باستثناء رسالة "جاري التحميل")
      final List<GeminiChatMessage> chatHistory = _messages
          .where((msg) => msg.message != "جاري التفكير...")
          .map((msg) => GeminiChatMessage(
                text: msg.message,
                isUser: msg.isUserMessage,
              ))
          .toList();

      if (userImagePath != null) {
        // إرسال استعلام مع صورة
        response = await GeminiService.sendImageQuery(
          data: carData,
          userQuery: userMessage.isEmpty
              ? 'ما هذه الصورة؟ قدم لي معلومات عنها.'
              : userMessage,
          imageFile: File(userImagePath),
          chatHistory: chatHistory,
          systemContext: systemPrompt,
          responseFormat: responseFormat,
        );
      } else {
        // إرسال استعلام نصي فقط
        response = await GeminiService.sendQuery(
          data: carData,
          userQuery: userMessage,
          chatHistory: chatHistory,
          systemContext: systemPrompt,
          responseFormat: responseFormat,
        );
      }

      // تحسين تنسيق الروابط في الرد إذا كانت موجودة
      if (response != null && response.contains('](#')) {
        debugPrint('تم العثور على روابط في الرد');
      }

      if (response == null || response.isEmpty) {
        response =
            'عذراً، لم أتمكن من الحصول على إجابة. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.';
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      response = 'عذراً، حدث خطأ أثناء معالجة طلبك. يرجى المحاولة مرة أخرى.';
    }

    // تأخير بسيط لتجنب مشاكل تحديث واجهة المستخدم
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        // إزالة رسالة "جاري التحميل"
        _messages.removeLast();

        // إضافة رد المساعد
        _messages.add(ChatMessage(
          message: response!,
          details: "",
          isUserMessage: false,
          timestamp: DateTime.now(),
        ));
      });

      // حفظ المحادثات بعد إضافة رسالة جديدة
      _saveMessages();

      // التمرير إلى أسفل الشاشة
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleNavigation(BuildContext context, int index) {
    final routes = [
      HomeScreen.routeName,
      MapScreen.routeName,
      AiWelcomeScreen.routeName,
      NotificationScreen.routeName,
      ProfileScreen.routeName,
    ];

    if (index < routes.length) {
      Navigator.pushNamed(context, routes[index]);
    }
  }

  Future<void> _showCameraConfirmationDialog() async {
    if (_hasCameraPermission) {
      _pickImageFromCamera();
    } else {
      final status = await Permission.camera.request();
      setState(() {
        _hasCameraPermission = status.isGranted;
      });
      if (status.isGranted) {
        _pickImageFromCamera();
      } else if (status.isPermanentlyDenied) {
        openAppSettings();
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1000,
      );
      if (pickedFile != null && mounted) {
        setState(() {
          _tempImagePath = pickedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error capturing image")),
        );
      }
    }
  }

  // عرض مربع حوار تأكيد مسح المحادثات
  void _showClearChatConfirmation() {
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('مسح المحادثة'),
          content: const Text('هل أنت متأكد من رغبتك في مسح جميع المحادثات؟'),
          actions: [
            CupertinoDialogAction(
              child: const Text('إلغاء'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('مسح'),
              onPressed: () {
                Navigator.pop(context);
                _clearChat();
              },
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('مسح المحادثة'),
          content: const Text('هل أنت متأكد من رغبتك في مسح جميع المحادثات؟'),
          actions: [
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text(
                'مسح',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.pop(context);
                _clearChat();
              },
            ),
          ],
        ),
      );
    }
  }

  // مسح المحادثات
  Future<void> _clearChat() async {
    setState(() {
      _messages.clear();
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('ai_chat_messages');
    } catch (e) {
      debugPrint('Error clearing chat: $e');
    }
  }
}

class ChatMessage {
  final String message;
  final String details;
  final bool isUserMessage;
  final String? imagePath;
  final DateTime timestamp;

  ChatMessage({
    required this.message,
    required this.details,
    required this.isUserMessage,
    this.imagePath,
    required this.timestamp,
  });

  // تحويل الرسالة إلى Map لتخزينها
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'details': details,
      'isUserMessage': isUserMessage,
      'imagePath': imagePath,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // إنشاء رسالة من Map
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      message: json['message'],
      details: json['details'],
      isUserMessage: json['isUserMessage'],
      imagePath: json['imagePath'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isUserMessage;
  final String? imagePath;
  final DateTime? timestamp;
  final bool isWelcomeMessage;

  const InfoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isUserMessage,
    this.imagePath,
    this.timestamp,
    required this.isWelcomeMessage,
  });

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';

    // Convert to 12-hour format
    int hour = timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour;
    // If hour is 0 (midnight), display as 12
    hour = hour == 0 ? 12 : hour;
    String period = timestamp.hour >= 12 ? 'PM' : 'AM';

    return '${hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')} $period';
  }

  // معالجة النقر على الروابط
  void _handleLinkTap(BuildContext context, String href) {
    if (href.startsWith('#')) {
      // الروابط الداخلية للتطبيق
      final screenName = href.substring(1); // إزالة علامة #

      switch (screenName) {
        case 'home':
          Navigator.pushNamed(context, HomeScreen.routeName);
          break;
        case 'map':
          Navigator.pushNamed(context, MapScreen.routeName);
          break;
        case 'notifications':
          Navigator.pushNamed(context, NotificationScreen.routeName);
          break;
        case 'profile':
          Navigator.pushNamed(context, ProfileScreen.routeName);
          break;
        default:
          // إذا كان الرابط غير معروف، عرض رسالة خطأ
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('صفحة غير متوفرة: $screenName')),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    return Align(
      // Align user messages to the right, AI messages to the left
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(
          left: 8,
          right: 8,
          bottom: 8,
        ),
        child: Column(
          crossAxisAlignment:
              isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: isUserMessage
                    ? const Color(0xFF023A87)
                    : (isLightMode ? const Color(0xFFE8E8E8) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width *
                    0.75, // Reduced width for better chat appearance
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imagePath != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(imagePath!),
                          width: MediaQuery.of(context).size.width * 0.75,
                          fit: BoxFit.fitWidth,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.error, color: Colors.red),
                            );
                          },
                        ),
                      ),
                      if (title.isNotEmpty) const SizedBox(height: 8),
                    ],
                    if (title.isNotEmpty)
                      MarkdownBody(
                        data: title,
                        onTapLink: (text, href, title) {
                          if (href != null) {
                            _handleLinkTap(context, href);
                          }
                        },
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            fontSize: 18,
                            color: isUserMessage
                                ? Colors.white
                                : (isLightMode ? Colors.black : Colors.black),
                          ),
                          strong: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isUserMessage
                                ? Colors.white
                                : (isLightMode ? Colors.black : Colors.black),
                          ),
                          em: TextStyle(
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                            color: isUserMessage
                                ? Colors.white
                                : (isLightMode ? Colors.black : Colors.black),
                          ),
                          a: TextStyle(
                            fontSize: 18,
                            color: isUserMessage
                                ? Colors.lightBlue[100]
                                : (isLightMode
                                    ? Colors.blue[700]
                                    : Colors.lightBlue[300]),
                            decoration: TextDecoration.underline,
                          ),
                          code: TextStyle(
                            fontSize: 16,
                            backgroundColor: isUserMessage
                                ? Colors.white.withOpacity(0.2)
                                : (isLightMode
                                    ? Colors.grey[200]
                                    : Colors.black45),
                            color: isUserMessage
                                ? Colors.white
                                : (isLightMode ? Colors.black : Colors.black),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      MarkdownBody(
                        data: subtitle,
                        onTapLink: (text, href, title) {
                          if (href != null) {
                            _handleLinkTap(context, href);
                          }
                        },
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            fontSize: 16,
                            color: isUserMessage
                                ? Colors.white.withOpacity(0.7)
                                : (isLightMode
                                    ? Colors.black54
                                    : Colors.black54),
                          ),
                          a: TextStyle(
                            fontSize: 16,
                            color: isUserMessage
                                ? Colors.lightBlue[100]
                                : (isLightMode
                                    ? Colors.blue[700]
                                    : Colors.lightBlue[300]),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (!isWelcomeMessage && timestamp != null) ...[
              const SizedBox(height: 2),
              Align(
                alignment: isUserMessage
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    _formatTimestamp(timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
