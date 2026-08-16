import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var nativeEngineBridge: OptimisticNativeEngineBridge?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    nativeEngineBridge = OptimisticNativeEngineBridge()
    let channel = FlutterMethodChannel(
      name: "optimistic_browser/native_engine",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.nativeEngineBridge?.handle(call, result: result) ?? result(FlutterError(code: "BRIDGE_UNAVAILABLE", message: "Native engine bridge unavailable", details: nil))
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
