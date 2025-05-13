import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const InfoCard({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    return LayoutBuilder(
      builder: (context, constraints) {
        final dimensions = _calculateDimensions(context, constraints);

        return (platform == TargetPlatform.iOS ||
                platform == TargetPlatform.macOS)
            ? _buildCupertinoCard(context, dimensions)
            : _buildMaterialCard(context, dimensions);
      },
    );
  }

  Widget _buildMaterialCard(BuildContext context, _CardDimensions dimensions) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: dimensions.horizontalMargin,
        vertical: dimensions.verticalMargin,
      ),
      color: isDark ? const Color(0xFF1F3551) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(dimensions.borderRadius),
      ),
      child: _buildCardContent(context, dimensions, isDark),
    );
  }

  Widget _buildCupertinoCard(BuildContext context, _CardDimensions dimensions) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: dimensions.horizontalMargin,
        vertical: dimensions.verticalMargin,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F3551) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(dimensions.borderRadius),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildCardContent(context, dimensions, isDark),
    );
  }

  Widget _buildCardContent(
      BuildContext context, _CardDimensions dimensions, bool isDark) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: dimensions.maxWidth,
        minWidth: dimensions.minWidth,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dimensions.horizontalPadding,
          vertical: dimensions.verticalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: dimensions.titleFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: dimensions.spacingHeight),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: dimensions.subtitleFontSize,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _CardDimensions _calculateDimensions(
      BuildContext context, BoxConstraints constraints) {
    final size = MediaQuery.of(context).size;

    double horizontalPadding = size.width * 0.1;
    double verticalPadding = size.height * 0.02;
    double titleFontSize = size.width * 0.04;
    double subtitleFontSize = size.width * 0.035;

    if (constraints.maxWidth > 600) {
      horizontalPadding = size.width * 0.08;
      titleFontSize = size.width * 0.03;
      subtitleFontSize = size.width * 0.025;
    }
    if (constraints.maxWidth > 1200) {
      horizontalPadding = size.width * 0.06;
      titleFontSize = size.width * 0.02;
      subtitleFontSize = size.width * 0.015;
    }

    titleFontSize = titleFontSize.clamp(16.0, 24.0);
    subtitleFontSize = subtitleFontSize.clamp(14.0, 20.0);

    return _CardDimensions(
      horizontalPadding: horizontalPadding,
      verticalPadding: verticalPadding,
      horizontalMargin: size.width * 0.05,
      verticalMargin: size.height * 0.01,
      titleFontSize: titleFontSize,
      subtitleFontSize: subtitleFontSize,
      borderRadius: size.width * 0.03,
      spacingHeight: size.height * 0.01,
      maxWidth: 800,
      minWidth: 200,
    );
  }
}

class _CardDimensions {
  final double horizontalPadding;
  final double verticalPadding;
  final double horizontalMargin;
  final double verticalMargin;
  final double titleFontSize;
  final double subtitleFontSize;
  final double borderRadius;
  final double spacingHeight;
  final double maxWidth;
  final double minWidth;

  _CardDimensions({
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.horizontalMargin,
    required this.verticalMargin,
    required this.titleFontSize,
    required this.subtitleFontSize,
    required this.borderRadius,
    required this.spacingHeight,
    required this.maxWidth,
    required this.minWidth,
  });
}
