import Flutter
import UIKit
import workmanager

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register plugins for background tasks
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    
    // Register the background processing task identifier
    WorkmanagerPlugin.registerBGProcessingTask(withIdentifier: "fetchUpcomingEventsTask")
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
