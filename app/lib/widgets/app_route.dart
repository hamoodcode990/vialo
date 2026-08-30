import 'package:flutter/material.dart';

/// The app's one page-transition — a fade + gentle rise instead of
/// Material's default platform slide. Drop-in replacement for
/// `MaterialPageRoute(builder: ...)` everywhere in the app.
///
/// Deliberately built from the two cheapest animatable properties a
/// compositor has (opacity and a translate) — no shadows, no clipping, no
/// relayout of either page's subtree — so this is lighter on every frame
/// than the platform default, not just prettier. Short duration (220ms) so
/// it reads as snappy rather than slow.
class AppRoute<T> extends PageRouteBuilder<T> {
  AppRoute({required WidgetBuilder builder})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionDuration: const Duration(milliseconds: 220),
          reverseTransitionDuration: const Duration(milliseconds: 180),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeIn);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero).animate(curved),
                child: child,
              ),
            );
          },
        );
}
