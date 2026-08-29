import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

import 'iap_products.dart';
import 'monetization_config.dart';

enum PurchaseOutcome { success, cancelled, failed, unavailable }

class PurchaseResult {
  final PurchaseOutcome outcome;
  final CustomerInfo? customerInfo;
  final String? errorMessage;

  const PurchaseResult._(this.outcome, this.customerInfo, this.errorMessage);

  factory PurchaseResult.success(CustomerInfo info) => PurchaseResult._(PurchaseOutcome.success, info, null);
  factory PurchaseResult.cancelled() => const PurchaseResult._(PurchaseOutcome.cancelled, null, null);
  factory PurchaseResult.failed(String message) => PurchaseResult._(PurchaseOutcome.failed, null, message);
  factory PurchaseResult.unavailable() =>
      const PurchaseResult._(PurchaseOutcome.unavailable, null, 'Store not configured');

  bool get isSuccess => outcome == PurchaseOutcome.success;
}

/// Thin wrapper around the RevenueCat SDK. Every public method is safe to
/// call even when RevenueCat hasn't been configured (see
/// MonetizationConfig) — they just report [PurchaseOutcome.unavailable]
/// instead of throwing, so callers (MonetizationController) don't need to
/// know whether a real store is behind this.
class PurchaseService {
  bool _configured = false;
  bool get isAvailable => _configured;

  Future<void> initialize() async {
    if (!MonetizationConfig.isRevenueCatConfigured) {
      _configured = false;
      return;
    }
    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
      await Purchases.configure(
        PurchasesConfiguration(MonetizationConfig.revenueCatApiKeyIOS),
      );
      _configured = true;
    } catch (e) {
      // A bad key, no network at first launch, simulator quirks, etc. —
      // degrade to unavailable rather than crash app startup.
      _configured = false;
      debugPrint('PurchaseService.initialize failed: $e');
    }
  }

  /// Fetches live StoreKit products for the given ids. Returns an empty map
  /// (never throws) if unavailable or the products aren't configured yet in
  /// App Store Connect.
  Future<Map<String, StoreProduct>> fetchProducts(List<String> productIds) async {
    if (!_configured) return {};
    try {
      final products = await Purchases.getProducts(productIds);
      return {for (final p in products) p.identifier: p};
    } catch (e) {
      debugPrint('PurchaseService.fetchProducts failed: $e');
      return {};
    }
  }

  Future<PurchaseResult> purchase(StoreProduct product) async {
    if (!_configured) return PurchaseResult.unavailable();
    try {
      final result = await Purchases.purchase(PurchaseParams.storeProduct(product));
      return PurchaseResult.success(result.customerInfo);
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseResult.cancelled();
      }
      return PurchaseResult.failed(e.message ?? code.name);
    } catch (e) {
      return PurchaseResult.failed('$e');
    }
  }

  /// Restores prior non-consumable purchases (only [kProductRemoveAds] in
  /// this catalog — consumables have no StoreKit purchase history to
  /// restore, by design).
  Future<PurchaseResult> restore() async {
    if (!_configured) return PurchaseResult.unavailable();
    try {
      final info = await Purchases.restorePurchases();
      return PurchaseResult.success(info);
    } catch (e) {
      return PurchaseResult.failed('$e');
    }
  }
}
