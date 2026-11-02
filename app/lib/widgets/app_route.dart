import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'animated_app_background.dart';

/// Menu to menu: the native iOS slide, with swipe-back. Every route paints its
/// own opaque backdrop, because Scaffolds here are transparent; without one,
/// the screen underneath shows through for the whole transition.
class AppRoute<T> extends CupertinoPageRoute<T> {
  AppRoute({required WidgetBuilder builder})
      : super(builder: (context) => AnimatedAppBackground(child: builder(context)));
}

/// How long each half of the fade-through takes.
const int kFadeOutMs = 100;
const int kFadeInMs = 220;
const int _kFadeThroughMs = kFadeOutMs + kFadeInMs;

/// One frame of a fade-through. Opacity of the cover painted over the old
/// screen, and opacity and scale of the new one.
({double cover, double content, double scale}) fadeThroughAt(double value) {
  final ms = value * _kFadeThroughMs;
  final cover = (ms / kFadeOutMs).clamp(0.0, 1.0);
  final inT = Curves.easeOutCubic.transform(((ms - kFadeOutMs) / kFadeInMs).clamp(0.0, 1.0));
  return (cover: cover, content: inT, scale: 0.97 + 0.03 * inT);
}

/// The same, leaving a game: its content goes first, in [kFadeOutMs], then
/// the cover lifts over the rest. [value] runs 1 to 0, as a popping route's
/// animation does.
({double cover, double content, double scale}) fadeThroughReverseAt(double value) {
  final ms = (1 - value) * _kFadeThroughMs;
  final content = (1 - ms / kFadeOutMs).clamp(0.0, 1.0);
  final cover = 1 - Curves.easeOutCubic.transform(((ms - kFadeOutMs) / kFadeInMs).clamp(0.0, 1.0));
  return (cover: cover, content: content, scale: 1.0);
}

/// Into and out of gameplay: the old screen fades out completely, then the
/// new one fades in. The backdrop is the cover, so the old screen is fully
/// hidden long before Flutter stops painting it, and it can never disappear
/// in a single frame.
class GameRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;
  GameRoute({required this.builder});

  @override
  Duration get transitionDuration => const Duration(milliseconds: _kFadeThroughMs);
  @override
  Color? get barrierColor => null;
  @override
  String? get barrierLabel => null;
  @override
  bool get maintainState => true;
  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) => false;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) =>
      builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return _FadeThrough(animation: animation, reduceMotion: reduceMotion, child: child);
  }
}

class _FadeThrough extends StatelessWidget {
  final Animation<double> animation;
  final bool reduceMotion;
  final Widget child;
  const _FadeThrough({required this.animation, required this.reduceMotion, required this.child});

  @override
  Widget build(BuildContext context) {
    final page = RepaintBoundary(child: child);
    return AnimatedBuilder(
      animation: animation,
      child: page,
      builder: (context, page) {
        final v = animation.status == AnimationStatus.reverse
            ? fadeThroughReverseAt(animation.value)
            : fadeThroughAt(animation.value);
        return Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: v.cover,
              child: const AnimatedAppBackground(child: SizedBox.expand()),
            ),
            Opacity(
              opacity: v.content,
              child: Transform.scale(scale: reduceMotion ? 1.0 : v.scale, child: page),
            ),
          ],
        );
      },
    );
  }
}

/// A dialog that fades and scales in, 0.95 to 1.0 over 200ms.
Future<T?> showAppDialog<T>({required BuildContext context, required WidgetBuilder builder}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(scale: Tween(begin: 0.95, end: 1.0).animate(curved), child: child),
      );
    },
  );
}
