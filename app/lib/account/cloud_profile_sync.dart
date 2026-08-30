import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Thin wrapper around a native NSUbiquitousKeyValueStore (iCloud
/// key-value storage) bridge — CLAUDE.md Step 7's cross-device sync,
/// deliberately the lightest thing that could work rather than a full
/// CloudKit database, per the prompt's "do not build a full backend"
/// steer. The native side lives in ios/Runner/AppDelegate.swift.
///
/// Every method degrades to a no-op/null on any failure — no iCloud
/// entitlement configured yet, signed out of iCloud, Android, web, or the
/// Windows/Chrome dev target used to build this feature — mirroring
/// PurchaseService/AdsService's "unavailable rather than throw" contract.
/// A player who never touches this (or whose device can't reach iCloud)
/// stays fully playable on local-only progress, per the prompt's
/// "sign-in must be optional" requirement.
class CloudProfileSync {
  static const _channel = MethodChannel('vialo/icloud_kv');

  Future<String?> getProfile(String key) async {
    try {
      final result = await _channel.invokeMethod<String>('get', {'key': key});
      return result;
    } catch (e) {
      debugPrint('CloudProfileSync.getProfile unavailable: $e');
      return null;
    }
  }

  Future<bool> setProfile(String key, String json) async {
    try {
      await _channel.invokeMethod<void>('set', {'key': key, 'value': json});
      return true;
    } catch (e) {
      debugPrint('CloudProfileSync.setProfile unavailable: $e');
      return false;
    }
  }
}
