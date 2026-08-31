// App-level smoke test: the shell boots, waits out the profile-load splash,
// and lands on the home screen with the header bar and all four duel-mode
// tiles visible.
import 'package:vialo/main.dart';
import 'package:vialo/screens/duel_tube_game_screen.dart';
import 'package:vialo/theme/cosmetics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('VialoApp boots to the home screen', (WidgetTester tester) async {
    // onboarded:true so these tests land straight on the home screen —
    // onboarding-on-first-launch (Step 6) has its own dedicated test below.
    SharedPreferences.setMockInitialValues({'vialo_profile_v1': '{"onboarded":true}'});
    await tester.pumpWidget(const ProviderScope(child: VialoApp()));
    // Bounded pumps rather than pumpAndSettle: one to flush the profile-load
    // future, one to ride out the ~2.4s intro reveal (Step 4).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2600));

    expect(find.text('VIALO'), findsOneWidget);
    expect(find.text('Split'), findsOneWidget);
    expect(find.text('Pour'), findsOneWidget);
    expect(find.text('Fuse'), findsOneWidget);
    expect(find.text('Recipe'), findsOneWidget);
    expect(find.text('Solo sort'), findsOneWidget);
    // Fresh-install defaults from PlayerProfile.
    expect(find.text('5'), findsOneWidget); // lives
    expect(find.text('100'), findsOneWidget); // coins
  });

  testWidgets('tapping a mode tile opens its hub', (WidgetTester tester) async {
    // onboarded:true so these tests land straight on the home screen —
    // onboarding-on-first-launch (Step 6) has its own dedicated test below.
    SharedPreferences.setMockInitialValues({'vialo_profile_v1': '{"onboarded":true}'});
    await tester.pumpWidget(const ProviderScope(child: VialoApp()));
    // Bounded pumps rather than pumpAndSettle: one to flush the profile-load
    // future, one to ride out the ~2.4s intro reveal (Step 4).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2600));

    await tester.tap(find.text('Pour').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Levels'), findsOneWidget);
    expect(find.text('Quick match'), findsOneWidget);
    expect(find.text('Pass & play'), findsOneWidget);
  });

  testWidgets('fresh install shows onboarding once, then Skip reaches the home screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({}); // no saved profile => onboarded defaults to false
    await tester.pumpWidget(const ProviderScope(child: VialoApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2600));

    expect(find.text("You're ready"), findsNothing); // last slide, not shown yet
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('VIALO'), findsNothing); // home screen not reached yet

    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('VIALO'), findsOneWidget);
    expect(find.text('Split'), findsOneWidget);
  });

  testWidgets("Solo's level map shows chapter framing and blocks a locked level", (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'vialo_profile_v1': '{"onboarded":true}'});
    await tester.pumpWidget(const ProviderScope(child: VialoApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2600));

    // "Solo sort" sits below the fold on the test surface — scroll it into view.
    await tester.drag(find.text('VIALO'), const Offset(0, -400));
    await tester.pump();
    await tester.tap(find.text('Solo sort'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Chapter 1's title card (CLAUDE.md Step 10).
    expect(find.text('CHAPTER 1'), findsOneWidget);
    expect(find.text('The First Pours'), findsOneWidget);
    // Level 1 is unlocked on a fresh profile.
    expect(find.text('1'), findsOneWidget);

    // Level 2 is locked (shows a lock icon, not its number) and sits
    // further down the winding path — scroll it into view.
    await tester.drag(find.text('CHAPTER 1'), const Offset(0, -200));
    await tester.pump();
    expect(find.byIcon(Icons.lock_rounded), findsWidgets);

    await tester.tap(find.byIcon(Icons.lock_rounded).first);
    await tester.pump();

    expect(find.text('Locked — clear the level before it first'), findsWidgets);
  });

  testWidgets('avatar picker shows 3 unlocked + 5 locked avatars, and a locked tap explains why', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'vialo_profile_v1': '{"onboarded":true}'});
    await tester.pumpWidget(const ProviderScope(child: VialoApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2600));

    await tester.tap(find.byType(AvatarGlyph).first); // header avatar -> Profile
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('AVATAR'), findsOneWidget);
    // 8 avatars total in the picker grid — Profile itself has no header
    // chip, and the Home screen underneath is fully covered so its own
    // AvatarGlyph isn't part of what a finder sees here.
    expect(find.byType(AvatarGlyph), findsNWidgets(8));
    // 5 of the 8 are level-gated on a fresh profile (only level 1 cleared-frontier).
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(5));

    await tester.tap(find.byIcon(Icons.lock_rounded).first);
    await tester.pump();
    expect(find.textContaining('Unlocks at Solo level'), findsOneWidget);
  });

  testWidgets('first pass & play in a mode shows its tutorial once, then plays', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'vialo_profile_v1': '{"onboarded":true}'});
    await tester.pumpWidget(const ProviderScope(child: VialoApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2600));

    await tester.tap(find.text('Pour').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Pass & play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The tutorial gate fired instead of jumping straight to the game.
    expect(find.text('Pour — how to play'), findsOneWidget);
    expect(find.byType(DuelTubeGameScreen), findsNothing);

    // Walk through every step to the final "Let's play" CTA.
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.tap(find.text("Let's play"));
    await tester.pump();
    // pumpAndSettle rather than a fixed pump: the game screen staggers each
    // tube's entrance reveal in on its own delayed Future (tube_view.dart),
    // and by now the tutorial's own looping demo timer is gone (its screen
    // was just popped), so nothing here runs forever the way it would.
    await tester.pumpAndSettle();

    expect(find.byType(DuelTubeGameScreen), findsOneWidget);
  });

  testWidgets('a mode already marked seen skips straight past its tutorial', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'vialo_profile_v1': '{"onboarded":true,"seenModeTutorials":["pour"]}',
    });
    await tester.pumpWidget(const ProviderScope(child: VialoApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2600));

    await tester.tap(find.text('Pour').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Pass & play'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Pour — how to play'), findsNothing);
    expect(find.byType(DuelTubeGameScreen), findsOneWidget);
  });
}
