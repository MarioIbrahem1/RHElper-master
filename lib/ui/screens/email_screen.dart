import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:road_helperr/ui/screens/signupScreen.dart';
import 'dart:math' show min;
import 'constants.dart';
import 'package:road_helperr/ui/screens/OTPscreen.dart';
import 'package:road_helperr/services/api_service.dart';
import 'package:road_helperr/services/notification_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EmailScreen extends StatefulWidget {
  static const String routeName = "emailscreen";
  const EmailScreen({super.key});

  @override
  _EmailScreenState createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _moveAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _moveAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1, curve: Curves.easeIn),
      ),
    );
  }

  Future<void> _validateAndNavigate() async {
    var lang = AppLocalizations.of(context)!;
    if (_emailController.text.isEmpty) {
      NotificationService.showError(
        context: context,
        title: lang.error,
        message: lang.pleaseEnterYourEmail,
      );
      return;
    }

    if (!_isValidEmail(_emailController.text)) {
      NotificationService.showError(
        context: context,
        title: lang.error,
        message: lang.pleaseEnterAValidEmail,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.sendOTP(_emailController.text);

      if (response['success']) {
        if (mounted) {
          final lang = AppLocalizations.of(context)!;
          NotificationService.showSuccess(
            context: context,
            title: lang.otpSent,
            message: lang.otpSentToEmail,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Otp(
                email: _emailController.text,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          final lang = AppLocalizations.of(context)!;
          NotificationService.showError(
            context: context,
            title: lang.error,
            message: response['error'] ?? lang.serverError,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final lang = AppLocalizations.of(context)!;
        NotificationService.showError(
          context: context,
          title: lang.error,
          message: lang.networkError,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final platform = Theme.of(context).platform;
    final bool isIOS = platform == TargetPlatform.iOS;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final double paddingHorizontal = size.width * 0.1;
    const double maxWidth = 450.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isLight ? null : AppColors.primaryGradient,
          color: isLight ? Colors.white : null,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: maxWidth),
                  padding: EdgeInsets.symmetric(
                    horizontal: paddingHorizontal,
                    vertical: size.height * 0.05,
                  ),
                  child: Column(
                    children: [
                      _buildAnimatedImage(isLight),
                      _buildHeaderTexts(size, isLight),
                      _buildEmailInput(size, isIOS, isLight),
                      _buildGetOTPButton(size, isIOS, isLight),
                      _buildRegisterLink(size, isLight),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 24.0),
                          child: CircularProgressIndicator(
                            color: AppColors.primaryBlue,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedImage(bool isLightMode) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..translate(0.0, _moveAnimation.value)
                ..scale(_scaleAnimation.value),
              alignment: Alignment.center,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: isLightMode
                          ? const Color(0xFF4285F4).withOpacity(0.2)
                          : AppColors.primaryBlue.withOpacity(0.2),
                      blurRadius: 15,
                      offset: Offset(0, 5 + (_moveAnimation.value * 0.2)),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/otp_image.png',
                  fit: BoxFit.contain,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderTexts(Size size, bool isLightMode) {
    var lang = AppLocalizations.of(context)!;
    return Container(
      margin: EdgeInsets.symmetric(vertical: size.height * 0.03),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              lang.otpVerification,
              style: TextStyle(
                color: isLightMode ? Colors.black : AppColors.white,
                fontSize: min(size.width * 0.06, 24),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: size.height * 0.02),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              lang.weWillSendYouAnOneTimePasswordOnYourEmailAddress,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isLightMode
                    ? Colors.black.withOpacity(0.7)
                    : AppColors.white.withOpacity(0.7),
                fontSize: min(size.width * 0.04, 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailInput(Size size, bool isIOS, bool isLightMode) {
    var lang = AppLocalizations.of(context)!;
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      margin: EdgeInsets.only(top: size.height * 0.01),
      decoration: BoxDecoration(
        color: isLightMode ? Colors.white : AppColors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLightMode
              ? const Color(0xFF4285F4)
              : AppColors.primaryBlue.withOpacity(0.3),
        ),
      ),
      child: isIOS
          ? CupertinoTextField(
              controller: _emailController,
              style: TextStyle(
                color: isLightMode ? Colors.black : AppColors.white,
                fontSize: min(size.width * 0.04, 16),
              ),
              placeholder: lang.enterYourEmail,
              placeholderStyle: TextStyle(
                color: isLightMode
                    ? Colors.black.withOpacity(0.5)
                    : AppColors.white.withOpacity(0.5),
                fontSize: min(size.width * 0.04, 16),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.05,
                vertical: 16,
              ),
              keyboardType: TextInputType.emailAddress,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
            )
          : TextFormField(
              controller: _emailController,
              style: TextStyle(
                color: isLightMode ? Colors.black : AppColors.white,
                fontSize: min(size.width * 0.04, 16),
              ),
              decoration: InputDecoration(
                hintText: lang.enterYourEmail,
                hintStyle: TextStyle(
                  color: isLightMode
                      ? Colors.black.withOpacity(0.5)
                      : AppColors.white.withOpacity(0.5),
                  fontSize: min(size.width * 0.04, 16),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.05,
                  vertical: 16,
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return lang.pleaseEnterYourEmail;
                }
                if (!_isValidEmail(value)) {
                  return lang.pleaseEnterAValidEmail;
                }
                return null;
              },
            ),
    );
  }

  Widget _buildGetOTPButton(Size size, bool isIOS, bool isLightMode) {
    var lang = AppLocalizations.of(context)!;
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      height: 48,
      margin: EdgeInsets.only(top: size.height * 0.03),
      child: isIOS
          ? CupertinoButton(
              color: isLightMode
                  ? const Color(0xFF023A87)
                  : const Color.fromARGB(255, 119, 146, 184),
              borderRadius: BorderRadius.circular(12),
              onPressed: _isLoading ? null : _validateAndNavigate,
              child: _isLoading
                  ? const CupertinoActivityIndicator()
                  : Text(
                      lang.getOtp,
                      style: TextStyle(
                        fontSize: min(size.width * 0.04, 16),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            )
          : ElevatedButton(
              onPressed: _isLoading ? null : _validateAndNavigate,
              style: ElevatedButton.styleFrom(
                backgroundColor: isLightMode
                    ? const Color(0xFF023A87)
                    : const Color.fromARGB(255, 162, 172, 185),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      lang.getOtp,
                      style: TextStyle(
                        fontSize: min(size.width * 0.04, 16),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
    );
  }

  Widget _buildRegisterLink(Size size, bool isLightMode) {
    var lang = AppLocalizations.of(context)!;
    return Container(
      margin: EdgeInsets.only(top: size.height * 0.04),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              lang.dontHaveAnAccount,
              style: TextStyle(
                color: isLightMode
                    ? const Color(0xFFA19D9D)
                    : AppColors.white.withOpacity(0.7),
                fontSize: min(size.width * 0.035, 14),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SignupScreen(),
                  ),
                );
              },
              child: Text(
                lang.register,
                style: TextStyle(
                  color: isLightMode
                      ? const Color(0xFF4285F4)
                      : AppColors.white.withOpacity(0.7),
                  fontSize: min(size.width * 0.035, 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
