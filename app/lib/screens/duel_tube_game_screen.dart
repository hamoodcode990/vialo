import 'dart:async';
import 'dart:math' as math;

// `Split` exists both as our engine class and (since a recent Flutter
// version) an animation-curve helper in material.dart — hide the latter.
import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game.dart';
import '../state/profile_provider.dart';
import '../theme/app_colors.dart';
import '../theme/mode_info.dart';
import '../theme/spacing.dart';
import '../theme/tube_palettes.dart';
import '../widgets/game_result_panel.dart';
import '../widgets/tube_view.dart';

const Map<String, int> kBotBonus = {'easy': 25, 'normal': 40, 'hard': 60};

/// Pour, Split and Recipe all share this board (a row of tubes) and this
/// interaction model (tap to lift, tap again to pour) — port of
/// decant.html's `tap()`/`pourMove()`/`draw()` for the tube-based modes.
class DuelTubeGameScreen extends ConsumerStatefulWidget {
  final String kind; // pour | split | recipe
  final String mode; // ai | pass
  final String? aiKey;
  final int? levelNumber;
  final String format; // pour quick-match only: standard | blitz

  const DuelTubeGameScreen({
    super.key,
    required this.kind,
    required this.mode,
    this.aiKey,
    this.levelNumber,
    this.format = 'standard',
  });

  @override
  ConsumerState<DuelTubeGameScreen> createState() => _DuelTubeGameScreenState();
}

class _DuelTubeGameScreenState extends ConsumerState<DuelTubeGameScreen> {
  late TubeGameEngine engine;
  late String effectiveAiKey;
  int? selected;
  int shakeTrigger = 0;
  int? shakeTube;
  bool thinking = false;
  bool finished = false;
  ({bool won, int? stars, int? coins})? levelResult;

  @override
  void initState() {
    super.initState();
    _initGame();
    if (widget.mode == 'ai' && engine.turn == 1) _aiTurn();
  }

  void _initGame() {
    effectiveAiKey = widget.aiKey ?? 'normal';
    final int seed;
    if (widget.levelNumber != null) {
      seed = modeSeed(widget.kind, widget.levelNumber!);
    } else {
      seed = (DateTime.now().millisecondsSinceEpoch % 900000) + math.Random().nextInt(999);
    }

    switch (widget.kind) {
      case 'pour':
        if (widget.levelNumber != null) {
          final cfg = pourLvlCfg(widget.levelNumber!);
          effectiveAiKey = cfg.ai;
          engine = Pour(seed, cfg.colors, cfg.empty);
        } else {
          final blitz = widget.format == 'blitz';
          engine = Pour(seed, blitz ? 7 : 9, blitz ? 3 : 5);
        }
      case 'split':
        if (widget.levelNumber != null) {
          final cfg = splitLvlCfg(widget.levelNumber!);
          effectiveAiKey = cfg.ai;
          engine = Split(seed, cfg.colors, cfg.empty, cfg.own);
        } else {
          engine = Split(seed, 7, 3, 3);
        }
      case 'recipe':
        if (widget.levelNumber != null) {
          effectiveAiKey = recipeLvlCfg(widget.levelNumber!);
        }
        engine = Recipe(seed);
      default:
        throw ArgumentError('unknown tube kind ${widget.kind}');
    }
  }

  List<String> get _names => widget.mode == 'ai'
      ? ['You', '${kAiProfiles[effectiveAiKey]!.name} bot']
      : ['Player 1', 'Player 2'];

  bool get _isLevelRun => widget.levelNumber != null;

  void _tap(int i) {
    if (engine.over || thinking) return;
    if (widget.mode == 'ai' && engine.turn != 0) return;
    if (selected == null) {
      if (engine.tubes[i].isEmpty || engine.sealed[i]) return;
      final hasTarget = List.generate(engine.tubes.length, (d) => d).any((d) => engine.canAct(i, d));
      if (!hasTarget) {
        setState(() {
          shakeTube = i;
          shakeTrigger++;
        });
        return;
      }
      setState(() => selected = i);
      return;
    }
    if (selected == i) {
      setState(() => selected = null);
      return;
    }
    if (engine.canAct(selected!, i)) {
      final s = selected!;
      setState(() => selected = null);
      _performMove(s, i);
      return;
    }
    setState(() {
      shakeTube = selected;
      shakeTrigger++;
    });
  }

