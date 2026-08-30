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
    registerCloudKVChannel(engineBridge.applicationRegistrar.messenger())
  }

  // iCloud key-value store bridge for lib/account/cloud_profile_sync.dart
  // (CLAUDE.md Step 7's lightweight cross-device sync — NOT a full CloudKit
  // database, per the prompt's "do not build a full backend" steer). Needs
  // the iCloud > Key-value storage capability enabled in Xcode's Signing &
  // Capabilities before this does anything — see the note left in
  // ios/Runner/Runner.entitlements.
  //
  // Verified against the engine's FlutterImplicitEngineBridge declaration
  // and Flutter's own ios_add2app_uiscene sample (both found in this
  // machine's Flutter SDK checkout under dev/integration_tests/) —
  // `applicationRegistrar.messenger()` is the documented way to get an
  // app-level FlutterBinaryMessenger from this bridge type, an earlier
  // draft of this code used the wrong call (registry.registrar(forPlugin:))
  // before those files were found.
  private func registerCloudKVChannel(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "vialo/icloud_kv", binaryMessenger: messenger)
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
