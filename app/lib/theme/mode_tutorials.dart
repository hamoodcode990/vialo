import 'package:flutter/material.dart';

import '../widgets/tutorial_visuals.dart';
import 'app_colors.dart';
import 'mode_info.dart';

/// Per-mode "how to play" content shown by `ModeTutorialScreen` — one door
/// (Levels, Quick Match, Pass & Play) auto-shows it the first time a player
/// enters a mode (`widgets/mode_entry.dart`'s `openMode`); a help icon on
/// the mode hub reopens it any time after. Copy is written for a first-timer
/// (no internal tuning numbers — see CLAUDE.md's "do not change without
/// being asked" section, which is about balance, not player-facing rules).
class TutorialStep {
  final String title;
  final String body;
  final WidgetBuilder visual;
  const TutorialStep({required this.title, required this.body, required this.visual});
}

/// Display metadata for a tutorial's own screen — separate from [ModeInfo]
/// because Solo isn't a duel mode and has none there.
class TutorialModeMeta {
  final String name;
  final Color color;
  final String emoji;
  const TutorialModeMeta({required this.name, required this.color, required this.emoji});
}

TutorialModeMeta tutorialMetaFor(String modeId) {
  if (modeId == 'solo') {
    // A map/path glyph, not a flask — Pour already owns 🧪, and Solo's own
    // identity everywhere else in the app (SoloLevelMapScreen, its Home
    // card) is the winding road, not a tube.
    return const TutorialModeMeta(name: 'Solo sort', color: AppColors.p1, emoji: '🗺️');
  }
  final m = modeInfoFor(modeId);
  return TutorialModeMeta(name: m.name, color: m.color, emoji: m.emoji);
}

List<TutorialStep> tutorialStepsFor(String modeId) {
  switch (modeId) {
    case 'solo':
      return _soloSteps;
    case 'pour':
      return _pourSteps;
    case 'split':
      return _splitSteps;
    case 'fuse':
      return _fuseSteps;
    case 'recipe':
      return _recipeSteps;
    default:
      throw ArgumentError('No tutorial for mode "$modeId"');
  }
}

const _messy = [AppColors.p2, AppColors.violet, AppColors.p2];
const _sorted = [AppColors.p2, AppColors.p2, AppColors.p2];

final _soloSteps = [
  TutorialStep(
    title: 'Sort every colour',
    body: "Pour a tube onto another to gather each colour into its own tube — no opponent, just you and the clock.",
    visual: (_) => TutorialLoopDemo(frames: [
      Row(mainAxisSize: MainAxisSize.min, children: const [
        TubeVisual(blocks: _messy),
        SizedBox(width: 10),
        TubeVisual(blocks: []),
      ]),
      Row(mainAxisSize: MainAxisSize.min, children: const [
        TubeVisual(blocks: [AppColors.violet]),
        SizedBox(width: 10),
        TubeVisual(blocks: _sorted, sealed: true),
      ]),
    ]),
  ),
  const TutorialStep(
    title: 'Match colour, or pour into empty',
    body: 'A pour only works onto an empty tube or one already topped with the same colour. Fill a tube with one colour and it clears.',
    visual: _legalIllegalVisual,
  ),
  const TutorialStep(
    title: 'Mind your move count',
    body: "Every level has a move budget, set by its own ideal solution — wander past it without finishing and the attempt fails, the same as any other loss.",
    visual: _soloMoveLimitVisual,
  ),
  TutorialStep(
    title: 'Stars, hints, and undo',
    body: 'Finish inside the budget to earn more stars. Stuck? Spend coins on a hint, or undo your last pour.',
    visual: (_) => const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, color: AppColors.gold, size: 28),
        Icon(Icons.star_rounded, color: AppColors.gold, size: 28),
        Icon(Icons.star_rounded, color: AppColors.gold, size: 28),
        SizedBox(width: 14),
        Icon(Icons.lightbulb_rounded, color: AppColors.mute, size: 24),
        SizedBox(width: 8),
        Icon(Icons.undo_rounded, color: AppColors.mute, size: 24),
      ],
    ),
  ),
];

