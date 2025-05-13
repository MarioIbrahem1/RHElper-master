import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:road_helperr/ui/public_details/ai_button.dart';
import 'package:road_helperr/utils/app_colors.dart';
import 'package:road_helperr/utils/text_strings.dart';
import 'package:road_helperr/ui/screens/ai_chat.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AiWelcomeScreen extends StatelessWidget {
  static const String routeName = "aiwelcomescreen";
  const AiWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = MediaQuery.of(context).size;
        final isTablet = constraints.maxWidth > 600;
        final isDesktop = constraints.maxWidth > 1200;

        double titleSize = size.width *
            (isDesktop
                ? 0.035
                : isTablet
                    ? 0.045
                    : 0.055);
        double subtitleSize = titleSize * 0.7;
        double imageHeight = size.height *
            (isDesktop
                ? 0.6
                : isTablet
                    ? 0.5
                    : 0.4);
        double padding = size.width *
            (isDesktop
                ? 0.05
                : isTablet
                    ? 0.04
                    : 0.03);
        double spacing = size.height * 0.02;

        final bgColor = isDark
            ? const Color(0xFF01122A)
            : Colors.white; // Using white color for light mode

        return platform == TargetPlatform.iOS ||
                platform == TargetPlatform.macOS
            ? CupertinoPageScaffold(
                backgroundColor: bgColor,
                child: _buildContent(
                  context,
                  size,
                  titleSize,
                  subtitleSize,
                  imageHeight,
                  padding,
                  spacing,
                  isDesktop,
                  true,
                  isDark,
                ),
              )
            : Scaffold(
                backgroundColor: bgColor,
                body: _buildContent(
                  context,
                  size,
                  titleSize,
                  subtitleSize,
                  imageHeight,
                  padding,
                  spacing,
                  isDesktop,
                  false,
                  isDark,
                ),
              );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    Size size,
    double titleSize,
    double subtitleSize,
    double imageHeight,
    double padding,
    double spacing,
    bool isDesktop,
    bool isIOS,
    bool isDark,
  ) {
    final mainTextColor =
        isDark ? Colors.white : AppColors.getLabelTextField(context);
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    // Use bot.png in dark mode and white background in light mode
    String imageAsset;
    if (isDark) {
      imageAsset = 'assets/images/bot.png';
    } else {
      imageAsset =
          'assets/images/bot.png'; // Using the same image for light mode
    }

    return SafeArea(
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 1200 : 800,
          ),
          padding: EdgeInsets.all(padding),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxHeight: isDesktop ? 500 : 400,
                  ),
                  padding: EdgeInsets.only(bottom: spacing),
                  child: Image.asset(
                    imageAsset,
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: spacing * 1.5),
                Text(
                  AppLocalizations.of(context)?.providingTheBestAiSolutions ??
                      TextStrings.text1Ai,
                  maxLines: 2,
                  style: TextStyle(
                    color: mainTextColor,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w600,
                    fontFamily: isIOS ? '.SF Pro Text' : null,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: spacing),
                Padding(
                  padding: EdgeInsets.all(padding * 0.25),
                  child: Text(
                    AppLocalizations.of(context)?.readyToCheckCarRepairNeeds ??
                        TextStrings.text2Ai,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: subtitleSize,
                      fontFamily: isIOS ? '.SF Pro Text' : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: spacing * 3),
                _buildNavigationButton(context, isIOS),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButton(BuildContext context, bool isIOS) {
    return GestureDetector(
      onTap: () {
        if (isIOS) {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => const AiChat(),
            ),
          );
        } else {
          Navigator.pushNamed(context, AiChat.routeName);
        }
      },
      child: const AiButton(),
    );
  }
}
