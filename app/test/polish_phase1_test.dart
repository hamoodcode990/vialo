// Vialo 1.0.1 Phase 1 bug fixes.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vialo/game/level_curves.dart';
import 'package:vialo/main.dart';
import 'package:vialo/monetization/ads_service.dart';
import 'package:vialo/monetization/iap_products.dart';
import 'package:vialo/monetization/monetization_controller.dart';
import 'package:vialo/monetization/purchase_service.dart';
import 'package:vialo/screens/duel_tube_game_screen.dart';
import 'package:vialo/screens/profile_screen.dart';
import 'package:vialo/screens/store_screen.dart';
import 'package:vialo/state/profile_provider.dart';
import 'package:vialo/widgets/app_toast.dart';

class _FakePurchases extends PurchaseService {
  int fetches = 0;
  @override
  bool get isAvailable => true;
  @override
  Future<Map<String, StoreProduct>> fetchProducts(List<String> productIds) async {
    fetches++;
    return {};
  }
}

class _FakeAds extends AdsService {
  int shows = 0;
  @override
  bool get sdkAvailable => true;
  @override
  bool get isReady => true;
  @override
  Future<bool> show() async {
    shows++;
    return true;
  }
}

void _seed(int lives) {
  SharedPreferences.setMockInitialValues({
    'vialo_profile_v1':
        '{"onboarded":true,"lives":$lives,"livesUpdatedAt":${DateTime.now().millisecondsSinceEpoch},"coins":100}',
  });
}

Future<(ProviderContainer, _FakePurchases, _FakeAds)> _setup(int lives) async {
  _seed(lives);
  final purchases = _FakePurchases();
  final ads = _FakeAds();
  final c = ProviderContainer(overrides: [
    purchaseServiceProvider.overrideWithValue(purchases),
    adsServiceProvider.overrideWithValue(ads),
  ]);
  addTearDown(c.dispose);
  await c.read(profileControllerProvider.future);
  return (c, purchases, ads);
}

