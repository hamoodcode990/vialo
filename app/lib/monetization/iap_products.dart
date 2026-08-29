/// The IAP catalog, ported verbatim from claude_code_economy_prompt.md §6 /
/// decant.html's `store()`. Product ids match what must be configured as
/// In-App Purchases in App Store Connect and mirrored in the RevenueCat
/// dashboard (see purchase_service.dart) — everything here is a one-time
/// purchase, no subscriptions, matching CLAUDE.md's monetization stance.
library;

const String kProductRefillLives = 'vialo_refill_lives';
const String kProductUnlimited2h = 'vialo_unlimited_lives_2h';
const String kProductUnlimited7d = 'vialo_unlimited_lives_7d';
const String kProductCoins500 = 'vialo_coins_500';
const String kProductCoins1200 = 'vialo_coins_1200';
const String kProductCoins3000 = 'vialo_coins_3000';
const String kProductRemoveAds = 'vialo_remove_ads';
const String kProductStarterPack = 'vialo_starter_pack';

/// The RevenueCat entitlement identifier backing [kProductRemoveAds] — the
/// only product in this catalog that's non-consumable and thus the only one
/// meaningful to reconcile via Restore Purchases (consumables have no
/// purchase history for StoreKit to restore).
const String kEntitlementNoAds = 'no_ads';

class IapProduct {
  final String id;
  final String title;
  final String subtitle;

  /// Display fallback shown before the real store price loads (or when the
  /// store isn't reachable/configured). The live price always comes from
  /// [PurchaseService] once available.
  final String fallbackPriceLabel;

  const IapProduct({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.fallbackPriceLabel,
  });
}

const List<IapProduct> kLivesProducts = [
  IapProduct(
    id: kProductRefillLives,
    title: 'Refill to 5 lives',
    subtitle: '',
    fallbackPriceLabel: '\$0.99',
  ),
  IapProduct(
    id: kProductUnlimited2h,
    title: 'Unlimited lives — 2 hours',
    subtitle: '',
    fallbackPriceLabel: '\$1.99',
  ),
  IapProduct(
    id: kProductUnlimited7d,
    title: 'Unlimited lives — 7 days',
    subtitle: '',
    fallbackPriceLabel: '\$6.99',
  ),
];

const List<IapProduct> kCoinProducts = [
  IapProduct(id: kProductCoins500, title: '500 coins', subtitle: '', fallbackPriceLabel: '\$1.99'),
  IapProduct(id: kProductCoins1200, title: '1200 coins', subtitle: '', fallbackPriceLabel: '\$3.99'),
  IapProduct(id: kProductCoins3000, title: '3000 coins', subtitle: '', fallbackPriceLabel: '\$7.99'),
];

const IapProduct kRemoveAdsProduct = IapProduct(
  id: kProductRemoveAds,
  title: 'Remove ads',
  subtitle: 'No interstitials, ever',
  fallbackPriceLabel: '\$2.99',
);

const IapProduct kStarterPackProduct = IapProduct(
  id: kProductStarterPack,
  title: 'Starter pack',
  subtitle: 'Unlimited lives 24h + 1,000 coins + a bottle skin',
  fallbackPriceLabel: '\$2.99',
);

const List<IapProduct> kAllProducts = [
  ...kLivesProducts,
  ...kCoinProducts,
  kRemoveAdsProduct,
  kStarterPackProduct,
];

/// Rewarded-video placements — AdMob doesn't have a "product id" concept for
/// these, just an ad unit; this id is purely how our own code tells
/// [applyAdReward] what to grant.
const String kAdPlacementLife = 'watch_ad_life';
const String kAdPlacementCoins = 'watch_ad_coins';
