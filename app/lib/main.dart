import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'monetization/monetization_controller.dart';
import 'screens/home_screen.dart';
import 'state/profile_provider.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vialo',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _AppGate(),
    );
  }
}

/// Waits for the first profile load (a single shared_preferences read)
/// before showing the app, so no screen ever has to handle "profile not
/// loaded yet" — see ProfileController.build().
class _AppGate extends ConsumerWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);
    return profileAsync.when(
      data: (_) => const HomeScreen(),
      loading: () => const _Splash(),
      error: (err, st) => const HomeScreen(), // ProfileRepository.load() already falls back to defaults
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.ink,
      body: Center(
        child: Text(
          'VIALO',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1, color: AppColors.txt),
        ),
      ),
    );
  }
}
