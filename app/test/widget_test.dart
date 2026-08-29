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
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pour').first);
    await tester.pumpAndSettle();

    expect(find.text('Levels'), findsOneWidget);
    expect(find.text('Quick match'), findsOneWidget);
    expect(find.text('Pass & play'), findsOneWidget);
  });
}
