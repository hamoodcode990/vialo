import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../monetization/iap_products.dart';
import '../monetization/monetization_controller.dart';
import '../state/profile_provider.dart';
import '../theme/app_colors.dart';
import '../theme/spacing.dart';
import '../theme/tube_palettes.dart';

/// IAP + rewarded-ad + cosmetics store. Real purchases/ads route through
/// [MonetizationController] (RevenueCat/AdMob); when the store isn't
/// configured yet (no real account credentials — see MonetizationConfig)
/// it falls back to the same instant-grant stub decant.html's reference
/// implementation uses, so the screen stays testable either way. Port of
/// decant.html's `store()`.
class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final monetize = ref.watch(monetizationControllerProvider);
    // Coin-priced cosmetics and the coin-spend life refill aren't real-money
    // IAP — they stay on ProfileController directly, no SDK involved.
    final ctrl = ref.read(profileControllerProvider.notifier);
    final starterEligible = !profile.starterUsed &&
        DateTime.now().millisecondsSinceEpoch - profile.firstOpenAt < 48 * 3600 * 1000;

    void toast(String msg) {
      if (msg.isEmpty) return; // e.g. a cancelled purchase — nothing to say
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }

    Future<void> buy(String productId) async => toast(await monetize.purchase(productId));
    Future<void> watch(String placement) async => toast(await monetize.watchRewardedAd(placement));

    return Scaffold(
      appBar: AppBar(title: const Text('Store')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (starterEligible) ...[
              const _SectionLabel('LIMITED — FIRST 48 HOURS'),
              _IapRow(
                title: kStarterPackProduct.title,
                subtitle: kStarterPackProduct.subtitle,
                price: kStarterPackProduct.fallbackPriceLabel,
                onTap: () => buy(kProductStarterPack),
              ),
            ],
            const _SectionLabel('LIVES'),
            for (final product in kLivesProducts)
              _IapRow(
                title: product.title,
                subtitle: null,
                price: product.fallbackPriceLabel,
                onTap: () => buy(product.id),
              ),
            _WatchAdRow(subtitle: '+1 life, free', onWatched: () => watch(kAdPlacementLife)),
            const _SectionLabel('COINS'),
            for (final product in kCoinProducts)
              _IapRow(
                title: product.title,
                subtitle: null,
                price: product.fallbackPriceLabel,
                onTap: () => buy(product.id),
              ),
            _WatchAdRow(subtitle: '+25 coins, free', onWatched: () => watch(kAdPlacementCoins)),
            const _SectionLabel('ADS'),
            _IapRow(
              title: kRemoveAdsProduct.title,
              subtitle: profile.adsRemoved ? 'Already removed' : kRemoveAdsProduct.subtitle,
              price: profile.adsRemoved ? null : kRemoveAdsProduct.fallbackPriceLabel,
              onTap: profile.adsRemoved ? null : () => buy(kProductRemoveAds),
            ),
            const _SectionLabel('PALETTE'),
            for (final p in kTubePalettes)
              _PaletteRow(
                name: p.name,
                colors: p.colors,
                owned: profile.unlockedPalettes.contains(p.id),
                price: p.price,
                selected: profile.paletteId == p.id,
                onTap: () {
                  final ok = ctrl.selectPalette(p.id, p.price);
                  if (!ok) toast('Not enough coins');
                },
              ),
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'Palettes are cosmetic. They never change the board, the rules, or the difficulty. '
                'High contrast is free — accessibility is not a paid feature.',
                style: TextStyle(fontSize: 11.5, color: AppColors.mute),
              ),
            ),
            const _SectionLabel('SPEND COINS'),
            _IapRow(
              title: 'Refill 1 life',
              subtitle: null,
              price: '75🪙',
              onTap: () {
                if (ctrl.spendCoins(75)) {
                  ctrl.addLives(1);
                  toast('+1 life');
                } else {
                  toast('Not enough coins');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Text(text, style: const TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w800, color: AppColors.mute)),
    );
  }
}

class _IapRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? price;
  final VoidCallback? onTap;
  const _IapRow({required this.title, required this.subtitle, required this.price, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.ink2,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.edge),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: const TextStyle(fontSize: 11, color: AppColors.mute)),
                ],
              ],
            ),
          ),
          if (price != null)
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.p1, AppColors.p1d]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(price!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            )
          else
            const Icon(Icons.check_circle_rounded, color: AppColors.p1),
        ],
      ),
    );
  }
}

class _WatchAdRow extends StatefulWidget {
  final String subtitle;
  final Future<void> Function() onWatched;
  const _WatchAdRow({required this.subtitle, required this.onWatched});

  @override
  State<_WatchAdRow> createState() => _WatchAdRowState();
}

class _WatchAdRowState extends State<_WatchAdRow> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.ink2,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.edge),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Watch a video', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 2),
                Text(widget.subtitle, style: const TextStyle(fontSize: 11, color: AppColors.mute)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _loading
                ? null
                : () async {
                    setState(() => _loading = true);
                    // The real duration (real ad watch, or the dev-mode
                    // simulated-load fallback) lives in MonetizationController.
                    await widget.onWatched();
                    if (!mounted) return;
                    setState(() => _loading = false);
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.violet, AppColors.violetd]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _loading ? 'Loading…' : '▶ Watch',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaletteRow extends StatelessWidget {
  final String name;
  final List<Color> colors;
  final bool owned;
  final int price;
  final bool selected;
  final VoidCallback onTap;
  const _PaletteRow({
    required this.name,
    required this.colors,
    required this.owned,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.ink2,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: selected ? AppColors.p1.withValues(alpha: 0.4) : AppColors.edge),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$name${owned ? '' : ' · $price🪙'}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 6),
                  Row(children: [for (final c in colors.take(9)) Container(width: 14, height: 14, margin: const EdgeInsets.only(right: 4), decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)))]),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.p1),
          ],
        ),
      ),
    );
  }
}
