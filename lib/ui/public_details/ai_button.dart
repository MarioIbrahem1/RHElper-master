import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:gradient_slide_to_act/gradient_slide_to_act.dart';
import 'package:road_helperr/ui/screens/ai_chat.dart';
import 'package:road_helperr/utils/app_colors.dart';
import 'package:road_helperr/utils/text_strings.dart';
import 'package:road_helperr/utils/responsive_helper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AiButton extends StatefulWidget {
  const AiButton({super.key});

  @override
  State<AiButton> createState() => _AiButtonState();
}

class _AiButtonState extends State<AiButton>
    with SingleTickerProviderStateMixin {
  // Track drag position
  double _dragPosition = 0;
  final double _dragThreshold = 0.7; // Threshold to trigger action (70% of width)
  bool _isSubmitted = false;
  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);

    // Get platform & screen size
    final platform = Theme.of(context).platform;
    final screenSize = MediaQuery.of(context).size;

    return LayoutBuilder(
      builder: (context, constraints) {
        final dimensions = _calculateDimensions(screenSize, constraints);

        return Center(
          child: Container(
            constraints: _getAdaptiveConstraints(platform),
            width: dimensions.width,
            height: dimensions.height,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: dimensions.width,
                height: dimensions.height,
                child: _buildAdaptiveSlider(
                  context,
                  platform,
                  dimensions,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Dynamic sizing
  _Dimensions _calculateDimensions(
      Size screenSize, BoxConstraints constraints) {
    double width = screenSize.width * 0.85;
    double height = screenSize.height * 0.08;
    double fontSize = screenSize.width * 0.045;

    if (constraints.maxWidth > 600) {
      width = screenSize.width * 0.6;
      height = screenSize.height * 0.07;
      fontSize = screenSize.width * 0.035;
    }
    if (constraints.maxWidth > 1200) {
      width = screenSize.width * 0.4;
      height = screenSize.height * 0.06;
      fontSize = screenSize.width * 0.025;
    }
    return _Dimensions(width, height, fontSize);
  }

  BoxConstraints _getAdaptiveConstraints(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return const BoxConstraints(
          maxWidth: 500,
          minWidth: 200,
          maxHeight: 70,
          minHeight: 45,
        );
      case TargetPlatform.windows:
        return const BoxConstraints(
          maxWidth: 600,
          minWidth: 250,
          maxHeight: 80,
          minHeight: 50,
        );
      default:
        return const BoxConstraints(
          maxWidth: 600,
          minWidth: 200,
          maxHeight: 80,
          minHeight: 50,
        );
    }
  }

  Widget _buildAdaptiveSlider(
    BuildContext context,
    TargetPlatform platform,
    _Dimensions dimensions,
  ) {
    // أفضل gradient للألوان بالاعتماد على AppColors
    final List<Color> gradientColors = [
      Colors.blue.shade300,
      Colors.blue.shade400,
      AppColors.getAiElevatedButton(context),
      AppColors.getAiElevatedButton(context),
    ];

    final Color backgroundColor =
        Theme.of(context).brightness == Brightness.light
            ? AppColors.getAiElevatedButton2(context).withOpacity(0.9)
            : const Color(0xFF2E3B55).withOpacity(0.9);

    final lang = AppLocalizations.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    if (isRtl) {
      // For RTL, create a custom slider with the button on the right side
      return Container(
        width: dimensions.width,
        height: dimensions.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: backgroundColor,
        ),
        child: Stack(
          children: [
            // Gradient background that fills based on drag position
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Stack(
                children: [
                  // Background color
                  Container(
                    width: dimensions.width,
                    height: dimensions.height,
                    color: backgroundColor,
                  ),
                  // Gradient overlay that shows based on drag position
                  Positioned(
                    right: 0, // Start from right for RTL
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 50),
                      width: dimensions.width *
                          (1 - _dragPosition), // Shrink from right
                      height: dimensions.height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: gradientColors,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Text in the center
            Center(
              child: Text(
                lang?.getStarted ?? TextStrings.getStarted,
                style: _getAdaptiveTextStyle(
                    context, platform, dimensions.fontSize),
              ),
            ),
            // Draggable button on the right side
            Positioned(
              right: _isSubmitted
                  ? 0
                  : (dimensions.width - dimensions.height) * _dragPosition,
              child: GestureDetector(
                onTap: () {
                  if (!_isSubmitted) {
                    _submitForm(context, platform);
                  }
                },
                onHorizontalDragStart: (_) {
                  setState(() {
                    _dragPosition = 0;
                    _isSubmitted = false;
                  });
                },
                onHorizontalDragEnd: (_) {
                  if (_dragPosition >= _dragThreshold && !_isSubmitted) {
                    _submitForm(context, platform);
                  } else {
                    setState(() {
                      _dragPosition = 0;
                    });
                  }
                },
                onHorizontalDragUpdate: (details) {
                  if (!_isSubmitted) {
                    setState(() {
                      // Calculate drag position as percentage of width
                      // For RTL, we need to invert the calculation
                      _dragPosition += (-details.delta.dx) /
                          (dimensions.width - dimensions.height);
                      _dragPosition = _dragPosition.clamp(0.0, 1.0);

                      // If we've dragged past the threshold, submit
                      if (_dragPosition >= _dragThreshold) {
                        _submitForm(context, platform);
                      }
                    });
                  }
                },
                child: Container(
                  height: dimensions.height,
                  width: dimensions.height, // Make it square
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isSubmitted ? gradientColors.last : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _isSubmitted ? Icons.check : Icons.arrow_forward_ios,
                      color: _isSubmitted ? Colors.white : gradientColors.last,
                      size: dimensions.fontSize * 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // For LTR, use the normal widget
      return GradientSlideToAct(
        text: lang?.getStarted ?? TextStrings.getStarted,
        sliderButtonIcon: _getPlatformIcon(platform),
        textStyle:
            _getAdaptiveTextStyle(context, platform, dimensions.fontSize),
        backgroundColor: backgroundColor,
        width: dimensions.width,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        onSubmit: () {
          _navigateToAiChat(context, platform);
          debugPrint("Submitted in LTR mode!");
        },
        dragableIcon: Icons.arrow_forward_ios,
      );
    }
  }

  TextStyle _getAdaptiveTextStyle(
      BuildContext context, TargetPlatform platform, double fontSize) {
    switch (platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          fontFamily: '.SF Pro Text',
        );
      case TargetPlatform.windows:
        return TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          fontFamily: 'Segoe UI',
        );
      default:
        return TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        );
    }
  }

  IconData _getPlatformIcon(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return CupertinoIcons.chat_bubble_fill;
      default:
        return Icons.insert_comment_sharp;
    }
  }

  void _submitForm(BuildContext context, TargetPlatform platform) {
    setState(() {
      _isSubmitted = true;
      _dragPosition = 1.0;
    });

    // Navigate after a short delay to show the completed animation
    Future.delayed(const Duration(milliseconds: 300), () {
      _navigateToAiChat(context, platform);
    });
  }

  void _navigateToAiChat(BuildContext context, TargetPlatform platform) {
    Navigator.push(
      context,
      platform == TargetPlatform.iOS || platform == TargetPlatform.macOS
          ? CupertinoPageRoute(builder: (context) => const AiChat())
          : MaterialPageRoute(builder: (context) => const AiChat()),
    );
  }
}

// Helper class for dynamic sizing
class _Dimensions {
  final double width;
  final double height;
  final double fontSize;

  _Dimensions(this.width, this.height, this.fontSize);
}
