import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game.dart';
import '../state/profile_provider.dart';
import '../theme/app_colors.dart';
import '../theme/chapters.dart';
import '../theme/cosmetics.dart';
import '../theme/spacing.dart';
import '../widgets/header_bar.dart';
import '../widgets/level_road_path.dart';
import 'game_screen_router.dart';
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
    final chapters = buildChapters(total);

    return Scaffold(
      appBar: AppBar(title: const Text('Solo sort')),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _ParallaxBackdrop(scrollController: _scrollController)),
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
                          onAvatarTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
                          onLivesTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StoreScreen())),
                          onCoinsTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StoreScreen())),
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
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StoreScreen()));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Out of lives')));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => GameScreenRouter.level(modeId: 'solo', levelNumber: node.level)));
  }
}

/// Two soft, blurred colour blobs drifting at different fractions of scroll
/// speed — the "parallax background layers" CLAUDE.md Step 10 asks for.
/// Deliberately simple (no image assets, matching the app's no-external-
/// asset posture) rather than a painted landscape.
class _ParallaxBackdrop extends StatelessWidget {
  final ScrollController scrollController;
  const _ParallaxBackdrop({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        final offset = scrollController.hasClients ? scrollController.offset : 0.0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -60,
              top: 40 - offset * 0.12,
              child: _Blob(color: AppColors.p1.withValues(alpha: 0.10), size: 220),
            ),
            Positioned(
              right: -80,
              top: 420 - offset * 0.22,
              child: _Blob(color: AppColors.violet.withValues(alpha: 0.09), size: 260),
            ),
            Positioned(
              left: -40,
              top: 900 - offset * 0.17,
              child: _Blob(color: AppColors.gold.withValues(alpha: 0.10), size: 200),
            ),
          ],
        );
      },
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
