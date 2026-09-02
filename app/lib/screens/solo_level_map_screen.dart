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
import 'mode_tutorial_screen.dart';
import 'profile_screen.dart';
import 'store_screen.dart';

/// Solo's level ladder as a winding road with chapter framing (CLAUDE.md
/// Step 10) — a 2D path with perspective tricks (node position/size
/// variation, a smoothed curve, parallax backdrop) rather than a flat grid
/// or a real 3D scene. Its own screen/widget so it never entangles with any
/// board-rendering code; duel modes keep the existing flat
/// LevelSelectScreen grid — see the judgment-call note in this batch's
/// report for why.
class SoloLevelMapScreen extends ConsumerStatefulWidget {
  const SoloLevelMapScreen({super.key});

  @override
  ConsumerState<SoloLevelMapScreen> createState() => _SoloLevelMapScreenState();
}

class _SoloLevelMapScreenState extends ConsumerState<SoloLevelMapScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final total = kLevelCounts['solo']!;
    final progress = profile.levelProgress['solo'] ?? 1;
    final avatar = avatarById(profile.avatarId);
    final chapters = buildChapters('solo', total);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solo sort'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'How to play',
            onPressed: () => Navigator.of(context).push(AppRoute(builder: (_) => const ModeTutorialScreen(modeId: 'solo'))),
          ),
        ],
      ),
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
                          profile: profile,
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
                            stars: profile.stars['solo']?[n.toString()] ?? 0,
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
      modeId: 'solo',
      gameBuilder: (_) => GameScreenRouter.level(modeId: 'solo', levelNumber: node.level),
    );
  }
}

