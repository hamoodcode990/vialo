import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_controller.dart';
import '../game/game.dart';
import '../state/profile_provider.dart';
import '../theme/app_colors.dart';
import '../theme/mode_info.dart';
import '../theme/spacing.dart';
import '../theme/tube_palettes.dart';
import '../widgets/fuse_cell_view.dart';
import '../widgets/game_result_panel.dart';
import '../widgets/gem_painter.dart';
import 'duel_tube_game_screen.dart' show kBotBonus;

const double _kFuseCellSpacing = 7;
const double _kFuseGridPad = AppSpacing.md;

/// A merge in flight: the loser gem (at [from]) visibly slides into the
/// winner's cell (at [to]) before the engine move actually commits, so a
/// fusion reads as one gem giving itself up into the other rather than an
/// instant value swap. Step 2/5 of the Vialo UI/content batch.
class _FlyingGem {
  final int from;
  final int to;
  final int value;
  final Color color;
  const _FlyingGem({required this.from, required this.to, required this.value, required this.color});
}

class FuseGameScreen extends ConsumerStatefulWidget {
  final String mode; // ai | pass
  final String? aiKey;
  final int? levelNumber;

  const FuseGameScreen({super.key, required this.mode, this.aiKey, this.levelNumber});

  @override
  ConsumerState<FuseGameScreen> createState() => _FuseGameScreenState();
}

