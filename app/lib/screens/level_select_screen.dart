import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game.dart';
import '../state/profile_provider.dart';
import '../theme/app_colors.dart';
import '../theme/cosmetics.dart';
import '../theme/spacing.dart';
import '../widgets/header_bar.dart';
import '../widgets/star_row.dart';
import 'game_screen_router.dart';
import 'profile_screen.dart';
import 'store_screen.dart';

const Map<String, String> _kModeTitle = {
  'solo': 'Solo sort',
  'pour': 'Pour levels',
  'split': 'Split levels',
  'fuse': 'Fuse levels',
  'recipe': 'Recipe levels',
};

/// Level grid: locked past the unlock frontier, stars shown on cleared
/// levels, grouped in chunks of 25. One screen serves Solo and all four
/// duel modes — port of decant.html's `soloLevels()`/`levelSelect()`.
class LevelSelectScreen extends ConsumerWidget {
  final String mode;
  const LevelSelectScreen({super.key, required this.mode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final total = kLevelCounts[mode]!;
    final progress = profile.levelProgress[mode] ?? 1;
    final cleared = profile.stars[mode]?.length ?? 0;
    final avatar = avatarById(profile.avatarId);

    return Scaffold(
      appBar: AppBar(title: Text(_kModeTitle[mode] ?? mode)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HeaderBar(
                avatarEmoji: avatar.emoji,
                lives: profile.lives,
                lifeMax: 5,
                coins: profile.coins,
                onAvatarTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
                onLivesTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StoreScreen())),
                onCoinsTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StoreScreen())),
              ),
              Text(
                '$cleared/$total CLEARED · NEXT: LEVEL ${progress > total ? total : progress}',
                style: const TextStyle(fontSize: 10.5, letterSpacing: 1, fontWeight: FontWeight.w800, color: AppColors.mute),
              ),
              const SizedBox(height: AppSpacing.md),
              for (var start = 1; start <= total; start += 25) _LevelChunk(mode: mode, start: start, end: (start + 24).clamp(1, total)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelChunk extends ConsumerWidget {
  final String mode;
  final int start;
  final int end;
  const _LevelChunk({required this.mode, required this.start, required this.end});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final progress = profile.levelProgress[mode] ?? 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$start–$end', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.goldd, fontSize: 15)),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
            children: [
              for (var n = start; n <= end; n++)
                _LevelChip(
                  mode: mode,
                  n: n,
                  locked: n > progress,
                  stars: profile.stars[mode]?[n.toString()] ?? 0,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelChip extends ConsumerWidget {
  final String mode;
  final int n;
  final bool locked;
  final int stars;
  const _LevelChip({required this.mode, required this.n, required this.locked, required this.stars});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = stars > 0;
    return GestureDetector(
      onTap: () => _open(context, ref),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          gradient: done ? const LinearGradient(colors: [AppColors.p1, AppColors.p1d]) : null,
          color: done ? null : AppColors.ink2,
          border: Border.all(color: AppColors.edge),
          boxShadow: [BoxShadow(color: AppColors.txt.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              locked ? '🔒' : '$n',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: done ? Colors.white : AppColors.txt),
            ),
            if (done) StarRow(stars: stars, size: 7),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, WidgetRef ref) {
    if (locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Locked — clear the level before it first')),
      );
      return;
    }
    final profile = ref.read(profileProvider);
    final unlimited = profile.tempLivesUntil > DateTime.now().millisecondsSinceEpoch;
    if (profile.lives <= 0 && !unlimited) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StoreScreen()));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Out of lives')));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => GameScreenRouter.level(modeId: mode, levelNumber: n)));
  }
}
