import 'package:flutter/material.dart';
import 'package:road_helperr/ui/widgets/custom_message_dialog.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static void showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onConfirm,
    String? confirmButtonText,
  }) {
    CustomMessageDialog.show(
      context: context,
      title: title,
      message: message,
      isError: false,
      onConfirm: onConfirm,
      confirmButtonText: confirmButtonText ?? "Continue",
    );
  }

  static void showError({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onConfirm,
    String? confirmButtonText,
  }) {
    CustomMessageDialog.show(
      context: context,
      title: title,
      message: message,
      isError: true,
      onConfirm: onConfirm,
      confirmButtonText: confirmButtonText ?? "Try Again",
    );
  }

  // Common success messages
  static void showPasswordResetSuccess(BuildContext context,
      {VoidCallback? onConfirm}) {
    var lang = AppLocalizations.of(context)!;
    showSuccess(
      context: context,
      title: lang.passwordResetSuccessful,
      message: lang.passwordResetSuccessful,
      onConfirm: onConfirm,
      confirmButtonText: lang.continueToLogin,
    );
  }

  static void showLoginSuccess(BuildContext context,
      {VoidCallback? onConfirm}) {
    var lang = AppLocalizations.of(context)!;
    showSuccess(
      context: context,
      title: lang.loginSuccessful,
      message: lang.loginSuccessful,
      onConfirm: onConfirm,
    );
  }

  static void showRegistrationSuccess(BuildContext context,
      {VoidCallback? onConfirm}) {
    var lang = AppLocalizations.of(context)!;
    showSuccess(
      context: context,
      title: lang.registrationSuccessful,
      message: lang.registrationSuccessful,
      onConfirm: onConfirm,
      confirmButtonText: lang.continueToLogin,
    );
  }

  // Common error messages
  static void showPasswordMismatch(BuildContext context) {
    var lang = AppLocalizations.of(context)!;
    showError(
      context: context,
      title: lang.passwordMismatch,
      message: lang.passwordMismatch,
    );
  }

  static void showInvalidCredentials(BuildContext context) {
    var lang = AppLocalizations.of(context)!;
    showError(
      context: context,
      title: lang.invalidCredentials,
      message: lang.invalidCredentials,
    );
  }

  static void showNetworkError(BuildContext context) {
    var lang = AppLocalizations.of(context)!;
    showError(
      context: context,
      title: lang.networkError,
      message: lang.networkError,
    );
  }

  static void showServerError(BuildContext context) {
    var lang = AppLocalizations.of(context)!;
    showError(
      context: context,
      title: lang.serverError,
      message: lang.serverError,
    );
  }

  static void showValidationError(BuildContext context, String message) {
    var lang = AppLocalizations.of(context)!;
    showError(
      context: context,
      title: lang.validationError,
      message: message,
    );
  }

  static void showGenericError(BuildContext context, String message) {
    var lang = AppLocalizations.of(context)!;
    showError(
      context: context,
      title: lang.error,
      message: message,
    );
  }
}