class _FuseGameScreenState extends ConsumerState<FuseGameScreen> with SingleTickerProviderStateMixin {
  late Fuse engine;
  late String effectiveAiKey;
  int? selected;
  int shakeCell = -1;
  int shakeTrigger = 0;
  bool thinking = false;
  bool finished = false;
  ({bool won, int? stars, int? coins})? levelResult;
  late final AnimationController _flyCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 230));
  _FlyingGem? _flying;

  @override
  void initState() {
    super.initState();
    _initGame();
    if (widget.mode == 'ai' && engine.turn == 1) _aiTurn();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(audioControllerProvider).playGameMusic();
    });
  }

  void _initGame() {
    effectiveAiKey = widget.aiKey ?? 'normal';
    if (widget.levelNumber != null) effectiveAiKey = fuseLvlCfg(widget.levelNumber!);
    final seed = widget.levelNumber != null
        ? modeSeed('fuse', widget.levelNumber!)
        : (DateTime.now().millisecondsSinceEpoch % 900000) + math.Random().nextInt(999);
    engine = Fuse(seed);
  }

  List<String> get _names =>
      widget.mode == 'ai' ? ['You', '${kAiProfiles[effectiveAiKey]!.name} bot'] : ['Player 1', 'Player 2'];

  bool get _isLevelRun => widget.levelNumber != null;

  void _tap(int i) {
    if (engine.over || thinking) return;
    if (widget.mode == 'ai' && engine.turn != 0) return;
    if (selected == null) {
      if (engine.grid[i] == 0 || engine.sealed[i]) return;
      final hasTarget = List.generate(engine.grid.length, (b) => b).any((b) => engine.canAct(i, b));
      if (!hasTarget) {
        ref.read(audioControllerProvider).invalidMove();
        setState(() {
          shakeCell = i;
          shakeTrigger++;
        });
        return;
      }
      ref.read(audioControllerProvider).pick();
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
    ref.read(audioControllerProvider).invalidMove();
    setState(() {
      shakeCell = selected!;
      shakeTrigger++;
    });
  }

  Color _colorOf(int i) => tubePaletteById(ref.read(profileProvider).paletteId)[i];

  void _performMove(int a, int b) async {
    setState(() {
      _flying = _FlyingGem(from: a, to: b, value: engine.grid[a], color: _colorOf(engine.grid[a] - 1));
    });
    await _flyCtrl.forward(from: 0);
    if (!mounted) return;
    final result = engine.act(a, b);
    final audio = ref.read(audioControllerProvider);
    if (result?.sealed != null) {
      audio.claim();
    } else if (result?.value != null) {
      audio.fuseMerge(result!.value!);
    }
    setState(() => _flying = null);
    if (engine.over) {
      _finish();
      return;
    }
    if (widget.mode == 'ai' && engine.turn == 1) _aiTurn();
  }

  @override
  void dispose() {
    ref.read(audioControllerProvider).playMenuMusic();
    _flyCtrl.dispose();
    super.dispose();
  }

  Offset _cellOrigin(int index, double cw) {
    final row = index ~/ engine.w, col = index % engine.w;
    return Offset(
      _kFuseGridPad + col * (cw + _kFuseCellSpacing),
      _kFuseGridPad + row * (cw + _kFuseCellSpacing),
    );
  }

  Widget _buildFlyingGem(_FlyingGem f, double cw) {
    final start = _cellOrigin(f.from, cw);
    final end = _cellOrigin(f.to, cw);
    return AnimatedBuilder(
      animation: _flyCtrl,
      builder: (context, child) {
        final t = Curves.easeInCubic.transform(_flyCtrl.value);
        final arc = -cw * 0.4 * math.sin(t * math.pi); // brief hop over the board, not a straight slide
        final pos = Offset(start.dx + (end.dx - start.dx) * t, start.dy + (end.dy - start.dy) * t + arc);
        final scale = 1.0 - 0.18 * t; // gives itself up into the target on arrival
        return Positioned(
          left: pos.dx,
          top: pos.dy,
          width: cw,
          height: cw,
          child: IgnorePointer(
            child: Transform.scale(
              scale: scale,
              child: Center(child: GemGlyph(size: cw * 0.86, value: f.value, color: f.color)),
            ),
          ),
        );
      },
    );
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
    final audio = ref.read(audioControllerProvider);
    final won = widget.mode == 'ai' && engine.leader == 0;

    if (widget.mode == 'ai') {
      won ? audio.levelWin() : audio.levelLose();
      ctrl.recordAiResult('fuse', won, engine.scores[0]);
      if (won) {
        ctrl.addCoins(kBotBonus[effectiveAiKey] ?? 0);
        audio.coinGain();
      }
    } else {
      ctrl.recordPassPlay();
    }

    if (_isLevelRun) {
      if (won) {
        final stars = duelStars(kind: 'fuse', myScore: engine.scores[0], oppScore: engine.scores[1], colors: 0);
        final coins = ctrl.recordLevelWin('fuse', widget.levelNumber!, stars);
        audio.coinGain();
        levelResult = (won: true, stars: stars, coins: coins);
      } else {
        ctrl.loseLife();
        levelResult = (won: false, stars: null, coins: null);
      }
    }
    setState(() {});
  }

  void _restart() {
    setState(() {
      selected = null;
      thinking = false;
      finished = false;
      levelResult = null;
      _initGame();
    });
    if (widget.mode == 'ai' && engine.turn == 1) _aiTurn();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final palette = tubePaletteById(profile.paletteId);
    Color colorOf(int idx) => palette[idx];
    final info = modeInfoFor('fuse');
    final names = _names;

    return Scaffold(
      appBar: AppBar(title: Text(_isLevelRun ? '${info.name} · Level ${widget.levelNumber}' : info.name)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Opacity(
                    opacity: engine.turn == 0 && !engine.over ? 1 : 0.35,
                    child: _PlayerScore(name: names[0], score: engine.scores[0], color: AppColors.p1),
                  ),
                  const Spacer(),
                  Opacity(
                    opacity: engine.turn == 1 && !engine.over ? 1 : 0.35,
                    child: _PlayerScore(name: names[1], score: engine.scores[1], color: AppColors.p2, alignRight: true),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final avail = constraints.maxWidth.clamp(0, 540) - 40 - (engine.w - 1) * 6;
                    final cw = (avail / engine.w).floorToDouble().clamp(38.0, 56.0);
                    return Stack(
                      alignment: Alignment.topLeft,
                      clipBehavior: Clip.none,
                      children: [
                        GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: engine.w,
                      mainAxisSpacing: _kFuseCellSpacing,
                      crossAxisSpacing: _kFuseCellSpacing,
                      childAspectRatio: 1,
                      padding: const EdgeInsets.all(_kFuseGridPad),
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (var i = 0; i < engine.grid.length; i++)
                          FuseCellView(
                            size: cw,
                            value: i == _flying?.from ? 0 : engine.grid[i],
                            sealed: engine.sealed[i],
                            owner: engine.owner[i],
                            colorOf: colorOf,
                            selected: selected == i,
                            isTarget: selected != null && engine.canAct(selected!, i),
                            dimmed: selected != null && selected != i && !engine.canAct(selected!, i),
                            shakeTrigger: shakeCell == i ? shakeTrigger : 0,
                            onTap: () => _tap(i),
                          ),
                      ],
                        ),
                        if (_flying != null) _buildFlyingGem(_flying!, cw),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (engine.over)
              Padding(padding: const EdgeInsets.only(bottom: AppSpacing.lg), child: _buildResult(context, names))
            else
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                child: Text(
                  thinking ? '${names[1]} is thinking…' : (widget.mode == 'ai' ? 'Your move' : "${names[engine.turn]} — your move"),
                  style: TextStyle(color: thinking ? AppColors.p2 : (engine.turn == 0 ? AppColors.p1 : AppColors.p2), fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(BuildContext context, List<String> names) {
    final l = engine.leader;
    if (_isLevelRun) {
      final r = levelResult!;
      return GameResultPanel(
        title: r.won ? 'Level cleared' : 'Level lost',
        color: r.won ? AppColors.p1 : AppColors.hot,
        subtitle: '${engine.scores[0]} — ${engine.scores[1]} · no fusions left${r.won ? ' · +${r.coins} coins' : ' · −1 life'}',
        stars: r.won ? r.stars : null,
        actions: [
          if (!r.won) primaryAction('Retry', _restart),
          secondaryAction('Levels', () => Navigator.of(context).pop()),
        ],
      );
    }
    final title = widget.mode == 'ai' ? (l == 0 ? 'You win' : 'You lose') : '${names[l]} wins';
    final color = l == 0 ? AppColors.p1 : AppColors.p2;
    return GameResultPanel(
      title: title,
      color: color,
      subtitle: '${engine.scores[0]} — ${engine.scores[1]} (½ to second player) · no fusions left',
      actions: [
        primaryAction('Rematch', _restart),
        secondaryAction('Menu', () => Navigator.of(context).popUntil((r) => r.isFirst)),
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
