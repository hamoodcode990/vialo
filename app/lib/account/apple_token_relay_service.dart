import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'apple_token_relay_config.dart';

/// Talks to the small serverless relay in tools/apple-revoke-worker/ that
/// holds the Sign in with Apple private key and performs the two calls
/// Apple requires to run server-side: exchanging a fresh authorization code
/// for a refresh token (right after sign-in, while the code is still valid),
/// and revoking that refresh token later (on account deletion).
///
/// Degrades to unavailable/best-effort-failed rather than throwing on any
/// network problem or when [appleTokenRelayBaseUrl] hasn't been configured
/// yet — same "unavailable rather than throw" contract as
/// PurchaseService/AdsService/CloudProfileSync, since a player must still be
/// able to delete their local + iCloud data even if this relay is
/// unreachable.
class AppleTokenRelayService {
  bool get isConfigured => !appleTokenRelayBaseUrl.contains('REPLACE-ME');

  /// Exchanges a just-received authorization code for a refresh token to
  /// store for later revocation. Must be called promptly after sign-in —
  /// Apple's authorization codes expire in minutes and are single-use.
  Future<String?> exchangeCodeForRefreshToken(String authorizationCode) async {
    if (!isConfigured) return null;
    try {
      final res = await http
          .post(
            Uri.parse('$appleTokenRelayBaseUrl/exchange'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({'code': authorizationCode}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['refresh_token'] as String?;
    } catch (e) {
      debugPrint('AppleTokenRelayService.exchangeCodeForRefreshToken failed: $e');
      return null;
    }
  }

  /// Revokes a previously-stored refresh token. Returns true only on a
  /// confirmed revoke — callers should still proceed with local/iCloud
  /// deletion on false, since a player's ability to delete their data can't
  /// depend on this relay being reachable.
  Future<bool> revokeRefreshToken(String refreshToken) async {
    if (!isConfigured) return false;
    try {
      final res = await http
          .post(
            Uri.parse('$appleTokenRelayBaseUrl/revoke'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('AppleTokenRelayService.revokeRefreshToken failed: $e');
      return false;
    }
  }
}
