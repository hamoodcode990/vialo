import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'monetization_config.dart';

/// Thin wrapper around AdMob rewarded video — the only ad format this app
/// uses (CLAUDE.md §7: rewarded video only, player-initiated, no
/// banners/interstitial spam). `google_mobile_ads` only has Android/iOS
/// platform implementations, so [initialize] no-ops safely everywhere else
/// (web/desktop) rather than throwing — that's how this gets exercised
/// during development in this repo, which has no mobile device attached.
class AdsService {
  RewardedAd? _ad;
  bool _sdkAvailable = false;
  bool _loading = false;

  /// Whether the AdMob SDK itself initialized (real device/platform, valid
  /// App ID). False on web/desktop, where this package has no
  /// implementation — that's the signal MonetizationController uses to
  /// decide whether "no ad ready" means "fall back to the dev stub" or
  /// "a real ad is just still loading, ask the player to try again."
  bool get sdkAvailable => _sdkAvailable;

  bool get isReady => _ad != null;

  Future<void> initialize() async {
    if (kIsWeb || !(defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android)) {
      _sdkAvailable = false;
      return;
    }
    try {
      await MobileAds.instance.initialize();
      _sdkAvailable = true;
      unawaited(_load());
    } catch (e) {
      _sdkAvailable = false;
      debugPrint('AdsService.initialize failed: $e');
    }
  }

  Future<void> _load() async {
    if (!_sdkAvailable || _loading || _ad != null) return;
    _loading = true;
    final completer = Completer<void>();
    await RewardedAd.load(
      adUnitId: MonetizationConfig.rewardedAdUnitIdIOS,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
          completer.complete();
        },
        onAdFailedToLoad: (error) {
          _ad = null;
          _loading = false;
          debugPrint('AdsService: rewarded ad failed to load: $error');
          completer.complete();
        },
      ),
    );
    return completer.future;
  }

  /// Shows the rewarded ad if one is ready; returns whether the reward was
  /// actually earned (the user watched to completion). Always
  /// pre-loads the next ad afterward.
  Future<bool> show() async {
    final ad = _ad;
    if (ad == null) return false;
    _ad = null;

    final rewardEarned = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        unawaited(_load());
      },
      onAdFailedToShowFullScreenContent: (a, error) {
        a.dispose();
        unawaited(_load());
        if (!rewardEarned.isCompleted) rewardEarned.complete(false);
      },
    );
    await ad.show(
      onUserEarnedReward: (ad, reward) {
        if (!rewardEarned.isCompleted) rewardEarned.complete(true);
      },
    );
    return rewardEarned.future;
  }
}