Future<void> _pumpScreen(WidgetTester tester, Widget screen, int lives) async {
  _seed(lives);
  tester.view.physicalSize = const Size(1170, 5000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(child: MaterialApp(home: screen)));
  await tester.pump();
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1.1 level count', () {
    test('Solo has one total', () => expect(kLevelCounts['solo'], kSoloLevelCount));

    testWidgets('Profile reads it', (tester) async {
      await _pumpScreen(tester, const ProfileScreen(), 5);
      expect(find.text('0/$kSoloLevelCount'), findsOneWidget);
      expect(find.textContaining('/300'), findsNothing);
    });
  });

  group('1.2 toast', () {
    test('no default SnackBars are left in lib/', () {
      final hits = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart') && f.readAsStringSync().contains('SnackBar('))
          .map((f) => f.path)
          .toList();
      expect(hits, isEmpty);
    });

    testWidgets('shows, then expires after about 1.8s', (tester) async {
      await tester.pumpWidget(MaterialApp(builder: (_, c) => AppToastHost(child: c!), home: const Scaffold()));
      AppToast.show('hello');
      await tester.pump();
      expect(find.text('hello'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('hello'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 850));
      await tester.pump();
      expect(find.text('hello'), findsNothing);
    });

    testWidgets('is cleared by navigation', (tester) async {
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(MaterialApp(
        navigatorKey: nav,
        navigatorObservers: [AppToastObserver()],
        builder: (_, c) => AppToastHost(child: c!),
        home: const Scaffold(),
      ));
      AppToast.show('stay behind');
      await tester.pump();
      nav.currentState!.push(MaterialPageRoute(builder: (_) => const Scaffold()));
      await tester.pump();
      expect(find.text('stay behind'), findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('sits below the app bar, clear of the bottom half', (tester) async {
      SharedPreferences.setMockInitialValues({'vialo_profile_v1': '{"onboarded":true}'});
      await tester.pumpWidget(const ProviderScope(child: VialoApp()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2600));
      AppToast.show('where am I');
      await tester.pump();
      final y = tester.getCenter(find.text('where am I')).dy;
      expect(y, greaterThan(kToolbarHeight));
      expect(y, lessThan(tester.view.physicalSize.height / tester.view.devicePixelRatio / 2));
    });
  });

  group('1.3 labels', () {
    test('pass & play is P1/P2, vs bot is YOU/BOT', () {
      expect(playerLabel(0, vsBot: false), 'P1');
      expect(playerLabel(1, vsBot: false), 'P2');
      expect(playerLabel(0, vsBot: true), 'YOU');
      expect(playerLabel(1, vsBot: true), 'BOT');
    });

    testWidgets('a pass & play Split board never says YOU or THEM', (tester) async {
      await _pumpScreen(tester, const DuelTubeGameScreen(kind: 'split', mode: 'pass'), 5);
      await tester.pumpAndSettle();
      expect(find.text('YOU'), findsNothing);
      expect(find.text('THEM'), findsNothing);
      expect(find.text('P1').evaluate().length + find.text('P2').evaluate().length, greaterThan(0));
    });
  });

  group('1.5 store at full lives', () {
    test('no purchase can start for the refill', () async {
      final (c, purchases, _) = await _setup(5);
      final msg = await c.read(monetizationControllerProvider).purchase(kProductRefillLives);
      expect(msg, kLivesFullMessage);
      expect(purchases.fetches, 0);
    });

    test('the refill still works below full', () async {
      final (c, purchases, _) = await _setup(3);
      await c.read(monetizationControllerProvider).purchase(kProductRefillLives);
      expect(purchases.fetches, 1);
    });

    test('unlimited lives stays purchasable at full', () async {
      final (c, purchases, _) = await _setup(5);
      await c.read(monetizationControllerProvider).purchase(kProductUnlimited2h);
      expect(purchases.fetches, 1);
    });

    test('no life ad can start at full, but the coin ad can', () async {
      final (c, _, ads) = await _setup(5);
      final m = c.read(monetizationControllerProvider);
      expect(await m.watchRewardedAd(kAdPlacementLife), kLivesFullMessage);
      expect(ads.shows, 0);
      await m.watchRewardedAd(kAdPlacementCoins);
      expect(ads.shows, 1);
    });

    test('the life ad works below full', () async {
      final (c, _, ads) = await _setup(4);
      await c.read(monetizationControllerProvider).watchRewardedAd(kAdPlacementLife);
      expect(ads.shows, 1);
      expect(c.read(profileProvider).lives, 5);
    });

    test('the coin refill takes no coins at full', () async {
      final (c, _, _) = await _setup(5);
      expect(c.read(monetizationControllerProvider).buyLifeWithCoins(75), kLivesFullMessage);
      expect(c.read(profileProvider).coins, 100);
    });

    test('the coin refill works below full, at the same price', () async {
      final (c, _, _) = await _setup(2);
      expect(c.read(monetizationControllerProvider).buyLifeWithCoins(75), '+1 life');
      expect(c.read(profileProvider).coins, 25);
      expect(c.read(profileProvider).lives, 3);
    });

    testWidgets('rows show Full / Lives full at 5/5', (tester) async {
      await _pumpScreen(tester, const StoreScreen(), 5);
      expect(find.text('Full'), findsNWidgets(2)); // real-money refill + coin refill
      expect(find.text('Lives full'), findsNWidgets(2)); // status card + ad row
      expect(find.text('\$0.99'), findsNothing);
      expect(find.text('\$1.99'), findsWidgets); // unlimited stays priced
    });

    testWidgets('rows show prices below full', (tester) async {
      await _pumpScreen(tester, const StoreScreen(), 3);
      expect(find.text('Full'), findsNothing);
      expect(find.text('\$0.99'), findsOneWidget);
    });
  });
}
