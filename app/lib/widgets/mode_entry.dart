import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/mode_tutorial_screen.dart';
import '../state/profile_provider.dart';
import 'app_route.dart';

/// The one choke point every door into an actual game goes through
/// (level tap, quick-match difficulty tap, pass & play) — whichever door a
/// player first walks through for a given mode, this shows that mode's
/// how-to-play tutorial exactly once before their first game, then remembers
/// it via `PlayerProfile.seenModeTutorials`. Already-seen modes skip straight
/// to [gameBuilder]. Reopening the tutorial later (the mode hub's help icon)
/// pushes `ModeTutorialScreen` directly instead — this gate is only for the
/// auto-show-once behaviour.
Future<void> openMode(
  BuildContext context,
  WidgetRef ref, {
  required String modeId,
  required WidgetBuilder gameBuilder,
}) async {
  final profile = ref.read(profileProvider);
  if (!profile.seenModeTutorials.contains(modeId)) {
    final playedNext = await Navigator.of(context).push<bool>(
      AppRoute(builder: (_) => ModeTutorialScreen(modeId: modeId, firstTime: true)),
    );
    ref.read(profileControllerProvider.notifier).markTutorialSeen(modeId);
    if (playedNext != true) return;
  }
  if (!context.mounted) return;
  Navigator.of(context).push(AppRoute(builder: gameBuilder));
}
