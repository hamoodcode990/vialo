import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/player_profile.dart';
import '../state/profile_provider.dart';
import 'ads_service.dart';
import 'iap_products.dart';
import 'purchase_service.dart';
import 'reward_mapping.dart';

const String kLivesFullMessage = 'Your lives are already full';

final purchaseServiceProvider = Provider<PurchaseService>((ref) => PurchaseService());
final adsServiceProvider = Provider<AdsService>((ref) => AdsService());

/// Glues PurchaseService + AdsService to the profile, and is the *only*
/// thing the Store screen talks to — it never touches RevenueCat/AdMob or
/// ProfileController directly. Every method returns a short user-facing
/// message ('' means "nothing to say", e.g. a cancelled purchase) instead
/// of throwing, so the screen layer stays a thin `AppToast.show(await ...)`.
class MonetizationController {
  final PurchaseService purchases;
  final AdsService ads;
  final ProfileController profile;

  MonetizationController(this.purchases, this.ads, this.profile);

  bool get isStoreAvailable => purchases.isAvailable;

  /// Catches up regeneration first, so a life that came back while the Store
  /// was open still counts. Nothing that grants a life can be paid for, in
  /// money, coins or ad time, while this is true.
  bool _livesFull() {
    profile.regenLivesNow();
    return profile.currentProfile.lives >= PlayerProfile.lifeMax;
  }

  /// The Store's "Refill 1 life" row. Returns the message to show.
  String buyLifeWithCoins(int cost) {
    if (_livesFull()) return kLivesFullMessage;
    if (!profile.spendCoins(cost)) return 'Not enough coins';
    profile.addLives(1);
    return '+1 life';
  }

  Future<void> initialize() async {
    await purchases.initialize();
    await ads.initialize();
  }

  /// Attempts a real StoreKit purchase via RevenueCat. Falls back to
  /// decant.html's reference-implementation stub (instant-grant) when the
  /// store isn't configured yet (see MonetizationConfig) — that's what
  /// keeps this app testable without real store credentials.
  Future<String> purchase(String productId) async {
    if (productId == kProductRefillLives && _livesFull()) return kLivesFullMessage;
    if (!purchases.isAvailable) {
      profile.applyMutation((p) => applyProductPurchase(p, productId, profile.nowMs));
      return 'Purchase complete (demo mode — store not configured yet)';
    }

    final products = await purchases.fetchProducts([productId]);
    final product = products[productId];
    if (product == null) {
      return "This product isn't set up in App Store Connect yet.";
    }

    final result = await purchases.purchase(product);
    switch (result.outcome) {
      case PurchaseOutcome.success:
        profile.applyMutation((p) => applyProductPurchase(p, productId, profile.nowMs));
        return 'Purchase complete';
      case PurchaseOutcome.cancelled:
        return '';
      case PurchaseOutcome.failed:
        return 'Purchase failed: ${result.errorMessage}';
      case PurchaseOutcome.unavailable:
        return 'Store not configured';
    }
  }

  /// Shows a rewarded video for [placement] (+1 life or +25 coins). Falls
  /// back to a simulated-load stub only when there's no ad SDK at all
  /// (web/desktop dev environment) — if the SDK is available but a real ad
  /// just hasn't finished loading yet, this reports that instead of
  /// granting a free reward.
  Future<String> watchRewardedAd(String placement) async {
    if (placement == kAdPlacementLife && _livesFull()) return kLivesFullMessage;
    if (!ads.sdkAvailable) {
      await Future.delayed(const Duration(milliseconds: 1200));
      profile.applyMutation((p) => applyAdReward(p, placement));
      return placement == kAdPlacementLife ? '+1 life' : '+25 coins';
    }
    if (!ads.isReady) {
      return 'Ad not ready yet — try again in a moment.';
    }
    final earned = await ads.show();
    if (!earned) return '';
    profile.applyMutation((p) => applyAdReward(p, placement));
    return placement == kAdPlacementLife ? '+1 life' : '+25 coins';
  }
}

final monetizationControllerProvider = Provider<MonetizationController>((ref) {
  return MonetizationController(
    ref.watch(purchaseServiceProvider),
    ref.watch(adsServiceProvider),
    ref.watch(profileControllerProvider.notifier),
  );
});
