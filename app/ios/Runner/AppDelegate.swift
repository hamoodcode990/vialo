import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerCloudKVChannel(engineBridge.pluginRegistry)
  }

  // iCloud key-value store bridge for lib/account/cloud_profile_sync.dart
  // (CLAUDE.md Step 7's lightweight cross-device sync — NOT a full CloudKit
  // database, per the prompt's "do not build a full backend" steer). Needs
  // the iCloud > Key-value storage capability enabled in Xcode's Signing &
  // Capabilities before this does anything — see the note left in
  // ios/Runner/Runner.entitlements.
  private func registerCloudKVChannel(_ registry: FlutterPluginRegistry) {
    let registrar = registry.registrar(forPlugin: "VialoCloudKV")
    let channel = FlutterMethodChannel(name: "vialo/icloud_kv", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      let store = NSUbiquitousKeyValueStore.default
      guard let args = call.arguments as? [String: Any], let key = args["key"] as? String else {
        result(FlutterError(code: "bad_args", message: "missing key", details: nil))
        return
      }
      switch call.method {
      case "get":
        result(store.string(forKey: key))
      case "set":
        guard let value = args["value"] as? String else {
          result(FlutterError(code: "bad_args", message: "missing value", details: nil))
          return
        }
        store.set(value, forKey: key)
        store.synchronize()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
