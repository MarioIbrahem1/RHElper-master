import UIKit
import Flutter
import GoogleMaps // تأكد من استيراد حزمة GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // إضافة API Key هنا
    GMSServices.provideAPIKey("AIzaSyDrP9YA-D4xFrLi-v1klPXvtoEuww6kmBo")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}