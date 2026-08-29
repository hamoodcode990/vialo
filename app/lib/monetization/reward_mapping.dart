import '../profile/player_profile.dart';
import '../theme/cosmetics.dart' show kBackgroundSkins;
import 'iap_products.dart';

/// Pure application of a completed purchase or rewarded-ad view to a
/// profile — deliberately kept separate from purchase_service.dart /
/// ads_service.dart (which talk to RevenueCat/AdMob) so the actual *reward*
/// logic is unit-testable without either SDK. Mirrors decant.html's
/// stub IAP button handlers.
///
/// Mutates [p] in place; callers are responsible for committing the change
/// (see ProfileController.applyMutation).
void applyProductPurchase(PlayerProfile p, String productId, int nowMs) {
  switch (productId) {
    case kProductRefillLives:
      p.addLives(PlayerProfile.lifeMax);
    case kProductUnlimited2h:
      _grantUnlimitedLives(p, nowMs, const Duration(hours: 2));
    case kProductUnlimited7d:
      _grantUnlimitedLives(p, nowMs, const Duration(days: 7));
    case kProductCoins500:
      p.addCoins(500);
    case kProductCoins1200:
      p.addCoins(1200);
    case kProductCoins3000:
      p.addCoins(3000);
    case kProductRemoveAds:
      p.adsRemoved = true;
    case kProductStarterPack:
      _grantUnlimitedLives(p, nowMs, const Duration(hours: 24));
      p.addCoins(1000);
      p.starterUsed = true;
      final bonusSkin = kBackgroundSkins.length > 1 ? kBackgroundSkins[1].id : null;
      if (bonusSkin != null && !p.unlockedBackgrounds.contains(bonusSkin)) {
        p.unlockedBackgrounds.add(bonusSkin);
      }
    default:
      throw ArgumentError.value(productId, 'productId', 'unknown IAP product');
  }
}

/// Applies the [kEntitlementNoAds] entitlement found during a Restore
/// Purchases call. Consumables (lives/coins/starter pack) have no purchase
/// history for StoreKit to restore, so this is the only thing restore
/// meaningfully reconciles.
void applyRestoredEntitlements(PlayerProfile p, Set<String> activeEntitlements) {
  if (activeEntitlements.contains(kEntitlementNoAds)) {
    p.adsRemoved = true;
  }
}

/// Rewarded-video placements: +1 life or +25 coins, matching
/// claude_code_economy_prompt.md §4/§7.
void applyAdReward(PlayerProfile p, String placement) {
  switch (placement) {
    case kAdPlacementLife:
      p.addLives(1);
    case kAdPlacementCoins:
      p.addCoins(25);
    default:
      throw ArgumentError.value(placement, 'placement', 'unknown ad placement');
  }
}

void _grantUnlimitedLives(PlayerProfile p, int nowMs, Duration duration) {
  final until = nowMs + duration.inMilliseconds;
  if (until > p.tempLivesUntil) p.tempLivesUntil = until;
}
