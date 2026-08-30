import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'tube_painter.dart';

/// One glass tube: selection lift, legal-target ring, dimmed/sealed states,
/// and a shake on an illegal tap. Port of decant.html's `.tube` interaction
/// states (`.sel`, `.tgt`, `.dim`, `.done`, `.shk`).
class TubeView extends StatefulWidget {
  final double width;
  final int capacity;
  final List<int> contents;
  final Color Function(int) colorOf;
  final bool sealed;
  final bool selected;
  final bool isTarget;
  final bool dimmed;
  final String? capLabel;
  final Color? capColor;

  /// Bump this to trigger a shake (e.g. on an illegal tap).
  final int shakeTrigger;
  final VoidCallback? onTap;

  const TubeView({
    super.key,
    required this.width,
    required this.capacity,
    required this.contents,
    required this.colorOf,
    this.sealed = false,
    this.selected = false,
    this.isTarget = false,
    this.dimmed = false,
    this.capLabel,
    this.capColor,
    this.shakeTrigger = 0,
    this.onTap,
  });

  @override
  State<TubeView> createState() => _TubeViewState();
}

class _TubeViewState extends State<TubeView> with TickerProviderStateMixin {
  late final AnimationController _shakeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  // Squash-and-stretch settle (CLAUDE.md Step 5) whenever this tube's
  // contents change — covers both the destination landing a pour and the
  // source tube being disturbed by one, with no extra wiring from callers:
  // TubeView just reacts to its own contents diffing on rebuild.
  late final AnimationController _settleCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  static final Animatable<double> _settleTween = TweenSequence([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.88,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.88,
        end: 1.05,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.05,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
  ]);

  @override
  void didUpdateWidget(TubeView old) {
    super.didUpdateWidget(old);
    if (widget.shakeTrigger != old.shakeTrigger) {
      _shakeCtrl.forward(from: 0);
    }
    if (!_sameContents(old.contents, widget.contents)) {
      _settleCtrl.forward(from: 0);
    }
  }

  bool _sameContents(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _settleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unit = (widget.width * 1.05).clamp(20.0, double.infinity);
    final height = unit * widget.capacity;
    final segments = mergeSegments(widget.contents, widget.colorOf);

    Color borderColor;
    double borderWidth = 3;
    if (widget.sealed) {
      borderColor = AppColors.gold;
    } else if (widget.selected) {
      borderColor = AppColors.p1;
    } else if (widget.isTarget) {
      borderColor = AppColors.p1;
    } else {
      borderColor = AppColors.outline;
    }

    Widget glass = CustomPaint(
      size: Size(widget.width, height),
      painter: TubePainter(
        capacity: widget.capacity,
        segments: segments,
        sealed: widget.sealed,
      ),
    );

    glass = Container(
      width: widget.width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(widget.width * 0.16),
          topRight: Radius.circular(widget.width * 0.16),
          bottomLeft: Radius.circular(widget.width * 0.4),
          bottomRight: Radius.circular(widget.width * 0.4),
        ),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: AppColors.txt.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(widget.width * 0.16),
          topRight: Radius.circular(widget.width * 0.16),
          bottomLeft: Radius.circular(widget.width * 0.4),
          bottomRight: Radius.circular(widget.width * 0.4),
        ),
        child: glass,
      ),
    );

    glass = AnimatedBuilder(
      animation: _settleCtrl,
      child: glass,
      builder: (context, child) => Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.diagonal3Values(
          1,
          _settleTween.evaluate(_settleCtrl),
          1,
        ),
        child: child,
      ),
    );

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedOpacity(
        opacity: widget.dimmed ? 0.34 : 1.0,
        duration: const Duration(milliseconds: 180),
        child: AnimatedBuilder(
          animation: _shakeCtrl,
          builder: (context, child) {
            final t = _shakeCtrl.value;
            final dx = t == 0 || t == 1
                ? 0.0
                : (7 * (1 - t)) * ((t * 4).floor().isEven ? 1 : -1);
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: AnimatedSlide(
            offset: widget.selected ? const Offset(0, -0.14) : Offset.zero,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                glass,
                const SizedBox(height: 5),
                SizedBox(
                  height: 14,
                  child: Text(
                    widget.capLabel ?? (widget.sealed ? '●' : ''),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: widget.capColor ?? AppColors.mute,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