  void _performMove(int s, int d) {
    engine.act(s, d);
    if (!mounted) return;
    setState(() {});
    if (engine.over) {
      _finish();
      return;
    }
    if (widget.mode == 'ai' && engine.turn == 1) _aiTurn();
  }

  Future<void> _aiTurn() async {
    setState(() => thinking = true);
    await Future.delayed(Duration(milliseconds: 380 + math.Random().nextInt(340)));
    if (!mounted) return;
    final profile = kAiProfiles[effectiveAiKey]!;
    final rnd = mb32(DateTime.now().millisecondsSinceEpoch & 0xffff);
    final m = best(engine, profile.depth, profile.blunder, rnd);
    if (!mounted) return;
    setState(() => thinking = false);
    if (m == null) {
      if (engine.over) _finish();
      return;
    }
    _performMove(m.$1, m.$2);
  }

  void _finish() {
    if (finished) return;
    finished = true;
    final ctrl = ref.read(profileControllerProvider.notifier);
    final won = widget.mode == 'ai' && engine.leader == 0;

    if (widget.mode == 'ai') {
      ctrl.recordAiResult(widget.kind, won, engine.scores[0]);
      if (won) ctrl.addCoins(kBotBonus[effectiveAiKey] ?? 0);
    } else {
      ctrl.recordPassPlay();
    }

    if (_isLevelRun) {
      if (won) {
        final stars = duelStars(
          kind: widget.kind,
          myScore: engine.scores[0],
          oppScore: engine.scores[1],
          colors: engine.colors,
        );
        final coins = ctrl.recordLevelWin(widget.kind, widget.levelNumber!, stars);
        levelResult = (won: true, stars: stars, coins: coins);
      } else {
        ctrl.loseLife();
        levelResult = (won: false, stars: null, coins: null);
      }
    }
    setState(() {});
  }

  double _tubeWidth(double avail, int n) {
    final per = n <= 7 ? n : (n / 2).ceil();
    final a = avail.clamp(0, 540) - 22 - (per - 1) * 7;
    return (a / per).floorToDouble().clamp(28.0, 52.0);
  }

  String? _capLabel(int i) {
    if (widget.kind == 'recipe') {
      if (i >= kRecipeSrc) return i - kRecipeSrc == 0 ? 'YOUR VIAL' : 'THEIR VIAL';
      return '';
    }
    if (widget.kind != 'split') return engine.sealed[i] ? '●' : '';
    final t = engine.tubes[i];
    if (t.isEmpty) return '';
    final o = (engine as Split).colOwner(t.last);
    return o == 0 ? 'YOU' : (o == 1 ? 'THEM' : 'GOLD');
  }

