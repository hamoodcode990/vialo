/// Monetization: RevenueCat (IAP) + AdMob (rewarded video only). For pure,
/// SDK-free unit tests, import iap_products.dart / reward_mapping.dart
/// directly instead of this barrel — it pulls in the RevenueCat/AdMob
/// plugins (and therefore package:flutter), same caveat as profile.dart
/// re-exporting profile_repository.dart. See Phase 3's lesson on this.
library;

export 'ads_service.dart';
export 'iap_products.dart';
export 'monetization_config.dart';
export 'monetization_controller.dart';
export 'purchase_service.dart';
export 'reward_mapping.dart';
