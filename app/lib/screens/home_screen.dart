import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_controller.dart';
import '../profile/profile.dart';
import '../state/profile_provider.dart';
import '../theme/app_colors.dart';
import '../theme/cosmetics.dart';
import '../theme/mode_info.dart';
import '../theme/spacing.dart';
import '../widgets/app_card.dart';
import '../widgets/app_route.dart';
import '../widgets/header_bar.dart';
import 'daily_challenge_screen.dart';
import 'mode_hub_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'solo_level_map_screen.dart';
import 'stats_screen.dart';
import 'store_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Mutating provider state during build() would trigger another build,
    // looping forever — regen on mount and on resume only, never in build().
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(profileControllerProvider.notifier).regenLivesNow();
      ref.read(audioControllerProvider).playMenuMusic();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(profileControllerProvider.notifier).regenLivesNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final avatar = avatarById(profile.avatarId);
    final doneToday = profile.dailyDoneToday(DateTime.now());
    final s = profile.stats;
    final totalGames = s.w + s.l + s.fw + s.fl + s.sw + s.sl + s.rw + s.rl;
    final totalWins = s.w + s.fw + s.sw + s.rw;
    final totalLosses = s.l + s.fl + s.sl + s.rl;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HeaderBar(
                avatar: avatar,
                profile: profile,
                onAvatarTap: () => Navigator.of(context).push(AppRoute(builder: (_) => const ProfileScreen())),
                onLivesTap: () => Navigator.of(context).push(AppRoute(builder: (_) => const StoreScreen())),
                onCoinsTap: () => Navigator.of(context).push(AppRoute(builder: (_) => const StoreScreen())),
              ),
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final c in [AppColors.p2, AppColors.violet, AppColors.p1, AppColors.gold])
                          Container(
                            width: 11,
                            height: 15,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(7)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('VIALO', style: Theme.of(context).textTheme.displayLarge),
                    const SizedBox(height: 4),
                    const Text(
                      'ONE BOARD · TWO MINDS · CLAIM IT',
                      style: TextStyle(fontSize: 9.5, letterSpacing: 3.6, color: AppColors.mute, fontWeight: FontWeight.w600),
                    ),
                    if (totalGames > 0) ...[
                      const SizedBox(height: 10),
                      Text(
                        '${totalWins}W · ${totalLosses}L${s.bs > 1 ? ' · best streak ${s.bs}' : ''}',
                        style: const TextStyle(fontSize: 12, color: AppColors.mute),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppCard(
                onTap: () => Navigator.of(context).push(AppRoute(builder: (_) => const DailyChallengeScreen())),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Today's Pour", style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.goldd, fontSize: 16)),
                          const SizedBox(height: 3),
                          Text(
                            doneToday ? 'Solved for today — come back tomorrow' : 'One puzzle. Everyone gets the same one today.',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.mute),
                          ),
                        ],
                      ),
                    ),
                    Text('🔥 ${profile.daily.streak}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.goldd)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                accentColor: AppColors.p1,
                onTap: () => Navigator.of(context).push(
                  AppRoute(builder: (_) => const SoloLevelMapScreen()),
                ),
                child: Row(
                  children: [
                    const Text('🗺️', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Solo sort', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                          const SizedBox(height: 2),
                          Text(
                            '${kLevelCounts['solo']} levels · your own path through the atelier',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.mute),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.p1),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Padding(
                padding: EdgeInsets.only(left: 2, bottom: AppSpacing.sm),
                child: Text('DUELS', style: TextStyle(fontSize: 10.5, letterSpacing: 2, fontWeight: FontWeight.w800, color: AppColors.mute)),
              ),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.35,
                children: [for (final mode in kDuelModes) _ModeGridTile(mode: mode)],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _IconButton(emoji: '🛍️', onTap: () => Navigator.of(context).push(AppRoute(builder: (_) => const StoreScreen()))),
                  _IconButton(emoji: '📊', onTap: () => Navigator.of(context).push(AppRoute(builder: (_) => const StatsScreen()))),
                  _IconButton(
                    emoji: '⚙️',
                    onTap: () => Navigator.of(context).push(AppRoute(builder: (_) => const SettingsScreen())),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact square tile in the 2x2 "Duels" grid — one tap target, always to
/// the mode's hub (Levels / Quick Match / Pass & Play). Replaces four
/// full-width cards (name + blurb + a nested "Pass & play ›" shortcut chip,
/// itself a second hit target a few pixels from the first, easy to
/// fat-finger by mistake) that made the home screen a long scroll before
/// anyone reached Solo or the icon row below. Blurbs move to the hub itself,
/// which now also surfaces the "how to play" tutorial one tap away.
class _ModeGridTile extends ConsumerWidget {
  final ModeInfo mode;
  const _ModeGridTile({required this.mode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      accentColor: mode.color,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => Navigator.of(context).push(AppRoute(builder: (_) => ModeHubScreen(modeId: mode.id))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(mode.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(mode.name, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;
  const _IconButton({required this.emoji, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.ink2,
            border: Border.all(color: AppColors.outline, width: 2.5),
            boxShadow: [BoxShadow(color: AppColors.txt.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 17)),
        ),
      ),
    );
  }
}