  Color? _capColor(int i) {
    if (widget.kind == 'recipe') {
      if (i >= kRecipeSrc) return i - kRecipeSrc == 0 ? AppColors.p1 : AppColors.p2;
      return null;
    }
    if (widget.kind != 'split') return null;
    final t = engine.tubes[i];
    if (t.isEmpty) return null;
    final o = (engine as Split).colOwner(t.last);
    return o == 0 ? AppColors.p1 : (o == 1 ? AppColors.p2 : AppColors.gold);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final palette = tubePaletteById(profile.paletteId);
    Color colorOf(int idx) => palette[idx];
    final info = modeInfoFor(widget.kind);
    final names = _names;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLevelRun ? '${info.name} · Level ${widget.levelNumber}' : info.name),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _ScoreRow(
                names: names,
                scores: engine.scores,
                turn: engine.turn,
                over: engine.over,
                claimed: engine.scores[0] + engine.scores[1],
                total: widget.kind == 'recipe' ? kCap * 2 : engine.colors,
                label: widget.kind == 'recipe' ? 'BLENDED' : 'CLAIMED',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = _tubeWidth(constraints.maxWidth, engine.tubes.length);
                    return SingleChildScrollView(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        spacing: 7,
                        runSpacing: 14,
                        children: [
                          for (var i = 0; i < engine.tubes.length; i++)
                            TubeView(
                              width: w,
                              capacity: kCap,
                              contents: engine.tubes[i],
                              colorOf: colorOf,
                              sealed: engine.sealed[i],
                              selected: selected == i,
                              isTarget: selected != null && engine.canAct(selected!, i),
                              dimmed: selected != null && selected != i && !engine.canAct(selected!, i),
                              capLabel: _capLabel(i),
                              capColor: _capColor(i),
                              shakeTrigger: shakeTube == i ? shakeTrigger : 0,
                              onTap: () => _tap(i),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            if (engine.over)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: _buildResult(context, names),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                child: Text(
                  thinking ? '${names[1]} is thinking…' : (widget.mode == 'ai' ? 'Your move' : "${names[engine.turn]} — your move"),
                  style: TextStyle(
                    color: thinking ? AppColors.p2 : (engine.turn == 0 ? AppColors.p1 : AppColors.p2),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(BuildContext context, List<String> names) {
    final l = engine.leader;
    final why = engine.stall >= kStall ? 'board stalled' : 'board locked';
    if (_isLevelRun) {
      final r = levelResult!;
      return GameResultPanel(
        title: r.won ? 'Level cleared' : 'Level lost',
        color: r.won ? AppColors.p1 : AppColors.hot,
        subtitle: '${engine.scores[0]} — ${engine.scores[1]} · $why${r.won ? ' · +${r.coins} coins' : ' · −1 life'}',
        stars: r.won ? r.stars : null,
        actions: [
          if (!r.won) primaryAction('Retry', () => _restart(sameLevel: true)),
          secondaryAction('Levels', () => Navigator.of(context).pop()),
        ],
      );
    }
    final title = widget.mode == 'ai' ? (l == 0 ? 'You win' : (l == 1 ? 'You lose' : 'Draw')) : (l == -1 ? 'Draw' : '${names[l]} wins');
    final color = l == 0 ? AppColors.p1 : (l == 1 ? AppColors.p2 : AppColors.mute);
    return GameResultPanel(
      title: title,
      color: color,
      subtitle: '${engine.scores[0]} — ${engine.scores[1]}${engine.komi ? ' (½ to second player)' : ''} · $why',
      actions: [
        primaryAction('Rematch', () => _restart(sameLevel: false)),
        secondaryAction('Menu', () => Navigator.of(context).popUntil((r) => r.isFirst)),
      ],
    );
  }

  void _restart({required bool sameLevel}) {
    setState(() {
      selected = null;
      thinking = false;
      finished = false;
      levelResult = null;
      _initGame();
    });
    if (widget.mode == 'ai' && engine.turn == 1) _aiTurn();
  }
}

class _ScoreRow extends StatelessWidget {
  final List<String> names;
  final List<int> scores;
  final int turn;
  final bool over;
  final int claimed;
  final int total;
  final String label;

  const _ScoreRow({
    required this.names,
    required this.scores,
    required this.turn,
    required this.over,
    required this.claimed,
    required this.total,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final f0 = scores[0] * 100 + 1;
    final f1 = scores[1] * 100 + 1;
    final fm = math.max(1, (total - claimed)) * 100 + 1;
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Opacity(
              opacity: turn == 0 && !over ? 1 : 0.35,
              child: _PlayerScore(name: names[0], score: scores[0], color: AppColors.p1),
            ),
            Expanded(
              child: Column(
                children: [
                  Text('$claimed/$total', style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(label, style: const TextStyle(fontSize: 8.5, letterSpacing: 1.4, color: AppColors.mute)),
                ],
              ),
            ),
            Opacity(
              opacity: turn == 1 && !over ? 1 : 0.35,
              child: _PlayerScore(name: names[1], score: scores[1], color: AppColors.p2, alignRight: true),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            height: 4,
            child: Row(
              children: [
                Expanded(flex: f0, child: Container(color: AppColors.p1)),
                Expanded(flex: fm, child: Container(color: AppColors.edge)),
                Expanded(flex: f1, child: Container(color: AppColors.p2)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerScore extends StatelessWidget {
  final String name;
  final int score;
  final Color color;
  final bool alignRight;
  const _PlayerScore({required this.name, required this.score, required this.color, this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        Text('$score', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}
