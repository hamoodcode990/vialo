// App-level smoke test: the shell boots, waits out the profile-load splash,
// and lands on the home screen with the header bar and all four duel-mode
// tiles visible.
import 'package:vialo/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('VialoApp boots to the home screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
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
    SharedPreferences.setMockInitialValues({});
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
}
