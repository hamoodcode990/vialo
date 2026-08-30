import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/player_profile.dart';
import '../state/profile_provider.dart';
import 'apple_sign_in_service.dart';
import 'cloud_profile_sync.dart';

final appleSignInServiceProvider = Provider<AppleSignInService>((ref) => AppleSignInService());
final cloudProfileSyncProvider = Provider<CloudProfileSync>((ref) => CloudProfileSync());

/// Result of [AccountController.signIn] once the Apple credential itself
/// succeeded: either progress was pushed straight to iCloud (first link, or
/// no meaningful remote data existed), or a different remote profile was
/// found and the caller must ask the player before overwriting anything —
/// CLAUDE.md Step 7's "do not silently overwrite local progress" rule.
sealed class LinkOutcome {
  const LinkOutcome();
}

class LinkSynced extends LinkOutcome {
  const LinkSynced();
}

class LinkNeedsRestoreChoice extends LinkOutcome {
  final PlayerProfile remote;
  const LinkNeedsRestoreChoice(this.remote);
}

class LinkFailed extends LinkOutcome {
  final String message;
  const LinkFailed(this.message);
}

/// Glues AppleSignInService + CloudProfileSync to the profile — the
/// Settings screen's only entry point for account linking, same role
/// MonetizationController plays for purchases/ads. Sign-in is entirely
/// optional and this class never mutates the profile in a way that could
/// lose local progress without the caller explicitly choosing to.
class AccountController {
  final AppleSignInService _signIn;
  final CloudProfileSync _cloud;
  final ProfileController _profile;

  AccountController(this._signIn, this._cloud, this._profile);

  Future<bool> get isAppleSignInAvailable => _signIn.isAvailable;

  String _cloudKey(String appleUserId) => 'vialo_profile_$appleUserId';

  /// Signs in, links the resulting Apple user id to the local profile, and
  /// either syncs local progress up (nothing worth restoring found) or asks
  /// the caller to resolve a restore choice (existing remote progress that
  /// differs from local — likely a different device signing into the same
  /// Apple ID). Never overwrites local data on its own.
  Future<LinkOutcome> signIn() async {
    final result = await _signIn.signIn();
    switch (result.outcome) {
      case SignInOutcome.unavailable:
        return LinkFailed(result.errorMessage!);
      case SignInOutcome.cancelled:
        return const LinkFailed('');
      case SignInOutcome.failed:
        return LinkFailed(result.errorMessage!);
      case SignInOutcome.success:
        break;
    }
    final appleUserId = result.userId!;
    _profile.linkAppleAccount(appleUserId);

    final remoteJson = await _cloud.getProfile(_cloudKey(appleUserId));
    if (remoteJson != null) {
      try {
        final remote = PlayerProfile.fromJson(jsonDecode(remoteJson) as Map<String, dynamic>);
        if (_looksLikeDifferentProgress(remote)) {
          return LinkNeedsRestoreChoice(remote);
        }
      } catch (_) {
        // Corrupt/old-shape remote blob — treat as "nothing to restore".
      }
    }
    await pushToCloud();
    return const LinkSynced();
  }

  /// A coarse "is this worth asking about" check — not byte-equality (the
  /// current profile always differs slightly, e.g. lives-regen timestamps)
  /// but a real difference in earned progress.
  bool _looksLikeDifferentProgress(PlayerProfile remote) {
    final local = _profile.currentProfile;
    final remoteStars = remote.stars.values.fold<int>(0, (a, m) => a + m.values.fold(0, (x, y) => x + y));
    final localStars = local.stars.values.fold<int>(0, (a, m) => a + m.values.fold(0, (x, y) => x + y));
    return remoteStars != localStars || remote.coins != local.coins || remote.name != local.name;
  }

  /// Overwrites local progress with [remote] — only ever called after the
  /// player has explicitly chosen "Restore" in response to
  /// [LinkNeedsRestoreChoice].
  void restoreFromCloud(PlayerProfile remote) {
    _profile.replaceProfile(remote);
  }

  /// Uploads current local progress to iCloud under the linked account's
  /// key. Exposed as an explicit "Sync now" action (Settings) rather than
  /// run silently on every change — keeps this lightweight-sync feature
  /// predictable rather than a background service to reason about.
  Future<bool> pushToCloud() async {
    final p = _profile.currentProfile;
    if (p.appleUserId == null) return false;
    return _cloud.setProfile(_cloudKey(p.appleUserId!), jsonEncode(p.toJson()));
  }

  void signOut() => _profile.unlinkAppleAccount();
}

final accountControllerProvider = Provider<AccountController>((ref) {
  return AccountController(
    ref.watch(appleSignInServiceProvider),
    ref.watch(cloudProfileSyncProvider),
    ref.watch(profileControllerProvider.notifier),
  );
});
