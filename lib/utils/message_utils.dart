import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:road_helperr/utils/app_colors.dart';

/// A utility class for handling messages in the app.
/// This class provides methods for getting localized messages and theme-aware styling.
class MessageUtils {
  /// Get a localized message from the app's localization system.
  /// If the message is not found in the localization system, the fallback message is returned.
  static String getLocalizedMessage(
    BuildContext context,
    String messageKey,
    String fallbackMessage,
  ) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return fallbackMessage;

    // Try to access the message directly using a switch statement
    // This is safer than using reflection
    try {
      switch (messageKey) {
        case 'help':
          return localizations.help;
        case 'helpRequest':
          return localizations.helpRequest;
        case 'accept':
          return localizations.accept;
        case 'decline':
          return localizations.decline;
        case 'updateAvailable':
          return localizations.updateAvailable;
        case 'newNotification':
          return localizations.newNotification;
        case 'tryAgain':
          return localizations.tryAgain;
        case 'continueText':
          return localizations.continueText;
        case 'ok':
          return localizations.ok;
        default:
          return fallbackMessage;
      }
    } catch (e) {
      return fallbackMessage;
    }
  }

  /// Get the primary color for messages based on the current theme.
  static Color getPrimaryMessageColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? AppColors.getSwitchColor(context)
        : AppColors.getAiElevatedButton(context);
  }

  /// Get the error color for messages based on the current theme.
  static Color getErrorColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.red
        : Colors.redAccent;
  }

  /// Get the success color for messages based on the current theme.
  static Color getSuccessColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.green
        : Colors.greenAccent;
  }

  /// Get the text color for messages based on the current theme.
  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.black87
        : Colors.white;
  }

  /// Get the background color for message dialogs based on the current theme.
  static Color getDialogBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.white
        : AppColors.getBackgroundColor(context);
  }

  /// Common notification messages
  static String getHelpRequestTitle(BuildContext context) {
    return AppLocalizations.of(context)?.help ?? 'Help Request';
  }

  static String getHelpRequestBody(BuildContext context, String senderName) {
    const template = 'You received a help request from {name}';
    return template.replaceAll('{name}', senderName);
  }

  static String getUpdateAvailableTitle(BuildContext context) {
    return AppLocalizations.of(context)?.updateAvailable ?? 'Update Available';
  }

  static String getUpdateAvailableBody(BuildContext context, String version) {
    const template = 'Version {version} is now available. Tap to update.';
    return template.replaceAll('{version}', version);
  }

  static String getNewNotificationTitle(BuildContext context) {
    return AppLocalizations.of(context)?.newNotification ?? 'New Notification';
  }

  /// Common error messages
  static String getNetworkErrorMessage(BuildContext context) {
    return AppLocalizations.of(context)?.networkError ??
        'Please check your internet connection and try again';
  }

  static String getServerErrorMessage(BuildContext context) {
    return AppLocalizations.of(context)?.serverError ??
        'Something went wrong with the server. Please try again later';
  }

  static String getInvalidCredentialsMessage(BuildContext context) {
    return AppLocalizations.of(context)?.invalidCredentials ??
        'The email or password you entered is incorrect. Please try again';
  }

  static String getPasswordMismatchMessage(BuildContext context) {
    return AppLocalizations.of(context)?.passwordMismatch ??
        'The passwords you entered do not match. Please try again';
  }

  /// Common button texts
  static String getContinueButtonText(BuildContext context) {
    return AppLocalizations.of(context)?.continueText ?? 'Continue';
  }

  static String getTryAgainButtonText(BuildContext context) {
    return AppLocalizations.of(context)?.tryAgain ?? 'Try Again';
  }

  static String getOkButtonText(BuildContext context) {
    return AppLocalizations.of(context)?.ok ?? 'OK';
  }

  static String getAcceptButtonText(BuildContext context) {
    return AppLocalizations.of(context)?.accept ?? 'Accept';
  }

  static String getDeclineButtonText(BuildContext context) {
    return AppLocalizations.of(context)?.decline ?? 'Decline';
  }
}
