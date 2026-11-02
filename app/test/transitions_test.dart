// Vialo 1.0.1 Phase 2: screen transitions.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vialo/main.dart';
import 'package:vialo/screens/duel_tube_game_screen.dart';
import 'package:vialo/widgets/animated_app_background.dart';
import 'package:vialo/widgets/app_route.dart';
import 'package:vialo/widgets/entrance_reveal.dart';

const _total = kFadeOutMs + kFadeInMs;

void main() {
  group('fade-through timing', () {
    test('entering: the old screen is fully covered before the new one starts', () {
      final mid = fadeThroughAt(50 / _total);
      expect(mid.cover, closeTo(0.5, 0.001));
      expect(mid.content, 0);

      final covered = fadeThroughAt(kFadeOutMs / _total);
      expect(covered.cover, 1);
      expect(covered.content, 0);
      expect(covered.scale, closeTo(0.97, 0.001));

      final done = fadeThroughAt(1);
      expect(done.cover, 1);
      expect(done.content, 1);
      expect(done.scale, 1);
    });

    test('leaving: the game goes first, then the cover lifts', () {
      final goneAt = 1 - kFadeOutMs / _total;
      expect(fadeThroughReverseAt(1).content, 1);
      expect(fadeThroughReverseAt(goneAt).content, closeTo(0, 0.001));
      expect(fadeThroughReverseAt(goneAt).cover, closeTo(1, 0.001));
      expect(fadeThroughReverseAt(0).cover, 0);
    });

    test('opacity never jumps by more than a frame\'s worth', () {
      var last = fadeThroughAt(0);
      const frames = 40;
      for (var i = 1; i <= frames; i++) {
        final v = fadeThroughAt(i / frames);
        expect((v.cover - last.cover).abs(), lessThan(0.5), reason: 'frame $i cover');
        expect((v.content - last.content).abs(), lessThan(0.5), reason: 'frame $i content');
        last = v;
      }
    });
  });

  Future<void> boot(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'vialo_profile_v1': '{"onboarded":true,"seenModeTutorials":["pour"]}',
    });
    await tester.pumpWidget(const ProviderScope(child: VialoApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2600));
  }

  testWidgets('menus slide natively, with a backdrop of their own', (tester) async {
    await boot(tester);
    await tester.tap(find.text('Pour').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    final route = ModalRoute.of(tester.element(find.text('Quick match')));
    expect(route, isA<CupertinoPageRoute>());
    expect(route!.opaque, isTrue);
    expect(
      find.ancestor(of: find.text('Quick match'), matching: find.byType(AnimatedAppBackground)),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('gameplay fades through, and tubes deal in after the fade', (tester) async {
    await boot(tester);
    await tester.tap(find.text('Pour').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Pass & play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150)); // mid fade

    final game = find.byType(DuelTubeGameScreen);
    expect(ModalRoute.of(tester.element(game)), isA<GameRoute>());
    expect(ModalRoute.of(tester.element(game))!.opaque, isTrue);

    final reveal = find.descendant(of: game, matching: find.byType(EntranceReveal)).first;
    double revealOpacity() => tester
        .widget<Opacity>(find.descendant(of: reveal, matching: find.byType(Opacity)).first)
        .opacity;
    expect(revealOpacity(), 0, reason: 'still mid-fade: the tube has not started dealing');

    await tester.pump(const Duration(milliseconds: 200)); // fade over
    await tester.pumpAndSettle();
    expect(revealOpacity(), 1);
  });

  testWidgets('dialogs fade and scale in from 0.95', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) {
      ctx = c;
      return const SizedBox.expand();
    })));
    showAppDialog<void>(context: ctx, builder: (_) => const AlertDialog(title: Text('hi')));
    await tester.pump();
    final scale = tester.widget<ScaleTransition>(
      find.ancestor(of: find.text('hi'), matching: find.byType(ScaleTransition)).first,
    );
    expect(scale.scale.value, closeTo(0.95, 0.001));
    await tester.pump(const Duration(milliseconds: 200));
    expect(scale.scale.value, 1);
  });
}
