import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'mode_info.dart';

/// A themed zone of a level ladder (CLAUDE.md Step 10) — 24 levels per
/// chapter, an accent tint, and a one-line story blurb shown as a title card
/// when the player scrolls into it. Every mode (Solo plus all four duels)
/// tells its own story through these — same cadence and treatment, different
/// copy, all inside the atelier framing CLAUDE.md's Madame Corvel setting
/// established.
class Chapter {
  final int index; // 0-based
  final String title;
  final String blurb;
  final Color accent;
  final int startLevel; // 1-based, inclusive
  final int endLevel; // inclusive

  const Chapter({
    required this.index,
    required this.title,
    required this.blurb,
    required this.accent,
    required this.startLevel,
    required this.endLevel,
  });

  String get label => 'Chapter ${index + 1}: $title';
}

const int kChapterSize = 24;

/// Solo's story: a lone apprentice working the bench alone, level by level,
/// deeper into Corvel's back-catalogue of formulas. Cycles through all four
/// accents in turn since there's no single rival colour to anchor it to.
const List<({String title, String blurb})> _kSoloChapterCopy = [
  (title: 'The First Pours', blurb: "Where every apprentice begins."),
  (title: 'The Deep Sort', blurb: "The tubes run taller, the choices harder."),
  (title: 'Emerald Hollow', blurb: "A green hush settles over the bench."),
  (title: 'Rose Quarter', blurb: "Petals and pigments, tangled together."),
  (title: 'Plum Passage', blurb: "The shadows deepen, the palette narrows."),
  (title: 'Gilded Row', blurb: "Gold catches the last of the light."),
  (title: 'The Long Bench', blurb: "Madame Corvel's oldest formulas, still unsorted."),
  (title: 'Ivory Reach', blurb: "Where the parchment runs pale and endless."),
  (title: 'The Amber Wing', blurb: "Warm glass, warmer stakes."),
  (title: 'Verdant Close', blurb: "The garden's colours spill into the lab."),
  (title: 'The Violet Hour', blurb: "Twilight work, for steady hands only."),
  (title: "Corvel's Vault", blurb: "The final formulas — everything you've learned, at once."),
  (title: 'The Last Decant', blurb: "One board left. Finish it."),
];

/// Pour's story: sort-duel rivalries, climbing the atelier's pecking order
/// one claimed tube at a time.
const List<({String title, String blurb})> _kPourChapterCopy = [
  (title: 'The Sorting Bench', blurb: "Two stools, one bench. Everyone starts here."),
  (title: 'The Apprentice Wing', blurb: "Word spreads: you're worth watching."),
  (title: "The Rival's Row", blurb: "Corvel pairs you against her sharper students now."),
  (title: 'The Sealed Hall', blurb: "Every tube you claim, someone else can't have."),
  (title: 'The Long Claim', blurb: "Chains of claims separate the quick from the rest."),
  (title: "Journeyman's Gauntlet", blurb: "The bench gets crowded. The stakes don't."),
  (title: "Corvel's Challenge", blurb: "Her own trial boards — beat them, and whoever's left."),
];

/// Split's story: divided benches, rival colours, and the one neutral gold
/// nobody owns until somebody takes it.
const List<({String title, String blurb})> _kSplitChapterCopy = [
  (title: 'Two Benches, One Bottle', blurb: "You split the bench. The gold stays up for grabs."),
  (title: 'The Neutral Ground', blurb: "Every match comes down to who wants gold more."),
  (title: 'Rival Formulas', blurb: "Your colours, theirs, and the one neither of you owns yet."),
  (title: 'The Gilded Line', blurb: "Corvel adds more gold to the board. More to fight for."),
  (title: 'House Divided', blurb: "Every apprentice claims their own — until gold decides it."),
  (title: "The Tiebreaker's Table", blurb: "Close matches. Gold breaks all of them."),
  (title: "Corvel's Wager", blurb: "Her final split boards — winner takes the gold, and the rank."),
];

/// Fuse's story: alchemical fusion, merging up through Corvel's furnace.
const List<({String title, String blurb})> _kFuseChapterCopy = [
  (title: 'First Fusions', blurb: "Two of a kind, merged into one."),
  (title: 'The Rising Grid', blurb: "Bigger boards. Faster merges."),
  (title: "Corvel's Furnace", blurb: "Nothing claims itself. Reach four, or lose the square."),
  (title: 'The Merge Wars', blurb: "Every apprentice fusing for the same six squares."),
  (title: 'The Final Grid', blurb: "Her hardest boards — fuse fast, or fall behind."),
];

/// Recipe's story: secret formulas, memorised and never spoken aloud.
const List<({String title, String blurb})> _kRecipeChapterCopy = [
  (title: 'Your First Formula', blurb: "Four colours, memorised, told to no one."),
  (title: 'The Shared Shelf', blurb: "Everyone draws from the same tubes. Only you know why."),
  (title: "Corvel's Ciphers", blurb: "Her formulas get longer memory tricks, not longer lists."),
  (title: 'The Formula Wars', blurb: "Two apprentices, one shelf, opposite secrets."),
  (title: 'The Last Recipe', blurb: "Finish hers first. There's no partial credit."),
];

const List<Color> _kSoloChapterAccents = [
  AppColors.p1,
  AppColors.p2,
  AppColors.violet,
  AppColors.gold,
];

({List<({String title, String blurb})> copy, List<Color> accents}) _contentFor(String modeId) {
  switch (modeId) {
    case 'pour':
      return (copy: _kPourChapterCopy, accents: [modeInfoFor('pour').color]);
    case 'split':
      return (copy: _kSplitChapterCopy, accents: [modeInfoFor('split').color]);
    case 'fuse':
      return (copy: _kFuseChapterCopy, accents: [modeInfoFor('fuse').color]);
    case 'recipe':
      return (copy: _kRecipeChapterCopy, accents: [modeInfoFor('recipe').color]);
    case 'solo':
    default:
      return (copy: _kSoloChapterCopy, accents: _kSoloChapterAccents);
  }
}

/// Builds the full chapter list for [modeId]'s level ladder of [totalLevels]
/// levels. Cycles the copy/accent lists if there are more chapters than
/// entries (there won't be at the current level counts, but this keeps it
/// from crashing if any mode's level count ever grows past its story).
List<Chapter> buildChapters(String modeId, int totalLevels) {
  final content = _contentFor(modeId);
  final chapters = <Chapter>[];
  var start = 1;
  var i = 0;
  while (start <= totalLevels) {
    final end = (start + kChapterSize - 1).clamp(1, totalLevels);
    final copy = content.copy[i % content.copy.length];
    chapters.add(Chapter(
      index: i,
      title: copy.title,
      blurb: copy.blurb,
      accent: content.accents[i % content.accents.length],
      startLevel: start,
      endLevel: end,
    ));
    start = end + 1;
    i++;
  }
  return chapters;
}

Chapter chapterForLevel(List<Chapter> chapters, int level) =>
    chapters.firstWhere((c) => level >= c.startLevel && level <= c.endLevel, orElse: () => chapters.last);
