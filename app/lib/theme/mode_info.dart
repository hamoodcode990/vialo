import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Static per-mode display metadata — name, accent colour, blurb. Port of
/// decant.html's `MODES`/`HUBINFO`/`KNAME`.
class ModeInfo {
  final String id;
  final String name;
  final Color color;
  final String blurb;
  final String emoji;

  const ModeInfo({
    required this.id,
    required this.name,
    required this.color,
    required this.blurb,
    required this.emoji,
  });
}

const List<ModeInfo> kDuelModes = [
  ModeInfo(
    id: 'split',
    name: 'Split',
    color: AppColors.violet,
    blurb: 'Three colours each, one gold — it decides the match',
    emoji: '🌗',
  ),
  ModeInfo(
    id: 'pour',
    name: 'Pour',
    color: AppColors.p2,
    blurb: 'Sort duel · claim a tube, go again',
    emoji: '🧪',
  ),
  ModeInfo(
    id: 'fuse',
    name: 'Fuse',
    color: AppColors.p1,
    blurb: 'Merge equal tiles · reach 4 to claim the square',
    emoji: '💠',
  ),
  ModeInfo(
    id: 'recipe',
    name: 'Recipe',
    color: AppColors.gold,
    blurb: 'Race to blend your secret formula first',
    emoji: '📜',
  ),
];

ModeInfo modeInfoFor(String id) => kDuelModes.firstWhere((m) => m.id == id);
