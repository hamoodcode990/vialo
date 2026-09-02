import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game.dart';
import '../state/profile_provider.dart';
import '../theme/app_colors.dart';
import '../theme/cosmetics.dart';
import '../theme/mode_info.dart';
import '../theme/spacing.dart';
import '../widgets/app_card.dart';
import '../widgets/app_route.dart';
import '../widgets/header_bar.dart';
import '../widgets/mode_entry.dart';
import 'game_screen_router.dart';
import 'level_select_screen.dart';
import 'mode_tutorial_screen.dart';
import 'profile_screen.dart';
import 'quick_match_setup_screen.dart';
import 'store_screen.dart';

/// Levels / Quick Match / Pass & Play — port of decant.html's `modeHub()`.
class ModeHubScreen extends ConsumerWidget {
  final String modeId;
  const ModeHubScreen({super.key, required this.modeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = modeInfoFor(modeId);
    final profile = ref.watch(profileProvider);
    final avatar = avatarById(profile.avatarId);
    final total = kLevelCounts[modeId]!;
    final cleared = (profile.levelProgress[modeId] ?? 1) - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(info.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'How to play',
            onPressed: () => Navigator.of(context).push(AppRoute(builder: (_) => ModeTutorialScreen(modeId: modeId))),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
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
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Text(info.blurb, style: const TextStyle(color: AppColors.mute, fontSize: 12.5, height: 1.4)),
              ),
              HubCard(
                emoji: '🗺️',
                accentColor: info.color,
                title: 'Levels',
                subtitle: '$cleared/$total cleared · costs lives to fail, coins to win',
                onTap: () => Navigator.of(context).push(AppRoute(builder: (_) => LevelSelectScreen(mode: modeId))),
              ),
              HubCard(
                emoji: '⚡',
                accentColor: info.color,
                title: 'Quick match',
                subtitle: 'Pick a difficulty, play now — free, unlimited',
                onTap: () => Navigator.of(context).push(AppRoute(builder: (_) => QuickMatchSetupScreen(modeId: modeId))),
              ),
              HubCard(
                emoji: '🤝',
                accentColor: info.color,
                title: 'Pass & play',
                subtitle: 'Local two-player, same device — free, unlimited',
                onTap: () => openMode(
                  context,
                  ref,
                  modeId: modeId,
                  gameBuilder: (_) => GameScreenRouter.passPlay(modeId: modeId),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
