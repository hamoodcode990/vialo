// App-level smoke test: the shell boots, waits out the profile-load splash,
// and lands on the home screen with the header bar and all four duel-mode
// tiles visible.
import 'package:vialo/main.dart';
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
    // pumpAndSettle can't be used once the app has a perpetually-repeating
    // animation (the animated gradient backdrop) — it would wait forever
    // for zero pending frames. Bounded pumps instead: one to flush the
    // profile-load future, one to ride out the ~1.8s intro reveal (Step 4)
    // plus any transition animation.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2000));

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
    // pumpAndSettle can't be used once the app has a perpetually-repeating
    // animation (the animated gradient backdrop) — it would wait forever
    // for zero pending frames. Bounded pumps instead: one to flush the
    // profile-load future, one to ride out the ~1.8s intro reveal (Step 4)
    // plus any transition animation.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2000));

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
    await tester.pump(const Duration(milliseconds: 2000));

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
    await tester.pump(const Duration(milliseconds: 2000));

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
}
