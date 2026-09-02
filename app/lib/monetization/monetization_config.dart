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

  /// RevenueCat's public SDK key (safe to embed client-side — it's scoped
  /// to submitting receipts/purchases for this app, not to the account's
  /// secret/server-side key, which never belongs in the repo).
  static const String revenueCatApiKeyIOS = 'appl_ecKlqDEaULwnldAUcSKxyYVTuOf';

  static bool get isRevenueCatConfigured =>
      revenueCatApiKeyIOS != 'REVENUECAT_API_KEY_IOS_PLACEHOLDER' && revenueCatApiKeyIOS.isNotEmpty;

  /// Google's published test rewarded-ad unit id (iOS). Swap for the real
  /// ad unit id from your AdMob account before release — see also the
  /// matching `GADApplicationIdentifier` in ios/Runner/Info.plist.
  static const String rewardedAdUnitIdIOS = 'ca-app-pub-3940256099942544/1712485313';
}
