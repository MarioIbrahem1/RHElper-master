import 'package:flutter/material.dart';
import 'package:road_helperr/ui/screens/otp_screen.dart';
import 'package:road_helperr/ui/screens/signin_screen.dart';
import 'package:road_helperr/utils/app_colors.dart';

class OtpExpiredScreen extends StatefulWidget {
  static const String routeName = "otpexpired";
  const OtpExpiredScreen({super.key});

  @override
  State<OtpExpiredScreen> createState() => _OtpExpiredScreenState();
}

class _OtpExpiredScreenState extends State<OtpExpiredScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final backgroundColor = AppColors.getBackgroundColor(context);
    final containerColor = AppColors.getCardColor(context);
    const warningColor = Colors.red; // أو زي ما تحب من AppColors
    final buttonMainColor = AppColors.getSignAndRegister(context);
    final textMainColor = isLight ? Colors.black : Colors.white;

    return LayoutBuilder(
      builder: (context, constraints) {
        final responsive = ResponsiveHelper(
          context: context,
          constraints: constraints,
        );

        return Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: _buildMainContent(
              responsive,
              containerColor,
              warningColor,
              buttonMainColor,
              textMainColor,
              isLight,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainContent(
    ResponsiveHelper responsive,
    Color containerColor,
    Color warningColor,
    Color buttonMainColor,
    Color textMainColor,
    bool isLight,
  ) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: responsive.maxContentWidth,
          ),
          padding: EdgeInsets.all(responsive.padding),
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.03),
                blurRadius: 12,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildWarningIcon(responsive, warningColor),
              SizedBox(height: responsive.spacing),
              _buildErrorMessage(responsive, textMainColor),
              SizedBox(height: responsive.largeSpacing),
              _buildRequestOtpButton(responsive, buttonMainColor),
              SizedBox(height: responsive.spacing),
              _buildBackToLoginButton(responsive, textMainColor, isLight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningIcon(ResponsiveHelper responsive, Color warningColor) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Icon(
        Icons.warning_amber_rounded,
        color: warningColor,
        size: responsive.iconSize,
      ),
    );
  }

  Widget _buildErrorMessage(ResponsiveHelper responsive, Color textMainColor) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Text(
        'The OTP has expired!',
        style: TextStyle(
          color: textMainColor,
          fontSize: responsive.titleSize,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildRequestOtpButton(
      ResponsiveHelper responsive, Color buttonMainColor) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SizedBox(
        width: double.infinity,
        height: responsive.buttonHeight,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonMainColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: responsive.buttonPadding,
          ),
          onPressed: () {
            Navigator.of(context).pushNamed(OtpScreen.routeName);
          },
          child: Text(
            'Request OTP',
            style: TextStyle(
              color: Colors.white,
              fontSize: responsive.buttonFontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackToLoginButton(
      ResponsiveHelper responsive, Color textMainColor, bool isLight) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SizedBox(
        width: double.infinity,
        height: responsive.buttonHeight,
        child: TextButton(
          onPressed: () {
            Navigator.of(context).pushNamed(SignInScreen.routeName);
          },
          style: TextButton.styleFrom(
            padding: responsive.buttonPadding,
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isLight
                    ? AppColors.getSignAndRegister(context)
                    : Colors.white54,
              ),
            ),
          ),
          child: Text(
            'Back to Login',
            style: TextStyle(
              color: isLight
                  ? AppColors.getSignAndRegister(context)
                  : Colors.white.withOpacity(0.8),
              fontSize: responsive.buttonFontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// Helper Classes زي ما عندك بالضبط (نقل الكود الحالي أو استخدمه كما هو)
class ResponsiveHelper {
  final BuildContext context;
  final BoxConstraints constraints;
  final Size size;

  ResponsiveHelper({
    required this.context,
    required this.constraints,
  }) : size = MediaQuery.of(context).size;

  bool get isTablet => constraints.maxWidth > 600;
  bool get isDesktop => constraints.maxWidth > 1200;

  double get iconSize =>
      size.width *
      (isDesktop
          ? 0.08
          : isTablet
              ? 0.12
              : 0.15);
  double get titleSize =>
      size.width *
      (isDesktop
          ? 0.025
          : isTablet
              ? 0.035
              : 0.05);
  double get buttonFontSize =>
      size.width *
      (isDesktop
          ? 0.015
          : isTablet
              ? 0.025
              : 0.04);
  double get buttonHeight =>
      size.height *
      (isDesktop
          ? 0.06
          : isTablet
              ? 0.07
              : 0.08);
  double get padding =>
      size.width *
      (isDesktop
          ? 0.03
          : isTablet
              ? 0.04
              : 0.05);
  double get spacing => size.height * 0.02;
  double get largeSpacing => size.height * 0.05;

  double get maxContentWidth => isDesktop
      ? 800
      : isTablet
          ? 600
          : double.infinity;
  double get buttonMaxWidth => isDesktop
      ? 400
      : isTablet
          ? 300
          : double.infinity;

  EdgeInsets get buttonPadding => EdgeInsets.symmetric(vertical: padding * 0.5);
}
