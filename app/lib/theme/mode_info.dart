import 'package:flutter/material.dart';

import '../widgets/app_icon.dart';
import 'app_colors.dart';

/// Static per-mode display metadata — name, accent colour, blurb. Port of
/// decant.html's `MODES`/`HUBINFO`/`KNAME`.
class ModeInfo {
  final String id;
  final String name;
  final Color color;
  final String blurb;
  final AppIcons icon;

  const ModeInfo({
    required this.id,
    required this.name,
    required this.color,
    required this.blurb,
    required this.icon,
  });
}

const List<ModeInfo> kDuelModes = [
  ModeInfo(
    id: 'split',
    name: 'Split',
    color: AppColors.violet,
    blurb: 'Three colours each, one gold — it decides the match',
    icon: AppIcons.split,
  ),
  ModeInfo(
    id: 'pour',
    name: 'Pour',
    color: AppColors.p2,
    blurb: 'Sort duel · claim a tube, go again',
    icon: AppIcons.pour,
  ),
  ModeInfo(
    id: 'fuse',
    name: 'Fuse',
    color: AppColors.p1,
    blurb: 'Merge equal tiles · reach 4 to claim the square',
    icon: AppIcons.gem,
  ),
  ModeInfo(
    id: 'recipe',
    name: 'Recipe',
    color: AppColors.gold,
    blurb: 'Race to blend your secret formula first',
    icon: AppIcons.scroll,
  ),
];

ModeInfo modeInfoFor(String id) => kDuelModes.firstWhere((m) => m.id == id);
