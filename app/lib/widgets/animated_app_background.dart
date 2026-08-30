import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Full-screen soft gradient behind every screen, slowly drifting instead of
/// sitting as a static flat colour (CLAUDE.md Step 3 theme pass). Stays
/// within the warm ivory/parchment + emerald/rose/plum/gold palette — no
/// section gets its own distinct gradient yet, this is one shared backdrop
/// mounted once at the MaterialApp root via `builder:` so every Scaffold
/// (which is transparent, see buildAppTheme) shows it through.
///
/// Throttled to ~8 updates/sec via a [Timer] rather than a raw
/// [AnimationController] (which ticks every frame, forever — 60fps for the
/// app's entire lifetime just for a drift that takes 18s to cross). At this
/// drift speed the two are visually indistinguishable, but this is roughly
/// an 8x cut in how often a full-screen layer repaints, and it's wrapped in
/// a [RepaintBoundary] so that repaint never has to walk back up into
/// whatever's compositing on top of it (namely: every page-transition
/// animation the Navigator runs). Reported as sluggish page transitions —
/// this is the fix for that.
class AnimatedAppBackground extends StatefulWidget {
  final Widget child;
  const AnimatedAppBackground({super.key, required this.child});

  @override
  State<AnimatedAppBackground> createState() => _AnimatedAppBackgroundState();
}

class _AnimatedAppBackgroundState extends State<AnimatedAppBackground> {
  static const _period = Duration(seconds: 18);
  static const _tick = Duration(milliseconds: 120);

  final _stopwatch = Stopwatch()..start();
  Timer? _timer;
  double _t = 0;

  static const _a = [Color(0xFFFBF7EE), Color(0xFFF3E9FF), Color(0xFFE9FBF2), Color(0xFFFFF1E6)];
  static const _b = [Color(0xFFFFF1E6), Color(0xFFFBF7EE), Color(0xFFF3E9FF), Color(0xFFE9FBF2)];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_tick, (_) => _advance());
  }

  void _advance() {
    final phase = (_stopwatch.elapsedMilliseconds % (_period.inMilliseconds * 2)) / _period.inMilliseconds;
    // Ping-pong 0->1->0 over one full period, eased — same feel as the
    // previous AnimationController(..)..repeat(reverse: true).
    final raw = phase <= 1 ? phase : 2 - phase;
    final next = Curves.easeInOut.transform(raw);
    if ((next - _t).abs() < 0.001) return; // skip a redundant repaint
    setState(() => _t = next);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(_a[0], _b[0], _t)!,
              Color.lerp(_a[1], _b[1], _t)!,
              Color.lerp(_a[2], _b[2], _t)!,
              Color.lerp(_a[3], _b[3], _t)!,
            ],
            stops: const [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

/// Fallback flat colour for contexts that render before the animated
/// backdrop mounts (e.g. the native launch screen).
const kBackgroundFallback = AppColors.ink;
