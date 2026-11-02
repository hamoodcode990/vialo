import 'package:flutter/material.dart';

import 'tube_palettes.dart';

/// How an engine colour index becomes a colour on screen. Rendering only:
/// engine indices never change, and neither do the audited palette values in
/// tube_palettes.dart.
///
/// Two problems live here:
/// - Palettes have 9 slots, but boards go up to 13 colours, so `index % 9`
///   drew two different colours identically. Indices 9-12 now use
///   [_kExtraColours].
/// - Split's neutral index is `own * 2`, which landed on a different slot at
///   every tier (purple, orange, indigo, blue). It is now always
///   [kMetallicGold], and players never get a slot that looks like it.

/// Split's neutral colour. [TubePainter] recognises this exact value and
/// paints it with the metallic treatment instead of a plain liquid gradient.
const Color kMetallicGold = Color(0xFFD9AE2E);

/// The stops of the metallic treatment, top to bottom.
const List<Color> kMetallicGoldStops = [
  Color(0xFFFFF0A8),
  Color(0xFFE6BE3C),
  Color(0xFFB98A1C),
  Color(0xFF7C5A10),
];

/// Indices 9-12 for each palette, chosen by measurement: see
/// test/theme/board_colors_test.dart.
const Map<String, List<Color>> _kExtraColours = {
  'lab': [Color(0xFF666666), Color(0xFF666600), Color(0xFFCCEEAA), Color(0xFFCC22AA)],
  'hc': [Color(0xFF4444EE), Color(0xFF666622), Color(0xFF00EE88), Color(0xFF66EEEE)],
  'ink': [Color(0xFF8800EE), Color(0xFFCCEE00), Color(0xFFCC0000), Color(0xFFAA66EE)],
  'neon': [Color(0xFF666666), Color(0xFF8888CC), Color(0xFF666600), Color(0xFFEE22AA)],
  'deep': [Color(0xFFAA4466), Color(0xFFCCAACC), Color(0xFF44EE66), Color(0xFF666622)],
};

/// Slots a Split *player* colour may not use because they read as gold.
const Map<String, Set<int>> _kSplitExcludedSlots = {
  'lab': {2, 6},
  'hc': {1, 6},
  'ink': {2, 6},
  'neon': {2, 6},
  'deep': {2, 6},
};

const int kBoardColourCount = 13;

/// Every colour a non-Split board can show, in engine-index order.
List<Color> boardColours(TubePalette palette) => [
      ...palette.colors,
      ...(_kExtraColours[palette.id] ?? _kExtraColours['lab']!),
    ];

/// The colour for engine index [index] on a Solo/Pour/Recipe board.
Color boardColour(TubePalette palette, int index) =>
    boardColours(palette)[index % kBoardColourCount];

/// Split's player colours, in engine-index order.
List<Color> splitPlayerColours(TubePalette palette) {
  final excluded = _kSplitExcludedSlots[palette.id] ?? const <int>{};
  final all = boardColours(palette);
  return [
    for (var i = 0; i < all.length; i++)
      if (!excluded.contains(i)) all[i],
  ];
}

/// The colour for engine index [index] on a Split board where each player
/// owns [own] colours.
Color splitColour(TubePalette palette, int index, int own) {
  if (index >= own * 2) return kMetallicGold;
  return splitPlayerColours(palette)[index];
}
