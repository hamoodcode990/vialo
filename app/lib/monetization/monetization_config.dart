/// Where the real store/ad account credentials go. Nothing in this repo can
/// exercise a real purchase or a real ad impression — that needs an Apple
/// Developer account with products configured in App Store Connect, a
/// RevenueCat project pointed at it, and a real AdMob account, none of
/// which exist here. Until [revenueCatApiKeyIOS] is replaced, the app runs
/// in "store not configured" mode: [PurchaseService.isAvailable] is false
/// and the Store screen falls back to the same instant-grant stub behaviour
/// decant.html's reference implementation already uses, so the app stays
/// fully testable without real credentials.
///
/// The AdMob values below are *not* placeholders — they're Google's own
/// published test identifiers, safe to ship in debug builds and meant to be
/// used exactly like this during development:
/// https://developers.google.com/admob/ios/test-ads
class MonetizationConfig {
  MonetizationConfig._();

  /// TODO(shipping): replace with the real RevenueCat public SDK key for
  /// this app (RevenueCat dashboard → Project Settings → API Keys → Apple
  /// App Store). Get the free account at https://app.revenuecat.com.
  static const String revenueCatApiKeyIOS = 'REVENUECAT_API_KEY_IOS_PLACEHOLDER';

  static bool get isRevenueCatConfigured =>
      revenueCatApiKeyIOS != 'REVENUECAT_API_KEY_IOS_PLACEHOLDER' && revenueCatApiKeyIOS.isNotEmpty;

  /// Google's published test rewarded-ad unit id (iOS). Swap for the real
  /// ad unit id from your AdMob account before release — see also the
  /// matching `GADApplicationIdentifier` in ios/Runner/Info.plist.
  static const String rewardedAdUnitIdIOS = 'ca-app-pub-3940256099942544/1712485313';
}
