import Flutter
import UIKit
import UserNotifications
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // The app's own notifications (services/notifier.dart): a tap on one
    // reaches the app, which opens its thread.
    UNUserNotificationCenter.current().delegate = self
    // The background check for news (ui/notifications_background_io.dart),
    // which iOS runs when it decides: at least 15 minutes apart. The name is
    // in Info.plist's BGTaskSchedulerPermittedIdentifiers.
    WorkmanagerPlugin.registerPeriodicTask(withIdentifier: "murmur-news", earliestBeginInSeconds: NSNumber(value: 15 * 60))
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // The background check runs in an engine of its own, with the same plugins.
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
  }
}