Widget _soloMoveLimitVisual(BuildContext context) => TutorialLoopDemo(frames: [
      Row(mainAxisSize: MainAxisSize.min, children: const [
        Icon(Icons.pending_outlined, color: AppColors.mute, size: 22),
        SizedBox(width: 8),
        Text('14 / 26 moves', style: TextStyle(color: AppColors.mute, fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
      Row(mainAxisSize: MainAxisSize.min, children: const [
        Icon(Icons.warning_rounded, color: AppColors.hot, size: 22),
        SizedBox(width: 8),
        Text('26 / 26 — failed', style: TextStyle(color: AppColors.hot, fontSize: 13, fontWeight: FontWeight.w800)),
      ]),
    ]);

Widget _legalIllegalVisual(BuildContext context) => TutorialLoopDemo(frames: [
      Row(mainAxisSize: MainAxisSize.min, children: const [
        TubeVisual(blocks: [AppColors.violet, AppColors.p1, AppColors.p1]),
        DemoArrow(),
        TubeVisual(blocks: [AppColors.p1]),
      ]),
      Row(mainAxisSize: MainAxisSize.min, children: const [
        TubeVisual(blocks: [AppColors.violet]),
        DemoArrow(),
        TubeVisual(blocks: [AppColors.p1, AppColors.p1, AppColors.p1], sealed: true),
      ]),
    ]);

final _pourSteps = [
  TutorialStep(
    title: 'Claim a tube',
    body: "Pour a tube's top colour onto a matching colour, or an empty tube. Fill one with a single colour and it locks — sealed, scored, and yours.",
    visual: (_) => TutorialLoopDemo(frames: [
      Row(mainAxisSize: MainAxisSize.min, children: const [
        TubeVisual(blocks: [AppColors.violet, AppColors.p1, AppColors.p1]),
        DemoArrow(),
        TubeVisual(blocks: [AppColors.p1]),
      ]),
      Row(mainAxisSize: MainAxisSize.min, children: const [
        TubeVisual(blocks: [AppColors.violet]),
        DemoArrow(),
        TubeVisual(blocks: [AppColors.p1, AppColors.p1, AppColors.p1], sealed: true),
      ]),
    ]),
  ),
  TutorialStep(
    title: "Sealed tubes are locked in",
    body: "A claimed tube can't be poured from again, and you can never immediately reverse the move your opponent just played against you.",
    visual: (_) => const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TubeVisual(blocks: [AppColors.p2, AppColors.p2, AppColors.p2], sealed: true),
        SizedBox(width: 10),
        Icon(Icons.block_rounded, color: AppColors.mute, size: 22),
      ],
    ),
  ),
  const TutorialStep(
    title: 'Claim it, go again',
    body: "Claiming a tube keeps your turn — chain claims to pull ahead. If nobody claims for a long stretch, the board locks and the higher score wins.",
    visual: _keepTurnVisual,
  ),
];

Widget _keepTurnVisual(BuildContext context) => TutorialLoopDemo(frames: [
      Row(mainAxisSize: MainAxisSize.min, children: const [
        _PlayerDot(color: AppColors.p1, active: true),
        SizedBox(width: 6),
        Icon(Icons.arrow_forward_rounded, color: AppColors.gold, size: 18),
        SizedBox(width: 6),
        Text('claim', style: TextStyle(color: AppColors.mute, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
      Row(mainAxisSize: MainAxisSize.min, children: const [
        _PlayerDot(color: AppColors.p1, active: true),
        SizedBox(width: 6),
        Icon(Icons.replay_rounded, color: AppColors.p1, size: 18),
        SizedBox(width: 6),
        Text('goes again', style: TextStyle(color: AppColors.mute, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    ]);

final _splitSteps = [
  const TutorialStep(
    title: 'Three colours each, one wildcard',
    body: "You and your opponent each own three colours. A fourth colour — gold — belongs to neither of you until someone claims it.",
    visual: _splitOwnersVisual,
  ),
  TutorialStep(
    title: 'Gold decides close matches',
    body: "Whoever pours the last drop into a gold tube claims it. It's the only colour up for grabs, so it swings the tightest games.",
    visual: (_) => TutorialLoopDemo(frames: [
      Row(mainAxisSize: MainAxisSize.min, children: const [
        TubeVisual(blocks: [AppColors.gold, AppColors.gold]),
        SizedBox(width: 8),
        Text('shared', style: TextStyle(color: AppColors.mute, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
      Row(mainAxisSize: MainAxisSize.min, children: const [
        TubeVisual(blocks: [AppColors.gold, AppColors.gold, AppColors.gold], sealed: true),
        SizedBox(width: 8),
        Text('claimed!', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w800)),
      ]),
    ]),
  ),
  const TutorialStep(
    title: 'Ownership beats last touch',
    body: "A tube always scores for whoever owns that colour — not whoever poured the final drop. And there's no chaining: every pour passes the turn.",
    visual: _splitOwnerCreditVisual,
  ),
];

Widget _splitOwnersVisual(BuildContext context) => const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TubeVisual(blocks: [AppColors.p2, AppColors.p2]),
        SizedBox(width: 8),
        TubeVisual(blocks: [AppColors.gold, AppColors.gold]),
        SizedBox(width: 8),
        TubeVisual(blocks: [AppColors.p1, AppColors.p1]),
      ],
    );

Widget _splitOwnerCreditVisual(BuildContext context) => TutorialLoopDemo(frames: [
      Row(mainAxisSize: MainAxisSize.min, children: const [
        TubeVisual(blocks: [AppColors.p1, AppColors.violet]),
        DemoArrow(),
        TubeVisual(blocks: [AppColors.violet, AppColors.violet]),
      ]),
      const Row(mainAxisSize: MainAxisSize.min, children: [
        TubeVisual(blocks: [AppColors.p1]),
        SizedBox(width: 10),
        TubeVisual(blocks: [AppColors.violet, AppColors.violet, AppColors.violet], sealed: true),
        SizedBox(width: 8),
        Text('P2 +1', style: TextStyle(color: AppColors.violet, fontSize: 12, fontWeight: FontWeight.w800)),
      ]),
    ]);

final _fuseSteps = [
  TutorialStep(
    title: 'Merge equal tiles',
    body: "Tap two adjacent tiles that show the same number — they merge into one tile worth one more.",
    visual: (_) => TutorialLoopDemo(frames: [
      const Row(mainAxisSize: MainAxisSize.min, children: [
        TileVisual(value: 2, color: AppColors.p1),
        SizedBox(width: 6),
        TileVisual(value: 2, color: AppColors.p1),
      ]),
      const Row(mainAxisSize: MainAxisSize.min, children: [
        TileVisual(value: 0, color: AppColors.p1, empty: true),
        SizedBox(width: 6),
        TileVisual(value: 3, color: AppColors.p1),
      ]),
    ]),
  ),
  TutorialStep(
    title: 'Reach 4 to claim the square',
    body: "Merge up to 4 and that square locks — sealed, scored, and yours.",
    visual: (_) => TutorialLoopDemo(frames: [
      const Row(mainAxisSize: MainAxisSize.min, children: [
        TileVisual(value: 3, color: AppColors.p2),
        SizedBox(width: 6),
        TileVisual(value: 3, color: AppColors.p2),
      ]),
      const Row(mainAxisSize: MainAxisSize.min, children: [
        TileVisual(value: 0, color: AppColors.p2, empty: true),
        SizedBox(width: 6),
        TileVisual(value: 4, color: AppColors.p2, sealed: true),
      ]),
    ]),
  ),
  const TutorialStep(
    title: 'Every merge passes the turn',
    body: "Unlike Pour, claiming a square in Fuse doesn't earn another turn. The board always shrinks by one tile per merge, so the game keeps moving to a natural end.",
    visual: _fuseAlternateVisual,
  ),
];

Widget _fuseAlternateVisual(BuildContext context) => TutorialLoopDemo(frames: [
      const Row(mainAxisSize: MainAxisSize.min, children: [
        _PlayerDot(color: AppColors.p1, active: true),
        SizedBox(width: 8),
        _PlayerDot(color: AppColors.p2, active: false),
      ]),
      const Row(mainAxisSize: MainAxisSize.min, children: [
        _PlayerDot(color: AppColors.p1, active: false),
        SizedBox(width: 8),
        _PlayerDot(color: AppColors.p2, active: true),
      ]),
    ]);

final _recipeSteps = [
  const TutorialStep(
    title: 'Build your secret formula',
    body: "You and your opponent each have a private, four-colour formula. Pour the shared tubes in the right order to fill your own vial.",
    visual: _recipeProgressVisual,
  ),
  TutorialStep(
    title: "Wrong order won't go in",
    body: 'Your vial only accepts the exact next colour your formula calls for — everything else simply refuses to pour in, so setting up the right top colour matters more than speed.',
    visual: (_) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const FormulaVisual(total: 4, filled: 1, color: AppColors.gold),
        const SizedBox(width: 10),
        Icon(Icons.block_rounded, color: AppColors.mute, size: 20),
      ],
    ),
  ),
  const TutorialStep(
    title: 'First to finish claims it',
    body: "Finish your formula before your opponent finishes theirs. If the shared tubes run dry first, whoever's further along wins the tie.",
    visual: _recipeCompleteVisual,
  ),
];

Widget _recipeProgressVisual(BuildContext context) => TutorialLoopDemo(frames: const [
      FormulaVisual(total: 4, filled: 1, color: AppColors.gold),
      FormulaVisual(total: 4, filled: 3, color: AppColors.gold),
    ]);

Widget _recipeCompleteVisual(BuildContext context) => const FormulaVisual(total: 4, filled: 4, color: AppColors.gold, complete: true);

class _PlayerDot extends StatelessWidget {
  final Color color;
  final bool active;
  const _PlayerDot({required this.color, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? color : Colors.transparent,
        border: Border.all(color: color, width: 2.5),
        boxShadow: active ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 10, spreadRadius: 1)] : null,
      ),
    );
  }
}
