import 'package:flutter/widgets.dart';

import 'duel_tube_game_screen.dart';
import 'fuse_game_screen.dart';
import 'solo_game_screen.dart';

/// Picks the right game-screen widget for a mode id, so callers (Home,
/// ModeHub, LevelSelect, QuickMatchSetup) don't need to know that Fuse is a
/// grid and Pour/Split/Recipe are tube rows.
class GameScreenRouter {
  GameScreenRouter._();

  static Widget passPlay({required String modeId}) {
    if (modeId == 'fuse') return const FuseGameScreen(mode: 'pass');
    return DuelTubeGameScreen(kind: modeId, mode: 'pass');
  }

  static Widget quickMatch({required String modeId, required String aiKey, String format = 'standard'}) {
    if (modeId == 'fuse') return FuseGameScreen(mode: 'ai', aiKey: aiKey);
    return DuelTubeGameScreen(kind: modeId, mode: 'ai', aiKey: aiKey, format: format);
  }

  static Widget level({required String modeId, required int levelNumber}) {
    if (modeId == 'solo') return SoloGameScreen(levelNumber: levelNumber);
    if (modeId == 'fuse') return FuseGameScreen(mode: 'ai', levelNumber: levelNumber);
    return DuelTubeGameScreen(kind: modeId, mode: 'ai', levelNumber: levelNumber);
  }
}
