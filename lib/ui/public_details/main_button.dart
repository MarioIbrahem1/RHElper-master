import 'package:flutter/material.dart';
import 'package:road_helperr/utils/app_colors.dart';

class MainButton extends StatelessWidget {
  final String textButton;
  final VoidCallback onPress;
  final bool isDisabled;

  const MainButton({
    super.key,
    required this.textButton,
    required this.onPress,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 250,
      height: 48,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPress,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled
              ? (isDarkMode
                  ? const Color(0xFF023A87).withOpacity(0.5)
                  : const Color(0xFF86A5D9).withOpacity(0.5))
              : (isDarkMode
                  ? const Color(0xFF023A87)
                  : const Color(0xFF86A5D9)),
          foregroundColor: isDisabled
              ? AppColors.getLabelTextField(context).withOpacity(0.7)
              : AppColors.getLabelTextField(context),
          disabledBackgroundColor: isDarkMode
              ? const Color(0xFF023A87).withOpacity(0.5)
              : const Color(0xFF86A5D9).withOpacity(0.5),
          disabledForegroundColor:
              AppColors.getLabelTextField(context).withOpacity(0.7),
        ),
        child: Text(
          textButton,
          style: TextStyle(
            color: isDisabled ? Colors.grey.shade300 : null,
          ),
        ),
      ),
    );
  }
}
