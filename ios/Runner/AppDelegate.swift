import Flutter
import UIKit
import GoogleMaps // 1. ADD THIS IMPORT

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // 2. ADD YOUR GOOGLE MAPS API KEY HERE
    GMSServices.provideAPIKey("AIzaSyD1zqr61LMbaROaCsUoGnJI73WJqdV14xo")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}