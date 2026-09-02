import 'package:flutter/material.dart';

/// The app's one page-transition — a clean horizontal push, like a native
/// navigation stack. Drop-in replacement for `MaterialPageRoute(builder:
/// ...)` everywhere in the app.
///
/// Pure translate, no fade. The previous version paired a fade with the
/// slide on the theory that opacity + translate are the two cheapest things
/// a compositor can animate — true in isolation, but every screen here is
/// full of glow (CLAUDE.md's dark/futuristic theme: blurred BoxShadows on
/// every card, button, and level-road node, now on five different chapter
/// screens' worth of nodes instead of just Solo's). Animating opacity over
/// that whole subtree forces the engine to re-composite every blurred layer
/// on every frame of every navigation, which is a much more plausible
/// explanation for "every single page transition feels bad" than any one
/// screen's own content — a pure translate repositions an already-rasterized
/// layer with no blending at all, regardless of how much glow is under it.
/// A full-width slide also just reads as a clearer, more deliberate "you're
/// on a new screen now" than the old 3.5%-of-height rise did.
class AppRoute<T> extends PageRouteBuilder<T> {
  AppRoute({required WidgetBuilder builder})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionDuration: const Duration(milliseconds: 260),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
            return SlideTransition(
              position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(curved),
              // A translate is only as cheap as the layer it's moving. Without
              // this, Flutter can still decide the incoming page's own
              // subtree needs re-painting on some frames of the slide (its
              // very first appearance isn't yet a settled, cacheable layer)
              // instead of purely repositioning an already-rasterized one —
              // exactly the kind of frame drop that reads as the previous
              // page still showing through for a beat.
              child: RepaintBoundary(child: child),
            );
          },
        );
}
