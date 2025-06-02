import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:road_helperr/ui/screens/bottomnavigationbar_screes/home_screen.dart';
import 'package:road_helperr/services/notification_service.dart';
import 'package:road_helperr/services/api_service.dart';
import 'package:road_helperr/utils/app_colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CarGoogleScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CarGoogleScreen({
    super.key,
    required this.userData,
  });

  static const String routeName = "car_google_screen";

  @override
  State<CarGoogleScreen> createState() => _CarGoogleScreenState();
}

class _CarGoogleScreenState extends State<CarGoogleScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _firstLetterController = TextEditingController();
  final TextEditingController _secondLetterController = TextEditingController();
  final TextEditingController _thirdLetterController = TextEditingController();
  final TextEditingController _numbersController = TextEditingController();
  final TextEditingController _carColorController = TextEditingController();
  final TextEditingController _carModelController = TextEditingController();

  final FocusNode _firstLetterFocus = FocusNode();
  final FocusNode _secondLetterFocus = FocusNode();
  final FocusNode _thirdLetterFocus = FocusNode();
  final FocusNode _numbersFocus = FocusNode();

  bool _isLoading = false;

  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String? _photoURL;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    // طباعة بيانات المستخدم للتصحيح
    debugPrint('User data received: ${widget.userData}');
    debugPrint('Photo URL from Google: ${widget.userData['photoURL']}');

    setState(() {
      _firstName = widget.userData['firstName'] ?? '';
      _lastName = widget.userData['lastName'] ?? '';
      _email = widget.userData['email'] ?? '';
      _photoURL = widget.userData['photoURL'];

      // طباعة قيمة _photoURL بعد التعيين
      debugPrint('_photoURL after assignment: $_photoURL');

      // إذا كان رقم الهاتف موجودًا في بيانات المستخدم، قم بتعيينه
      if (widget.userData['phone'] != null &&
          widget.userData['phone'].toString().isNotEmpty) {
        _phoneController.text = widget.userData['phone'];
      }
    });
  }

  Future<void> _completeSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // تحديث بيانات المستخدم مع رقم الهاتف وبيانات السيارة
      final updatedUserData = Map<String, dynamic>.from(widget.userData);
      updatedUserData['phone'] = _phoneController.text;

      // جمع حروف لوحة السيارة (إذا تم إدخالها)
      final letters =
          "${_firstLetterController.text}${_secondLetterController.text}${_thirdLetterController.text}";

      // تكوين رقم اللوحة الكامل (الحروف + الأرقام)
      final fullPlateNumber = letters.isNotEmpty
          ? "$letters-${_numbersController.text}"
          : _numbersController.text;

      // إضافة رقم اللوحة بالتنسيق الصحيح وباسم الحقل الصحيح (Car Number) كما هو مطلوب في API
      updatedUserData['Car Number'] = fullPlateNumber;

      // إضافة لون وموديل السيارة بالأسماء الصحيحة للحقول
      updatedUserData['car_color'] = _carColorController.text.trim();
      updatedUserData['car_model'] = _carModelController.text.trim();

      // التأكد من وجود صورة الملف الشخصي
      debugPrint('Photo URL before API call: ${updatedUserData['photoURL']}');

      // إذا كانت صورة الملف الشخصي غير موجودة، استخدم صورة افتراضية
      if (updatedUserData['photoURL'] == null ||
          updatedUserData['photoURL'].toString().isEmpty) {
        updatedUserData['photoURL'] =
            'https://ui-avatars.com/api/?name=${Uri.encodeComponent('$_firstName $_lastName')}&background=random';
        debugPrint(
            'Using default profile picture: ${updatedUserData['photoURL']}');
      }

      // تعيين الصورة الشخصية باسم الحقل الصحيح (Profile Picture) كما هو مطلوب في API
      updatedUserData['Profile Picture'] = updatedUserData['photoURL'];

      // طباعة البيانات النهائية للتأكد من صحتها
      debugPrint('Final user data before API call: $updatedUserData');

      // استدعاء API لتسجيل المستخدم في الخادم
      final response = await ApiService.registerGoogleUser(updatedUserData);

      if (!response['success']) {
        // إذا فشلت عملية التسجيل، عرض رسالة الخطأ
        if (mounted) {
          final lang = AppLocalizations.of(context)!;
          final theme = Theme.of(context);
          final isDarkMode = theme.brightness == Brightness.dark;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['error'] ?? lang.error,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: isDarkMode
                  ? const Color(0xFFD32F2F) // أحمر داكن للوضع الداكن
                  : const Color(0xFFE57373), // أحمر فاتح للوضع الفاتح
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }
      }

      // حفظ بيانات المستخدم في SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('logged_in_email', _email);
      await prefs.setBool('is_google_sign_in', true);

      if (mounted) {
        // عرض رسالة نجاح
        NotificationService.showRegistrationSuccess(
          context,
          onConfirm: () {
            // الانتقال إلى الشاشة الرئيسية
            Navigator.of(context).pushNamedAndRemoveUntil(
              HomeScreen.routeName,
              (route) => false,
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showNetworkError(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _firstLetterController.dispose();
    _secondLetterController.dispose();
    _thirdLetterController.dispose();
    _numbersController.dispose();
    _carColorController.dispose();
    _carModelController.dispose();

    _firstLetterFocus.dispose();
    _secondLetterFocus.dispose();
    _thirdLetterFocus.dispose();
    _numbersFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor = isLight ? Colors.black : Colors.white;
    final bgColor = isLight ? const Color(0xFF86A5D9) : const Color(0xFF1F3551);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // صورة العلوية
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.25,
              decoration: BoxDecoration(
                color: bgColor,
                image: const DecorationImage(
                  image: AssetImage("assets/images/rafiki.png"),
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // المحتوى الرئيسي
            Expanded(
              child: Container(
                width: double.infinity,
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
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // صورة الملف الشخصي
                        if (_photoURL != null && _photoURL!.isNotEmpty)
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(_photoURL!),
                            backgroundColor: Colors.grey[300],
                          )
                        else
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[300],
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey[600],
                            ),
                          ),
                        const SizedBox(height: 20),

                        // اسم المستخدم
                        Text(
                          '$_firstName $_lastName',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),

                        // البريد الإلكتروني
                        Text(
                          _email,
                          style: TextStyle(
                            color: textColor.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // عنوان إدخال رقم الهاتف
                        Text(
                          lang.phoneNumber,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // حقل إدخال رقم الهاتف
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: lang.phoneNumber,
                            hintText: lang.enterYourPhoneNumber,
                            prefixIcon: Icon(Icons.phone, color: textColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                color: textColor,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                color: isLight
                                    ? AppColors.getSignAndRegister(context)
                                    : Colors.white,
                                width: 2,
                              ),
                            ),
                            labelStyle: TextStyle(color: textColor),
                            hintStyle:
                                TextStyle(color: textColor.withOpacity(0.5)),
                            filled: true,
                            fillColor:
                                isLight ? Colors.white : Colors.transparent,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return lang.pleaseEnterPhoneNumber;
                            }
                            if (value.length < 11) {
                              return lang.mustBeExactly11Digits;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // عنوان بيانات السيارة
                        Text(
                          lang.carSettings,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // حقول إدخال حروف لوحة السيارة
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.letters,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                // الحرف الأول
                                Expanded(
                                  child: TextFormField(
                                    controller: _firstLetterController,
                                    focusNode: _firstLetterFocus,
                                    textAlign: TextAlign.center,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    style: TextStyle(
                                        color: textColor, fontSize: 18),
                                    decoration: InputDecoration(
                                      counterText: "",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      filled: true,
                                      fillColor: isLight
                                          ? Colors.white
                                          : Colors.transparent,
                                    ),
                                    maxLength: 1,
                                    onChanged: (value) {
                                      if (value.length == 1) {
                                        _secondLetterFocus.requestFocus();
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // الحرف الثاني
                                Expanded(
                                  child: TextFormField(
                                    controller: _secondLetterController,
                                    focusNode: _secondLetterFocus,
                                    textAlign: TextAlign.center,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    style: TextStyle(
                                        color: textColor, fontSize: 18),
                                    decoration: InputDecoration(
                                      counterText: "",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      filled: true,
                                      fillColor: isLight
                                          ? Colors.white
                                          : Colors.transparent,
                                    ),
                                    maxLength: 1,
                                    onChanged: (value) {
                                      if (value.length == 1) {
                                        _thirdLetterFocus.requestFocus();
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // الحرف الثالث
                                Expanded(
                                  child: TextFormField(
                                    controller: _thirdLetterController,
                                    focusNode: _thirdLetterFocus,
                                    textAlign: TextAlign.center,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    style: TextStyle(
                                        color: textColor, fontSize: 18),
                                    decoration: InputDecoration(
                                      counterText: "",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      filled: true,
                                      fillColor: isLight
                                          ? Colors.white
                                          : Colors.transparent,
                                    ),
                                    maxLength: 1,
                                    onChanged: (value) {
                                      if (value.length == 1) {
                                        _numbersFocus.requestFocus();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // حقل إدخال أرقام اللوحة
                        TextFormField(
                          controller: _numbersController,
                          focusNode: _numbersFocus,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: lang.plateNumbers,
                            hintText: lang.enterPlateNumber,
                            prefixIcon: Icon(Icons.numbers, color: textColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                color: textColor,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                color: isLight
                                    ? AppColors.getSignAndRegister(context)
                                    : Colors.white,
                                width: 2,
                              ),
                            ),
                            labelStyle: TextStyle(color: textColor),
                            hintStyle:
                                TextStyle(color: textColor.withOpacity(0.5)),
                            filled: true,
                            fillColor:
                                isLight ? Colors.white : Colors.transparent,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(7),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return lang.pleaseEnterNumbers;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // حقل إدخال لون السيارة
                        TextFormField(
                          controller: _carColorController,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: lang.carColor,
                            hintText: lang.enterCarColor,
                            prefixIcon:
                                Icon(Icons.color_lens, color: textColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                color: textColor,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                color: isLight
                                    ? AppColors.getSignAndRegister(context)
                                    : Colors.white,
                                width: 2,
                              ),
                            ),
                            labelStyle: TextStyle(color: textColor),
                            hintStyle:
                                TextStyle(color: textColor.withOpacity(0.5)),
                            filled: true,
                            fillColor:
                                isLight ? Colors.white : Colors.transparent,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return lang.pleaseEnterCarColor;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // حقل إدخال موديل السيارة
                        TextFormField(
                          controller: _carModelController,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: lang.carModel,
                            hintText: lang.enterCarModel,
                            prefixIcon:
                                Icon(Icons.directions_car, color: textColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                color: textColor,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                color: isLight
                                    ? AppColors.getSignAndRegister(context)
                                    : Colors.white,
                                width: 2,
                              ),
                            ),
                            labelStyle: TextStyle(color: textColor),
                            hintStyle:
                                TextStyle(color: textColor.withOpacity(0.5)),
                            filled: true,
                            fillColor:
                                isLight ? Colors.white : Colors.transparent,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return lang.pleaseEnterCarModel;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),

                        // زر التسجيل
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _completeSignup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF023A87),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : Text(
                                    lang.signUpButton,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
