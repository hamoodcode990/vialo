import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keychain-backed storage for the Apple refresh token obtained via
/// [AppleTokenRelayService.exchangeCodeForRefreshToken] — kept device-local
/// (never synced through CloudProfileSync's iCloud key-value store, and
/// deliberately not `synchronizable` in Keychain either) since it's only
/// ever needed on this device, to revoke on account deletion.
///
/// Only one Apple account can be linked at a time (mirrors
/// PlayerProfile.appleUserId being a single field), so this stores a single
/// value rather than one per user id.
class AppleRefreshTokenStore {
  static const _key = 'vialo_apple_refresh_token';
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> save(String refreshToken) async {
    try {
      await _storage.write(key: _key, value: refreshToken);
    } catch (e) {
      debugPrint('AppleRefreshTokenStore.save failed: $e');
    }
  }

  Future<String?> read() async {
    try {
      return await _storage.read(key: _key);
    } catch (e) {
      debugPrint('AppleRefreshTokenStore.read failed: $e');
      return null;
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (e) {
      debugPrint('AppleRefreshTokenStore.clear failed: $e');
    }
  }
}
