import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

enum SignInOutcome { success, cancelled, failed, unavailable }

class SignInResult {
  final SignInOutcome outcome;
  final String? userId;
  final String? errorMessage;

  const SignInResult._(this.outcome, this.userId, this.errorMessage);

  factory SignInResult.success(String userId) => SignInResult._(SignInOutcome.success, userId, null);
  factory SignInResult.cancelled() => const SignInResult._(SignInOutcome.cancelled, null, null);
  factory SignInResult.failed(String message) => SignInResult._(SignInOutcome.failed, null, message);
  factory SignInResult.unavailable() =>
      const SignInResult._(SignInOutcome.unavailable, null, 'Sign in with Apple is not available on this device');
}

/// Thin wrapper around the sign_in_with_apple plugin. Degrades to
/// [SignInOutcome.unavailable] rather than throwing on any platform where
/// it isn't supported (Android, web, older iOS, or this feature's own
/// build/dev target) — same contract as PurchaseService/AdsService.
class AppleSignInService {
  Future<bool> get isAvailable async {
    try {
      return await SignInWithApple.isAvailable();
    } catch (_) {
      return false;
    }
  }

  /// Requests only the stable user identifier — no name/email scope, since
  /// this app has no account system beyond "which device progress belongs
  /// together," consistent with the no-analytics, no-tracking posture.
  Future<SignInResult> signIn() async {
    try {
      if (!await isAvailable) return SignInResult.unavailable();
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [AppleIDAuthorizationScopes.email],
      );
      return SignInResult.success(credential.userIdentifier ?? '');
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return SignInResult.cancelled();
      return SignInResult.failed(e.message);
    } catch (e) {
      debugPrint('AppleSignInService.signIn failed: $e');
      return SignInResult.failed('Sign in failed');
    }
  }
}
