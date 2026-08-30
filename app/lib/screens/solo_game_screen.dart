import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_controller.dart';
import '../game/game.dart';
import '../state/profile_provider.dart';
import '../theme/app_colors.dart';
import '../theme/spacing.dart';
import '../theme/tube_palettes.dart';
import '../widgets/app_route.dart';
import '../widgets/game_result_panel.dart';
import '../widgets/pour_flight_overlay.dart';
import '../widgets/tube_view.dart';

/// Solo sort: a single-player board with a free undo, paid extra undos, and
/// two coin-priced hints. Port of decant.html's `drawSolo`/`tapSolo`.
class SoloGameScreen extends ConsumerStatefulWidget {
  final int? levelNumber; // null = Shuffle (no level attached, no lives cost)
  final int shuffleColors;
  final bool isDaily;

  const SoloGameScreen({
    super.key,
    this.levelNumber,
    this.shuffleColors = 6,
    this.isDaily = false,
  });

  @override
  ConsumerState<SoloGameScreen> createState() => _SoloGameScreenState();
}

class _SoloGameScreenState extends ConsumerState<SoloGameScreen> {
  late SoloBoard board;
  int? selected;
  int shakeTube = -1;
  int shakeTrigger = 0;
  (int, int)? hint;
  Timer? _ticker;
  DateTime? _startedAt;
  int? starsEarned;
  int? coinsEarned;
  List<String> newlyUnlockedAvatars = [];
  bool _lifeSpent = false;
  bool animating = false;

  final GlobalKey _boardKey = GlobalKey();
  final GlobalKey<PourFlightOverlayState> _flightKey = GlobalKey();
  List<GlobalKey> _tubeKeys = [];

