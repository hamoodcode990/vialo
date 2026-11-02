import 'package:flutter/material.dart';

/// Plays a one-time scale+fade pop-in when first mounted, optionally
/// delayed — used to stagger a grid/row of cells into view (a "deal the
/// board" reveal) instead of every tile appearing fully-formed in the very
/// first frame.
///
/// This exists for two reasons at once: it reads as a deliberate, premium
/// entrance rather than the board just snapping into existence, *and* it
/// spreads the cost of painting many complex tiles (gem facets, glass
/// gradients) across the ~15-20 frames of the reveal instead of
/// concentrating all of it into the single frame where a page transition
/// also starts — which is what "menu to mode UI lags" actually is for a
/// 6x6 Fuse grid: 36 tiles, each with their own CustomPainter and (for
/// Fuse specifically) two AnimationControllers, all inflating and painting
/// for the first time in the same frame the incoming route's transition
/// begins.
///
/// The animated child is wrapped in its own [RepaintBoundary] so that once
/// the reveal finishes, this tile's ordinary state animations (shake,
/// settle, grow) never force sibling tiles to repaint, and the reveal
/// itself only has to rasterize the tile once and then composite a cached
/// layer at varying scale/opacity for the rest of its run.
class EntranceReveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const EntranceReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 240),
  });

  @override
  State<EntranceReveal> createState() => _EntranceRevealState();
}

class _EntranceRevealState extends State<EntranceReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  Animation<double>? _routeAnimation;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || _routeAnimation != null) return;
    // Waits for the route's own transition, so the board deals in after the
    // screen has arrived rather than during its fade.
    // On a pushed route's first frame the route is offstage and this animation
    // reports "completed" while the real one hasn't started yet, so that
    // frame doesn't count.
    final route = ModalRoute.of(context);
    final routeAnimation = route?.animation;
    if (routeAnimation == null || (routeAnimation.isCompleted && !route!.offstage)) {
      _start();
    } else {
      _routeAnimation = routeAnimation..addStatusListener(_onRouteStatus);
    }
  }

  void _onRouteStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    _routeAnimation = null;
    _start();
  }

  void _start() {
    _started = true;
    if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      child: RepaintBoundary(child: widget.child),
      builder: (context, child) {
        final scaleT = Curves.easeOutBack.transform(_ctrl.value);
        final fadeT = Curves.easeOut.transform(_ctrl.value);
        return Opacity(
          opacity: fadeT.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.55 + 0.45 * scaleT, child: child),
        );
      },
    );
  }
}
