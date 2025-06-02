import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:road_helperr/ui/public_details/input_field.dart' as INp;
import 'package:road_helperr/ui/public_details/main_button.dart' as bum;
import 'package:road_helperr/ui/screens/car_settings_screen.dart';
import 'package:road_helperr/ui/screens/license_capture_screen.dart';
import 'package:road_helperr/utils/app_colors.dart' as colo;
import 'package:road_helperr/ui/screens/signin_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:road_helperr/ui/screens/signupScreen.dart'
    show signInWithGoogle;
import 'package:road_helperr/services/api_service.dart';
// import 'package:road_helperr/services/google_auth_service.dart';

class ValidationForm extends StatefulWidget {
  const ValidationForm({super.key});

  @override
  _ValidationFormState createState() => _ValidationFormState();
}

class _ValidationFormState extends State<ValidationForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final TextEditingController firstNameController = TextEditingController();
  final FocusNode firstNameFocusNode = FocusNode();

  final TextEditingController lastNameController = TextEditingController();
  final FocusNode lastNameFocusNode = FocusNode();

  final TextEditingController phoneController = TextEditingController();
  final FocusNode phoneFocusNode = FocusNode();

  final TextEditingController emailController = TextEditingController();
  final FocusNode emailFocusNode = FocusNode();

  final TextEditingController passwordController = TextEditingController();
  final FocusNode passwordFocusNode = FocusNode();

  final TextEditingController confirmPasswordController =
      TextEditingController();
  final FocusNode confirmPasswordFocusNode = FocusNode();

  // Show email exists dialog
  void _showEmailExistsDialog(String message, String messageEn) {
    if (!mounted) return;

    final lang = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // استخدام ألوان الثيم
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = isDarkMode ? const Color(0xFF1E2746) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
              width: 1,
            ),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: primaryColor,
              ),
              const SizedBox(width: 10),
              Text(
                lang.error,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            // استخدام الرسالة المناسبة حسب لغة التطبيق
            Localizations.localeOf(context).languageCode == 'ar'
                ? message
                : messageEn,
            style: TextStyle(
              color: textColor.withOpacity(0.8),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
              ),
              child: Text(lang.ok),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context)
                    .pushReplacementNamed(SignInScreen.routeName);
              },
              style: TextButton.styleFrom(
                foregroundColor: isDarkMode
                    ? const Color(0xFF90CAF9) // أزرق فاتح للوضع الداكن
                    : const Color(0xFF023A87), // أزرق داكن للوضع الفاتح
              ),
              child: Text(lang.login),
            ),
          ],
        );
      },
    );
  }

  // Proceed to license capture screen
  void _proceedToLicenseCapture() {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LicenseCaptureScreen(),
      ),
    ).then((result) {
      // Handle the result from license capture screen
      if (result != null && result is Map<String, dynamic>) {
        final frontImage = result['frontImage'] as File?;
        final backImage = result['backImage'] as File?;

        if (frontImage != null && backImage != null) {
          // Proceed to car settings with license images
          _proceedToCarSettings(frontImage, backImage);
        }
      }
    });
  }

  // Proceed to car settings screen with license images
  void _proceedToCarSettings(File? frontLicense, File? backLicense) {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CarSettingsScreen(
          registrationData: {
            'firstName': firstNameController.text.trim(),
            'lastName': lastNameController.text.trim(),
            'phone': phoneController.text.trim(),
            'email': emailController.text.trim(),
            'password': passwordController.text.trim(),
            'frontLicense': frontLicense,
            'backLicense': backLicense,
          },
        ),
      ),
    );
  }

  // Handle Google Sign In with proper error handling
  void _handleGoogleSignIn(BuildContext context) {
    setState(() {
      _isLoading = true;
    });

    // Store context in local variable
    final currentContext = context;
    final lang = AppLocalizations.of(currentContext)!;

    // Use Future to handle async operations
    Future.microtask(() async {
      try {
        // Call signInWithGoogle function
        await signInWithGoogle(currentContext);
      } catch (e) {
        // Check if still mounted before using context
        if (mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(
              content: Text('${lang.error}: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } finally {
        // Check if still mounted before updating state
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // تم إزالة المستمع للتحقق من البريد الإلكتروني
  }

  @override
  void dispose() {
    firstNameController.dispose();
    firstNameFocusNode.dispose();
    lastNameController.dispose();
    lastNameFocusNode.dispose();
    phoneController.dispose();
    phoneFocusNode.dispose();
    emailController.dispose();
    emailFocusNode.dispose();
    passwordController.dispose();
    passwordFocusNode.dispose();
    confirmPasswordController.dispose();
    confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var lang = AppLocalizations.of(context)!;
    double width = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              INp.InputField(
                icon: Icons.person,
                label: lang.firstName,
                hintText: lang.firstName,
                validatorIsContinue: (text) {
                  if (text!.isEmpty || text.length < 3) {
                    return lang.atLeast3Characters;
                  }
                  return null;
                },
                controller: firstNameController,
                focusNode: firstNameFocusNode,
              ),
              const SizedBox(height: 6),
              INp.InputField(
                icon: Icons.person,
                label: lang.lastName,
                hintText: lang.lastName,
                validatorIsContinue: (text) {
                  if (text!.isEmpty || text.length < 3) {
                    return lang.atLeast3Characters;
                  }
                  return null;
                },
                controller: lastNameController,
                focusNode: lastNameFocusNode,
              ),
              const SizedBox(height: 6),
              INp.InputField(
                icon: Icons.phone,
                label: lang.phoneNumber,
                hintText: lang.phone,
                keyboardType: TextInputType.number,
                controller: phoneController,
                focusNode: phoneFocusNode,
                validatorIsContinue: (phoneText) {
                  if (phoneText?.length != 11 ||
                      !RegExp(r'^[0-9]+').hasMatch(phoneText!)) {
                    return lang.mustBeExactly11Digits;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 6),
              INp.InputField(
                icon: Icons.email_outlined,
                label: lang.email,
                hintText: lang.email,
                validatorIsContinue: (emailText) {
                  final regExp = RegExp(
                      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}");
                  if (!regExp.hasMatch(emailText!)) {
                    return lang.invalidEmail;
                  }
                  return null;
                },
                controller: emailController,
                focusNode: emailFocusNode,
              ),
              const SizedBox(height: 6),
              INp.InputField(
                icon: Icons.lock,
                hintText: lang.enterYourPassword,
                label: lang.password,
                isPassword: true,
                controller: passwordController,
                focusNode: passwordFocusNode,
                validatorIsContinue: (passwordText) {
                  if (passwordText == null || passwordText.isEmpty) {
                    return lang.pleaseEnterYourPassword;
                  }
                  if (passwordText.length < 8) {
                    return lang.passwordMustBeAtLeast8Characters;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 6),
              INp.InputField(
                icon: Icons.lock,
                label: lang.confirmPassword,
                hintText: lang.confirmPassword,
                isPassword: true,
                validatorIsContinue: (confirmPasswordText) {
                  if (confirmPasswordText != passwordController.text) {
                    return lang.passwordsDoNotMatch;
                  }
                  return null;
                },
                controller: confirmPasswordController,
                focusNode: confirmPasswordFocusNode,
              ),
              const SizedBox(height: 15),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : bum.MainButton(
                      textButton: lang.nextPage,
                      onPress: () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _isLoading = true;
                          });

                          // التحقق من البريد الإلكتروني مباشرة عند الضغط على زر التالي
                          final email = emailController.text.trim();
                          try {
                            final result =
                                await ApiService.checkEmailExists(email);

                            final emailExists = result['success'] == true &&
                                result['exists'] == true;

                            if (emailExists) {
                              setState(() {
                                _isLoading = false;
                              });

                              // استخدام الرسائل من نتيجة API
                              _showEmailExistsDialog(
                                  result['message'] ??
                                      'هذا البريد الإلكتروني مرتبط بحساب موجود بالفعل',
                                  result['message_en'] ??
                                      'This email is already associated with an existing account');
                              return;
                            }

                            // المتابعة إلى تصوير الرخصة
                            _proceedToLicenseCapture();
                          } catch (e) {
                            // في حالة حدوث خطأ، نفترض أن البريد غير موجود ونتابع
                            _proceedToLicenseCapture();
                          } finally {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        } else {
                          final isDarkMode =
                              Theme.of(context).brightness == Brightness.dark;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                lang.allFieldsMustBeFilledOut,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              backgroundColor: isDarkMode
                                  ? const Color(
                                      0xFFD32F2F) // أحمر داكن للوضع الداكن
                                  : const Color(
                                      0xFFE57373), // أحمر فاتح للوضع الفاتح
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                    ),
              const SizedBox(height: 15),

              // Google Sign In Button
              InkWell(
                onTap: () {
                  _handleGoogleSignIn(context);
                },
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF023A87)
                        : const Color(0xFF1F3551),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/google.png',
                        height: 24,
                        width: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        lang.signUpWithGoogle,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.04,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    lang.alreadyHaveAnAccount,
                    style: TextStyle(
                      color: colo.AppColors.getBorderField(context),
                      fontSize: width * 0.035,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate directly to SignIn screen without validation
                      Navigator.of(context)
                          .pushReplacementNamed(SignInScreen.routeName);
                    },
                    child: Text(
                      lang.login,
                      style: TextStyle(
                        color: colo.AppColors.getSignAndRegister(context),
                        fontSize: width * 0.035,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
