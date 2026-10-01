/// The IAP catalog, ported verbatim from claude_code_economy_prompt.md §6 /
/// decant.html's `store()`. Product ids match what must be configured as
/// In-App Purchases in App Store Connect and mirrored in the RevenueCat
/// dashboard (see purchase_service.dart) — everything here is a one-time
/// purchase, no subscriptions, matching CLAUDE.md's monetization stance.
library;

const String kProductRefillLives = 'com.sablastudio.vialo.lives.refill';
const String kProductUnlimited2h = 'com.sablastudio.vialo.lives.unlimited2h';
const String kProductCoins500 = 'com.sablastudio.vialo.coins.500';
const String kProductCoins1200 = 'com.sablastudio.vialo.coins.1200';
const String kProductCoins3000 = 'com.sablastudio.vialo.coins.3000';
const String kProductStarterPack = 'com.sablastudio.vialo.starterpack';

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
];

const List<IapProduct> kCoinProducts = [
  IapProduct(id: kProductCoins500, title: '500 coins', subtitle: '', fallbackPriceLabel: '\$1.99'),
  IapProduct(id: kProductCoins1200, title: '1200 coins', subtitle: '', fallbackPriceLabel: '\$3.99'),
  IapProduct(id: kProductCoins3000, title: '3000 coins', subtitle: '', fallbackPriceLabel: '\$7.99'),
];

const IapProduct kStarterPackProduct = IapProduct(
  id: kProductStarterPack,
  title: 'Starter pack',
  subtitle: 'Unlimited lives 24h + 1,000 coins + a bottle skin',
  fallbackPriceLabel: '\$2.99',
);

const List<IapProduct> kAllProducts = [
  ...kLivesProducts,
  ...kCoinProducts,
  kStarterPackProduct,
];

/// Rewarded-video placements — AdMob doesn't have a "product id" concept for
/// these, just an ad unit; this id is purely how our own code tells
/// [applyAdReward] what to grant.
const String kAdPlacementLife = 'watch_ad_life';
const String kAdPlacementCoins = 'watch_ad_coins';
