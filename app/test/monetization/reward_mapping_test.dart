// Pure-logic tests for reward_mapping.dart — no Flutter, no RevenueCat/AdMob
// SDK. See purchase_service.dart/ads_service.dart for the (untestable in
// this sandbox, no real device) SDK-calling code these feed into.
import 'package:vialo/monetization/iap_products.dart';
import 'package:vialo/monetization/reward_mapping.dart';
import 'package:vialo/profile/player_profile.dart';
import 'package:test/test.dart';

void main() {
  group('applyProductPurchase', () {
    test('refill lives tops up to lifeMax without exceeding it', () {
      final p = PlayerProfile(lives: 2, livesUpdatedAt: 0);
      applyProductPurchase(p, kProductRefillLives, 0);
      expect(p.lives, PlayerProfile.lifeMax);
    });

    test('unlimited lives 2h sets tempLivesUntil 2h out', () {
      final p = PlayerProfile(livesUpdatedAt: 0);
      applyProductPurchase(p, kProductUnlimited2h, 1000);
      expect(p.tempLivesUntil, 1000 + 2 * 3600 * 1000);
    });

    test('unlimited lives 7d sets tempLivesUntil 7d out', () {
      final p = PlayerProfile(livesUpdatedAt: 0);
      applyProductPurchase(p, kProductUnlimited7d, 1000);
      expect(p.tempLivesUntil, 1000 + 7 * 24 * 3600 * 1000);
    });

    test('a shorter unlimited-lives grant never shortens an existing longer one', () {
      final p = PlayerProfile(livesUpdatedAt: 0);
      applyProductPurchase(p, kProductUnlimited7d, 0);
      final after7d = p.tempLivesUntil;
      applyProductPurchase(p, kProductUnlimited2h, 0);
      expect(p.tempLivesUntil, after7d, reason: 'buying the 2h pack after the 7d one should not shorten it');
    });

    test('coin packs add the exact advertised amount', () {
      final p = PlayerProfile(livesUpdatedAt: 0, coins: 0);
      applyProductPurchase(p, kProductCoins500, 0);
      expect(p.coins, 500);
      applyProductPurchase(p, kProductCoins1200, 0);
      expect(p.coins, 1700);
      applyProductPurchase(p, kProductCoins3000, 0);
      expect(p.coins, 4700);
    });

    test('remove ads sets adsRemoved', () {
      final p = PlayerProfile(livesUpdatedAt: 0);
      expect(p.adsRemoved, isFalse);
      applyProductPurchase(p, kProductRemoveAds, 0);
      expect(p.adsRemoved, isTrue);
    });

    test('starter pack grants unlimited-24h + 1000 coins + marks starterUsed', () {
      final p = PlayerProfile(livesUpdatedAt: 0, coins: 0);
      applyProductPurchase(p, kProductStarterPack, 5000);
      expect(p.tempLivesUntil, 5000 + 24 * 3600 * 1000);
      expect(p.coins, 1000);
      expect(p.starterUsed, isTrue);
    });

    test('an unknown product id throws rather than silently doing nothing', () {
      final p = PlayerProfile(livesUpdatedAt: 0);
      expect(() => applyProductPurchase(p, 'not_a_real_product', 0), throwsArgumentError);
    });
  });

  group('applyRestoredEntitlements', () {
    test('the no_ads entitlement sets adsRemoved', () {
      final p = PlayerProfile(livesUpdatedAt: 0);
      applyRestoredEntitlements(p, {kEntitlementNoAds});
      expect(p.adsRemoved, isTrue);
    });

    test('an empty entitlement set changes nothing', () {
      final p = PlayerProfile(livesUpdatedAt: 0);
      applyRestoredEntitlements(p, {});
      expect(p.adsRemoved, isFalse);
    });

    test('unrelated entitlements do not touch adsRemoved', () {
      final p = PlayerProfile(livesUpdatedAt: 0);
      applyRestoredEntitlements(p, {'some_other_entitlement'});
      expect(p.adsRemoved, isFalse);
    });
  });

  group('applyAdReward', () {
    test('the life placement grants exactly +1 life, capped at lifeMax', () {
      final p = PlayerProfile(lives: PlayerProfile.lifeMax, livesUpdatedAt: 0);
      applyAdReward(p, kAdPlacementLife);
      expect(p.lives, PlayerProfile.lifeMax);
      p.lives = 3;
      applyAdReward(p, kAdPlacementLife);
      expect(p.lives, 4);
    });

    test('the coins placement grants exactly +25 coins', () {
      final p = PlayerProfile(livesUpdatedAt: 0, coins: 10);
      applyAdReward(p, kAdPlacementCoins);
      expect(p.coins, 35);
    });

    test('an unknown placement throws', () {
      final p = PlayerProfile(livesUpdatedAt: 0);
      expect(() => applyAdReward(p, 'not_a_real_placement'), throwsArgumentError);
    });
  });
}
