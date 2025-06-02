import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Helper class for Google Sign-In related functionality
class GoogleSignInHelper {
  /// Verifies the SHA-1 certificate fingerprint
  static Future<void> verifySHA1Certificate(BuildContext context) async {
    try {
      // Run the keytool command to get the SHA-1 hash
      final result = await _getSigningInfo();

      // Display the SHA-1 hash
      if (context.mounted) {
        _showSHA1Dialog(context, result);
      }
    } catch (e) {
      debugPrint('Error verifying SHA-1 certificate: $e');
      if (context.mounted) {
        _showErrorDialog(
            context, 'Error', 'Failed to verify SHA-1 certificate: $e');
      }
    }
  }

  /// Gets the signing information using platform channels
  static Future<String> _getSigningInfo() async {
    try {
      // Use platform channel to get the signing info from native code
      const platform = MethodChannel('com.example.road_helperr/signing_info');
      final String result = await platform.invokeMethod('getSigningInfo');
      return result;
    } catch (e) {
      // If platform channel fails, return a message with the SHA-1 from google-services.json
      return 'SHA-1 from google-services.json: 7A6AD445967CD4567FEBA3E6AECB01769375B6A3\n'
          'Note: This is the SHA-1 configured in Firebase, not necessarily the one used for signing this app build.';
    }
  }

  /// Shows a dialog with the SHA-1 hash
  static void _showSHA1Dialog(BuildContext context, String sha1Info) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SHA-1 Certificate Fingerprint'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This is the SHA-1 certificate fingerprint used for signing this app:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(sha1Info),
              const SizedBox(height: 16),
              const Text(
                'Make sure this SHA-1 is added to your Firebase project.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: sha1Info));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('SHA-1 copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Shows an error dialog
  static void _showErrorDialog(
      BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
