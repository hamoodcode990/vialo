import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The app's one transient message: a dark glass pill near the top of the
/// screen, below the app bar, so it can't sit over the primary buttons at the
/// bottom of a screen. It never takes touches, lasts about 1.8s, and is
/// cleared by any navigation ([AppToastObserver]).
///
/// Needs no BuildContext, so it is safe to call after an `await`.
class AppToast {
  AppToast._();

  static const Duration duration = Duration(milliseconds: 1800);

  static final ValueNotifier<AppToastData?> _current = ValueNotifier(null);
  static int _serial = 0;

  /// Shows [message], replacing any toast already up. An empty message shows
  /// nothing (e.g. a cancelled purchase).
  static void show(String message, {IconData? icon}) {
    if (message.isEmpty) return;
    _current.value = AppToastData(++_serial, message, icon);
  }

  static void clear() => _current.value = null;
}

class AppToastData {
  final int serial;
  final String message;
  final IconData? icon;
  const AppToastData(this.serial, this.message, this.icon);
}

/// Clears the toast on every route change, so a message never follows the
/// player onto the next screen.
class AppToastObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => AppToast.clear();
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => AppToast.clear();
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => AppToast.clear();
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => AppToast.clear();
  @override
  void didStartUserGesture(Route<dynamic> route, Route<dynamic>? previousRoute) => AppToast.clear();
}

/// Mounted once above the Navigator (MaterialApp `builder:`). Costs nothing
/// while no toast is up: no ticker runs and nothing repaints.
class AppToastHost extends StatefulWidget {
  final Widget child;
  const AppToastHost({super.key, required this.child});

  @override
  State<AppToastHost> createState() => _AppToastHostState();
}

class _AppToastHostState extends State<AppToastHost> with SingleTickerProviderStateMixin {
  static const _fade = 0.09; // of the total, about 160ms each way

  late final AnimationController _ctrl = AnimationController(vsync: this, duration: AppToast.duration);
  AppToastData? _shown;

  @override
  void initState() {
    super.initState();
    AppToast._current.addListener(_onChange);
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) AppToast.clear();
    });
  }

  void _onChange() {
    final next = AppToast._current.value;
    if (next == null) _ctrl.stop();
    if (next != null) _ctrl.forward(from: 0);
    if (mounted) setState(() => _shown = next);
  }

  @override
  void dispose() {
    AppToast._current.removeListener(_onChange);
    AppToast._current.value = null;
    _ctrl.dispose();
    super.dispose();
  }

  double get _opacity {
    final t = _ctrl.value;
    if (t < _fade) return t / _fade;
    if (t > 1 - _fade) return (1 - t) / _fade;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final toast = _shown;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (toast != null)
          Positioned(
            left: 24,
            right: 24,
            top: MediaQuery.paddingOf(context).top + kToolbarHeight + 6,
            child: IgnorePointer(
              child: Center(
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, child) => Opacity(opacity: _opacity.clamp(0.0, 1.0), child: child),
                  child: _ToastPill(key: ValueKey(toast.serial), toast: toast),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ToastPill extends StatelessWidget {
  final AppToastData toast;
  const _ToastPill({super.key, required this.toast});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.ink2.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (toast.icon != null) ...[
                Icon(toast.icon, size: 15, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  toast.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
