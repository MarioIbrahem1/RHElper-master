import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:road_helperr/utils/message_utils.dart';

class CustomMessageDialog extends StatelessWidget {
  final String title;
  final String message;
  final bool isError;
  final VoidCallback? onConfirm;
  final String? confirmButtonText;

  const CustomMessageDialog({
    super.key,
    required this.title,
    required this.message,
    this.isError = false,
    this.onConfirm,
    this.confirmButtonText,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    bool isError = false,
    VoidCallback? onConfirm,
    String? confirmButtonText,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: CustomMessageDialog(
            title: title,
            message: message,
            isError: isError,
            onConfirm: onConfirm,
            confirmButtonText: confirmButtonText,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context);
    final errorColor = MessageUtils.getErrorColor(context);
    final successColor = MessageUtils.getSuccessColor(context);
    final backgroundColor = MessageUtils.getDialogBackgroundColor(context);
    final textColor = MessageUtils.getTextColor(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isError ? errorColor : successColor,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? errorColor : successColor,
              size: 50,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isError ? errorColor : successColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: textColor,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onConfirm?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isError ? errorColor : successColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    confirmButtonText ??
                        (isError
                            ? (lang?.tryAgain ?? 'Try Again')
                            : (lang?.continueText ?? 'Continue')),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
