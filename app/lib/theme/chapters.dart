import 'package:flutter/material.dart';

import 'app_colors.dart';

/// A themed zone of Solo's level ladder (CLAUDE.md Step 10) — 24 levels per
/// chapter, its own accent tint, and a one-line story blurb shown as a
/// title card when the player scrolls into it. Names/blurbs are explicitly
/// placeholder-style per the prompt ("I'll refine actual names later, just
/// get the structure working") — chosen to fit the atelier framing already
/// established (CLAUDE.md's Madame Corvel setting) without writing any real
/// narrative content.
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

const List<({String title, String blurb})> _kChapterCopy = [
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

const List<Color> _kChapterAccents = [
  AppColors.p1,
  AppColors.p2,
  AppColors.violet,
  AppColors.gold,
];

/// Builds the full chapter list for a level ladder of [totalLevels] levels.
/// Cycles the placeholder copy/accent lists if there are more chapters than
/// entries (there won't be, at 24/chapter up to 300 levels = 13 chapters,
/// exactly matching the copy list — but this keeps it from crashing if the
/// level count ever grows).
List<Chapter> buildChapters(int totalLevels) {
  final chapters = <Chapter>[];
  var start = 1;
  var i = 0;
  while (start <= totalLevels) {
    final end = (start + kChapterSize - 1).clamp(1, totalLevels);
    final copy = _kChapterCopy[i % _kChapterCopy.length];
    chapters.add(Chapter(
      index: i,
      title: copy.title,
      blurb: copy.blurb,
      accent: _kChapterAccents[i % _kChapterAccents.length],
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
