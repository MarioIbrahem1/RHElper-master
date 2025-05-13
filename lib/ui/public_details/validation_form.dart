import 'package:flutter/material.dart';
import 'package:road_helperr/ui/public_details/input_field.dart' as INp;
import 'package:road_helperr/ui/public_details/main_button.dart' as bum;
import 'package:road_helperr/ui/screens/car_settings_screen.dart';
import 'package:road_helperr/utils/app_colors.dart' as colo;
import 'package:road_helperr/ui/screens/signin_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:road_helperr/ui/screens/signupScreen.dart' show signInWithGoogle;

class ValidationForm extends StatefulWidget {
  const ValidationForm({super.key});

  @override
  _ValidationFormState createState() => _ValidationFormState();
}

class _ValidationFormState extends State<ValidationForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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

  // Handle Google Sign In with proper error handling
  Future<void> _handleGoogleSignIn(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      // Use signInWithGoogle function directly from signupScreen.dart
      if (mounted) {
        // Close loading dialog first
        Navigator.of(context).pop();

        // Call signInWithGoogle function
        await signInWithGoogle(context);
      }
    } catch (e) {
      // Close loading indicator
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing in with Google: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
              bum.MainButton(
                textButton: lang.nextPage,
                onPress: () async {
                  if (_formKey.currentState!.validate()) {
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
                          },
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all fields correctly'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 3),
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
                        'Sign up with Google',
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
