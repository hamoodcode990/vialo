import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game.dart';
import '../state/profile_provider.dart';
import '../theme/app_colors.dart';
import '../theme/chapters.dart';
import '../theme/cosmetics.dart';
import '../theme/spacing.dart';
import '../widgets/app_route.dart';
import '../widgets/header_bar.dart';
import '../widgets/level_road_path.dart';
import '../widgets/mode_entry.dart';
import '../widgets/parallax_backdrop.dart';
import 'game_screen_router.dart';
import 'profile_screen.dart';
import 'store_screen.dart';

const Map<String, String> _kModeTitle = {
  'pour': 'Pour levels',
  'split': 'Split levels',
  'fuse': 'Fuse levels',
  'recipe': 'Recipe levels',
};

/// A duel mode's level ladder as the same winding, chaptered road as Solo's
/// (widgets/level_road_path.dart) — each of the four duel modes tells its
/// own story (theme/chapters.dart) through the same treatment rather than
/// Solo being the only mode with a "path" and the rest a flat grid.
class LevelSelectScreen extends ConsumerStatefulWidget {
  final String mode;
  const LevelSelectScreen({super.key, required this.mode});

  @override
  ConsumerState<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends ConsumerState<LevelSelectScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;
    final profile = ref.watch(profileProvider);
    final total = kLevelCounts[mode]!;
    final progress = profile.levelProgress[mode] ?? 1;
    final avatar = avatarById(profile.avatarId);
    final chapters = buildChapters(mode, total);

    return Scaffold(
      appBar: AppBar(title: Text(_kModeTitle[mode] ?? mode)),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: ParallaxBackdrop(scrollController: _scrollController)),
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        HeaderBar(
                          avatar: avatar,
                          lives: profile.lives,
                          lifeMax: 5,
                          coins: profile.coins,
                          onAvatarTap: () => Navigator.of(context).push(AppRoute(builder: (_) => const ProfileScreen())),
                          onLivesTap: () => Navigator.of(context).push(AppRoute(builder: (_) => const StoreScreen())),
                          onCoinsTap: () => Navigator.of(context).push(AppRoute(builder: (_) => const StoreScreen())),
                        ),
                        Text(
                          'LEVEL ${progress > total ? total : progress} OF $total',
                          style: const TextStyle(fontSize: 10.5, letterSpacing: 1, fontWeight: FontWeight.w800, color: AppColors.mute),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  sliver: SliverList.builder(
                    itemCount: chapters.length,
                    itemBuilder: (context, i) {
                      final chapter = chapters[i];
                      final nodes = [
                        for (var n = chapter.startLevel; n <= chapter.endLevel; n++)
                          LevelNodeData(
                            level: n,
                            state: n < progress
                                ? LevelNodeState.complete
                                : (n == progress ? LevelNodeState.current : LevelNodeState.locked),
                            stars: profile.stars[mode]?[n.toString()] ?? 0,
                          ),
                      ];
                      return LevelRoadSection(
                        chapter: chapter,
                        nodes: nodes,
                        onTapNode: (node) => _openLevel(context, node),
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openLevel(BuildContext context, LevelNodeData node) {
    if (node.state == LevelNodeState.locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Locked — clear the level before it first')),
      );
      return;
    }
    final profile = ref.read(profileProvider);
    final unlimited = profile.tempLivesUntil > DateTime.now().millisecondsSinceEpoch;
    if (profile.lives <= 0 && !unlimited) {
      Navigator.of(context).push(AppRoute(builder: (_) => const StoreScreen()));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Out of lives')));
      return;
    }
    openMode(
      context,
      ref,
      modeId: widget.mode,
      gameBuilder: (_) => GameScreenRouter.level(modeId: widget.mode, levelNumber: node.level),
    );
  }
}
