import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'monetization/monetization_controller.dart';
import 'screens/home_screen.dart';
import 'screens/intro_screen.dart';
import 'screens/onboarding_screen.dart';
import 'state/profile_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/animated_app_background.dart';

void main() {
  runApp(const ProviderScope(child: VialoApp()));
}

class VialoApp extends ConsumerStatefulWidget {
  const VialoApp({super.key});

  @override
  ConsumerState<VialoApp> createState() => _VialoAppState();
}

class _VialoAppState extends ConsumerState<VialoApp> {
  @override
  void initState() {
    super.initState();
    // Fire-and-forget: RevenueCat/AdMob init doesn't block showing the app.
    // Both services degrade to "unavailable" on failure (bad/placeholder
    // key, no device, web/desktop dev environment) rather than throwing —
    // see MonetizationController.initialize().
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(monetizationControllerProvider).initialize();
    });
    // Android defaults to 60Hz even on 90/120Hz-capable screens unless an
    // app opts in — iOS ProMotion is already covered by
    // CADisableMinimumFrameDurationOnPhone in Info.plist. No-op on iOS/
    // devices without a high-refresh-rate mode; swallow any failure the
    // same way the rest of this app degrades rather than throws.
    FlutterDisplayMode.setHighRefreshRate().catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vialo',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // Mounted once here rather than per-screen so every Scaffold (which is
      // transparent, see buildAppTheme) shows the same drifting backdrop.
      builder: (context, child) => AnimatedAppBackground(child: child!),
      home: const _AppGate(),
    );
  }
}

/// Cold-launch gate: always shows the [IntroScreen] reveal (Step 4) for its
/// fixed ~2.4s, then — on a fresh install only, gated on
/// [PlayerProfile.onboarded] — the [OnboardingScreen] (Step 6), then the
/// home screen. On the rare case the profile's single shared_preferences
/// read is still pending once the reveal finishes, keeps the intro's rest
/// frame up with a small spinner rather than a blank frame, per CLAUDE.md
/// Step 4's "never a blank frame" rule. No screen past this gate ever has
/// to handle "profile not loaded yet" — see ProfileController.build().
class _AppGate extends ConsumerStatefulWidget {
  const _AppGate();

  @override
  ConsumerState<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<_AppGate> {
  bool _introDone = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileControllerProvider);
    final profileReady = profileAsync is! AsyncLoading;

    if (!_introDone) {
      return IntroScreen(
        onDone: () => setState(() => _introDone = true),
        showLoadingSpinner: !profileReady,
      );
    }
    return profileAsync.when(
      data: (profile) => profile.onboarded ? const HomeScreen() : const OnboardingScreen(),
      loading: () => const IntroScreen(onDone: _noop, showLoadingSpinner: true, animate: false),
      error: (err, st) => const HomeScreen(), // ProfileRepository.load() already falls back to defaults
    );
  }
}

void _noop() {}
