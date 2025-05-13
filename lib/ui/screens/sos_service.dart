import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class SOSService {
  static List<String> emergencyContacts = [];

  // إضافة جهة اتصال طارئة
  static void addEmergencyContact(String contact) {
    emergencyContacts.add(contact);
  }

  // حذف جهة اتصال طارئة
  static void removeEmergencyContact(int index) {
    emergencyContacts.removeAt(index);
  }

  // إرسال SOS
  static Future<void> sendSOS() async {
    // الحصول على الموقع الحالي
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    String location =
        "https://maps.google.com/?q=${position.latitude},${position.longitude}";

    // الاتصال برقم الطوارئ
    const emergencyNumber = "tel:911";
    final Uri emergencyUri = Uri.parse(emergencyNumber);
    if (await canLaunchUrl(emergencyUri)) {
      await launchUrl(emergencyUri);
    }

    // إرسال رسائل SMS إلى جهات الاتصال الطارئة
    for (var contact in emergencyContacts) {
      String message = "SOS! الموقع الحالي: $location";
      String smsUrl = "sms:$contact?body=$message";
      final Uri smsUri = Uri.parse(smsUrl);
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      }
    }
  }
}
