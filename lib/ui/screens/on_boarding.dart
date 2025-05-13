import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'signin_screen.dart';
import 'signupScreen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OnBoarding extends StatefulWidget {
  static const String routeName = "onboarding";
  const OnBoarding({super.key});

  @override
  State<OnBoarding> createState() => _OnBoardingState();
}

class _OnBoardingState extends State<OnBoarding> {
  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationEnabled) {
      _showLocationDisabledMessage();
    } else {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          _showLocationDisabledMessage();
        }
      }
    }
  }

  void _showLocationDisabledMessage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Required'),
        content: const Text('Please enable location services to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var lang = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = MediaQuery.of(context).size;
        final isTablet = constraints.maxWidth > 600;
        final isDesktop = constraints.maxWidth > 1200;
        final responsive = _ResponsiveSize(size, isDesktop, isTablet);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            // استخدام خلفية شفافة لأننا نستخدم صورة كخلفية
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: OrientationBuilder(
              builder: (context, orientation) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        Theme.of(context).brightness == Brightness.light
                            ? "assets/images/first app background light.png"
                            : "assets/images/first app background dark.png",
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.white
                                  : const Color(0xFF01122A));
                        },
                      ),
                    ),
                    Scaffold(
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.light
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black.withOpacity(0.4),
                      body: SafeArea(
                        child: SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Center(
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: responsive.maxContentWidth,
                                ),
                                padding: responsive.contentPadding,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: EdgeInsets.only(
                                          top: responsive.spacing * 0.2),
                                      child: _AdaptiveImage(
                                        imagePath: Theme.of(context)
                                                    .brightness ==
                                                Brightness.light
                                            ? "assets/images/OnBoardingLight.png"
                                            : "assets/images/rafiki.png",
                                        width: responsive.imageWidth,
                                        height: responsive.imageHeight * 1.2,
                                      ),
                                    ),
                                    SizedBox(height: responsive.spacing),
                                    _AdaptiveText(
                                      text:
                                          lang.ifYouveGotTheTimeWeveGotTheShine,
                                      style: TextStyle(
                                        fontSize: responsive.titleSize,
                                        color: Theme.of(context).brightness ==
                                                Brightness.light
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: responsive.spacing),
                                    _AdaptiveText(
                                      text: lang
                                          .justTheProtectionYouAndYourCarNeedSpeakToUsForBestServices,
                                      style: TextStyle(
                                        fontSize: responsive.subtitleSize,
                                        color: Theme.of(context).brightness ==
                                                Brightness.light
                                            ? const Color(0xFF47609A)
                                            : const Color(0xFFD6D1D1),
                                        fontWeight: FontWeight.w400,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: responsive.spacing * 2),
                                    _AdaptiveButtonRow(
                                      buttonWidth: responsive.buttonWidth,
                                      buttonHeight: responsive.buttonHeight,
                                      spacing: responsive.spacing,
                                      onSignUpPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const SignupScreen()),
                                      ),
                                      onSignInPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const SignInScreen()),
                                      ),
                                    ),
                                    SizedBox(height: responsive.bottomSpacing),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// Helper classes for better organization and reusability
class _ResponsiveSize {
  final Size size;
  final bool isDesktop;
  final bool isTablet;

  _ResponsiveSize(this.size, this.isDesktop, this.isTablet);

  double get maxContentWidth => isDesktop ? 1200 : 800;

  EdgeInsets get contentPadding => EdgeInsets.symmetric(
        horizontal: size.width * 0.05,
        vertical: size.height * 0.02,
      );

  double get titleSize =>
      size.width *
      (isDesktop
          ? 0.025
          : isTablet
              ? 0.035
              : 0.08);
  double get subtitleSize => titleSize * 0.5;
  double get buttonWidth =>
      size.width *
      (isDesktop
          ? 0.25
          : isTablet
              ? 0.35
              : 0.48);
  double get buttonHeight =>
      size.height *
      (isDesktop
          ? 0.08
          : isTablet
              ? 0.09
              : 0.075);
  double get imageWidth =>
      size.width *
      (isDesktop
          ? 0.4
          : isTablet
              ? 0.5
              : 0.9);
  double get imageHeight => imageWidth * 0.7;
  double get spacing => size.height * 0.04;
  double get bottomSpacing => size.height * 0.08;
  double get buttonSpacing => size.width * 0.03;
}

class _AdaptiveImage extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;

  const _AdaptiveImage({
    required this.imagePath,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image,
                  color: Theme.of(context).colorScheme.error, size: 48),
              const SizedBox(height: 8),
              Text('Image not found',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ),
        );
      },
    );
  }
}

class _AdaptiveText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  const _AdaptiveText({
    required this.text,
    required this.style,
    required this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        textAlign: textAlign,
        style: style,
      ),
    );
  }
}

class _AdaptiveButtonRow extends StatelessWidget {
  final double buttonWidth;
  final double buttonHeight;
  final double spacing;
  final VoidCallback onSignUpPressed;
  final VoidCallback onSignInPressed;

  const _AdaptiveButtonRow({
    required this.buttonWidth,
    required this.buttonHeight,
    required this.spacing,
    required this.onSignUpPressed,
    required this.onSignInPressed,
  });

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    return Container(
      width: buttonWidth * 2.2,
      height: buttonHeight * 1.3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.transparent,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFFDAD8D8)
                        : Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: buttonHeight * 0.2),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(15),
                  ),
                ),
              ),
              onPressed: onSignUpPressed,
              child: Text(
                lang.signUp,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.black,
                  fontSize: buttonHeight * 0.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Theme.of(context).brightness == Brightness.light
                        ? Theme.of(context).colorScheme.primary
                        : const Color(0xFF01122A),
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: buttonHeight * 0.2),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(15),
                  ),
                ),
              ),
              onPressed: onSignInPressed,
              child: Text(
                lang.signIn,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: buttonHeight * 0.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