  @override
  void initState() {
    super.initState();
    _initBoard();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _startedAt != null && !board.done && !board.failed) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(audioControllerProvider).playGameMusic();
    });
  }

  @override
  void dispose() {
    ref.read(audioControllerProvider).playMenuMusic();
    _ticker?.cancel();
    super.dispose();
  }

  void _initBoard() {
    final int seed;
    final int colors, empty;
    if (widget.isDaily) {
      final ds = _todayStr(DateTime.now());
      seed = dailySeed(ds);
      colors = 6;
      empty = 2;
    } else if (widget.levelNumber != null) {
      final cfg = soloCfg(widget.levelNumber!);
      seed = modeSeed('solo', widget.levelNumber!);
      colors = cfg.colors;
      empty = cfg.empty;
    } else {
      seed =
          (DateTime.now().millisecondsSinceEpoch % 900000) +
          math.Random().nextInt(999);
      colors = widget.shuffleColors;
      empty = 2;
    }
    board = SoloBoard(seed: seed, colors: colors, empty: empty);
    _tubeKeys = List.generate(board.tubes.length, (_) => GlobalKey());
    _startedAt = null;
    starsEarned = null;
    coinsEarned = null;
    newlyUnlockedAvatars = [];
    _lifeSpent = false;
  }

  void _tap(int i) {
    if (board.done || board.failed || animating) return;
    if (selected == null) {
      if (board.tubes[i].isEmpty) return;
      selected = i;
      hint = null;
      setState(() {});
      return;
    }
    if (selected == i) {
      setState(() => selected = null);
      return;
    }
    if (!board.legal(selected!, i)) {
      ref.read(audioControllerProvider).invalidMove();
      setState(() {
        shakeTube = selected!;
        shakeTrigger++;
      });
      return;
    }
    _startedAt ??= DateTime.now();
    final s = selected!;
    setState(() => selected = null);
    _startPour(s, i);
  }

  /// Plays the flying-droplet animation (Step 5) then commits the actual
  /// pour once the last drop lands — see DuelTubeGameScreen's twin of this
  /// for the full rationale (mirrors decant.html's animPour-then-act
  /// ordering). Falls back to an immediate pour if rects aren't measurable.
  void _startPour(int s, int d) {
    final srcTube = board.tubes[s];
    final col = srcTube.last;
    var n = 0, k = srcTube.length - 1;
    while (k >= 0 && srcTube[k] == col && (board.tubes[d].length + n) < kCap) {
      n++;
      k--;
    }
    final boardBox = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    final srcBox =
        _tubeKeys[s].currentContext?.findRenderObject() as RenderBox?;
    final dstBox =
        _tubeKeys[d].currentContext?.findRenderObject() as RenderBox?;
    if (n == 0 || boardBox == null || srcBox == null || dstBox == null) {
      _commitPour(s, d);
      return;
    }
    final srcRect =
        srcBox.localToGlobal(Offset.zero, ancestor: boardBox) & srcBox.size;
    final dstRect =
        dstBox.localToGlobal(Offset.zero, ancestor: boardBox) & dstBox.size;
    final palette = tubePaletteById(ref.read(profileProvider).paletteId);
    setState(() => animating = true);
    final audio = ref.read(audioControllerProvider);
    for (var i = 0; i < n; i++) {
      Future.delayed(Duration(milliseconds: i * 72), () => audio.pourDrip(i));
      Future.delayed(Duration(milliseconds: i * 72 + 475), audio.splash);
    }
    _flightKey.currentState!.playPour(
      from: srcRect,
      to: dstRect,
      color: palette[col],
      count: n,
      onDone: () {
        if (!mounted) return;
        setState(() => animating = false);
        _commitPour(s, d);
      },
    );
  }

  void _commitPour(int s, int d) {
    board.pour(s, d);
    final destTube = board.tubes[d];
    if (destTube.length == kCap && destTube.every((v) => v == destTube[0])) {
      ref.read(audioControllerProvider).claim();
    }
    if (board.done) {
      _onSolved();
    } else if (board.failed) {
      _onFailed();
    }
    if (!mounted) return;
    setState(() {});
  }

  void _onSolved() {
    final audio = ref.read(audioControllerProvider);
    audio.levelWin();
    if (widget.isDaily) {
      final earned = ref.read(profileControllerProvider.notifier).completeDailyNow();
      if (earned) audio.coinGain();
      return;
    }
    if (widget.levelNumber == null) return; // Shuffle: no economy hooks
    final par = soloPar(board.colors, board.empty);
    final stars = soloStars(
      usedHint: board.usedHint,
      moves: board.moves,
      par: par,
    );
    final result = ref
        .read(profileControllerProvider.notifier)
        .recordLevelWin('solo', widget.levelNumber!, stars);
    audio.coinGain();
    starsEarned = stars;
    coinsEarned = result.coinsEarned;
    newlyUnlockedAvatars = result.newlyUnlockedAvatars;
  }

  void _onFailed() {
    ref.read(audioControllerProvider).levelLose();
    if (widget.isDaily || widget.levelNumber == null) {
      return; // no lives cost for daily/shuffle
    }
    if (!_lifeSpent) {
      ref.read(profileControllerProvider.notifier).loseLife();
      _lifeSpent = true;
    }
  }

  void _restart({bool chargeIfUnsolved = false}) {
    if (chargeIfUnsolved &&
        !widget.isDaily &&
        widget.levelNumber != null &&
        !board.done &&
        !board.failed) {
      ref.read(profileControllerProvider.notifier).loseLife();
    }
    setState(_initBoard);
  }

  void _undo() {
    if (!board.canUndo) return;
    final ctrl = ref.read(profileControllerProvider.notifier);
    if (board.freeUndo > 0) {
      board.freeUndo--;
    } else {
      if (!ctrl.spendCoins(20)) {
        _toast('Not enough coins for an extra undo');
        return;
      }
    }
    board.undo();
    setState(() {});
  }

  void _revealHint() {
    final ctrl = ref.read(profileControllerProvider.notifier);
    final m = board.hintMove();
    if (m == null) {
      _toast('No legal move available');
      return;
    }
    if (!ctrl.spendCoins(40)) {
      _toast('Not enough coins');
      return;
    }
    board.usedHint = true;
    setState(() => hint = m);
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (mounted) setState(() => hint = null);
    });
  }

  void _addTubeHint() {
    final ctrl = ref.read(profileControllerProvider.notifier);
    if (!ctrl.spendCoins(60)) {
      _toast('Not enough coins');
      return;
    }
    setState(() {
      board.addTube();
      while (_tubeKeys.length < board.tubes.length) {
        _tubeKeys.add(GlobalKey());
      }
    });
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  double _tubeWidth(double avail, int n) {
    final per = n <= 7 ? n : (n / 2).ceil();
    final a = avail.clamp(0, 540) - 22 - (per - 1) * 7;
    return (a / per).floorToDouble().clamp(28, 52);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final palette = tubePaletteById(profile.paletteId);
    Color colorOf(int idx) => palette[idx];
    final secs = _startedAt == null
        ? 0
        : DateTime.now().difference(_startedAt!).inSeconds;
    final solvedCount = board.tubes
        .where((t) => t.length == kCap && t.every((v) => v == t[0]))
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isDaily
              ? "Today's Pour"
              : (widget.levelNumber != null
                    ? 'Level ${widget.levelNumber}'
                    : 'Solo sort'),
        ),
        actions: [
          IconButton(
            onPressed: board.canUndo ? _undo : null,
            icon: const Icon(Icons.undo_rounded),
            tooltip: board.freeUndo > 0 ? 'Undo' : 'Undo (20 coins)',
          ),
          IconButton(
            onPressed: () => _restart(chargeIfUnsolved: true),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Restart',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Stat(
                    label: 'TIME',
                    value:
                        '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}',
                  ),
                  _Stat(
                    label: 'MOVES',
                    value: '${board.moves}',
                    alignCenter: true,
                  ),
                  _Stat(
                    label: 'SOLVED',
                    value: '$solvedCount/${board.colors}',
                    alignRight: true,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = _tubeWidth(
                      constraints.maxWidth,
                      board.tubes.length,
                    );
                    return Stack(
                      key: _boardKey,
                      clipBehavior: Clip.none,
                      children: [
                        SingleChildScrollView(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.end,
                            spacing: 7,
                            runSpacing: 14,
                            children: [
                              for (var i = 0; i < board.tubes.length; i++)
                                TubeView(
                                  key: _tubeKeys[i],
                                  index: i,
                                  width: w,
                                  capacity: kCap,
                                  contents: board.tubes[i],
                                  colorOf: colorOf,
                                  selected: selected == i,
                                  isTarget:
                                      (selected != null &&
                                          board.legal(selected!, i)) ||
                                      (hint != null &&
                                          (hint!.$1 == i || hint!.$2 == i)),
                                  dimmed:
                                      selected != null &&
                                      selected != i &&
                                      !board.legal(selected!, i),
                                  shakeTrigger: shakeTube == i
                                      ? shakeTrigger
                                      : 0,
                                  onTap: () => _tap(i),
                                ),
                            ],
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: PourFlightOverlay(key: _flightKey),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (board.done || board.failed)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: _buildResult(context, secs),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                child: Column(
                  children: [
                    const Text(
                      'Tap to lift · tap again to pour',
                      style: TextStyle(fontSize: 12, color: AppColors.mute),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _HintChip(
                          label: '💡 Reveal move · 40🪙',
                          onTap: _revealHint,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _HintChip(
                          label: '🧪 Add tube · 60🪙',
                          onTap: _addTubeHint,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(BuildContext context, int secs) {
    if (board.done) {
      final timeStr = '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
      final List<Widget> actions;
      if (widget.isDaily) {
        actions = [
          primaryAction(
            'Done',
            () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ];
      } else if (widget.levelNumber != null) {
        actions = [
          primaryAction('Next level', () {
            Navigator.of(context).pushReplacement(
              AppRoute(
                builder: (_) =>
                    SoloGameScreen(levelNumber: widget.levelNumber! + 1),
              ),
            );
          }),
          secondaryAction('Levels', () => Navigator.of(context).pop()),
        ];
      } else {
        actions = [
          primaryAction('Next board', () => setState(_initBoard)),
          secondaryAction(
            'Menu',
            () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ];
      }
      return GameResultPanel(
        title: widget.isDaily ? 'Solved for today' : 'Solved',
        color: AppColors.p1,
        stars: (!widget.isDaily && widget.levelNumber != null)
            ? starsEarned
            : null,
        subtitle: widget.isDaily
            ? '$timeStr · ${board.moves} moves · 🔥 streak +1 · +50 coins'
            : '$timeStr · ${board.moves} moves${coinsEarned != null ? ' · +$coinsEarned coins' : ''}',
        unlockedAvatarIds: newlyUnlockedAvatars,
        actions: actions,
      );
    }
    return GameResultPanel(
      title: 'No moves left',
      color: AppColors.hot,
      subtitle: (!widget.isDaily && widget.levelNumber != null)
          ? 'This attempt cost a life.'
          : 'This board is stuck — try another.',
      actions: widget.isDaily
          ? [
              primaryAction(
                'Menu',
                () => Navigator.of(context).popUntil((r) => r.isFirst),
              ),
            ]
          : (widget.levelNumber != null
                ? [
                    primaryAction('Retry', () => setState(_initBoard)),
                    secondaryAction(
                      'Levels',
                      () => Navigator.of(context).pop(),
                    ),
                  ]
                : [
                    primaryAction('New board', () => setState(_initBoard)),
                    secondaryAction(
                      'Menu',
                      () => Navigator.of(context).popUntil((r) => r.isFirst),
                    ),
                  ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final bool alignCenter;
  final bool alignRight;
  const _Stat({
    required this.label,
    required this.value,
    this.alignCenter = false,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignCenter
          ? CrossAxisAlignment.center
          : (alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start),
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w700,
            color: AppColors.mute,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _HintChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _HintChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.ink2,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.outline, width: 2.5),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

String _todayStr(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
