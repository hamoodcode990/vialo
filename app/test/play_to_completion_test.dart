// CLAUDE.md: after any change, confirm all four duel modes and Solo still play
// to completion. These play through the real screens, tapping tubes and tiles
// at random, with the real pour animation running, until a result panel shows.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vialo/screens/duel_tube_game_screen.dart';
import 'package:vialo/screens/fuse_game_screen.dart';
import 'package:vialo/screens/solo_game_screen.dart';
import 'package:vialo/widgets/fuse_cell_view.dart';
import 'package:vialo/widgets/game_result_panel.dart';
import 'package:vialo/widgets/tube_view.dart';

Future<void> _pump(WidgetTester tester, Widget screen) async {
  SharedPreferences.setMockInitialValues({'vialo_profile_v1': '{"onboarded":true}'});
  // Wide: the test font's square glyphs overflow the hint chips at phone width.
  tester.view.physicalSize = const Size(2700, 4000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(child: MaterialApp(home: screen)));
  await tester.pump();
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<void> _playTubes(WidgetTester tester, {int seed = 7}) async {
  final rnd = math.Random(seed);
  final tubes = find.byType(TubeView);
  final before = _units(tester);
  for (var i = 0; i < 6000; i++) {
    if (find.byType(GameResultPanel).evaluate().isNotEmpty) break;
    final views = tester.widgetList<TubeView>(tubes).toList();
    final selected = views.indexWhere((t) => t.selected);
    if (selected >= 0) {
      final legal = [
        for (var d = 0; d < views.length; d++)
          if (views[d].isTarget) d,
      ];
      final d = legal.isEmpty ? selected : legal[rnd.nextInt(legal.length)];
      await tester.tapAt(tester.getCenter(tubes.at(d)));
      await tester.pump(const Duration(milliseconds: 16));
      if (legal.isNotEmpty) await tester.pumpAndSettle();
    } else {
      final s = rnd.nextInt(views.length);
      await tester.tapAt(tester.getCenter(tubes.at(s)));
      await tester.pump(const Duration(milliseconds: 16));
    }
    // Let any bot move finish.
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
  }
  expect(find.byType(GameResultPanel), findsOneWidget, reason: 'the game never ended');
  expect(_units(tester), before, reason: 'liquid was lost or made');
  for (final t in tester.widgetList<TubeView>(tubes)) {
    expect(t.live, isNull);
    expect(t.bodyHidden, isFalse);
  }
}

int _units(WidgetTester tester) =>
    tester.widgetList<TubeView>(find.byType(TubeView)).fold(0, (a, t) => a + t.contents.length);

void main() {
  testWidgets('Solo', (tester) async {
    await _pump(tester, const SoloGameScreen(levelNumber: 1));
    await _playTubes(tester);
  });

  for (final kind in ['pour', 'split', 'recipe']) {
    testWidgets('$kind, pass & play', (tester) async {
      await _pump(tester, DuelTubeGameScreen(kind: kind, mode: 'pass'));
      await _playTubes(tester);
    });
    testWidgets('$kind, vs bot', (tester) async {
      await _pump(tester, DuelTubeGameScreen(kind: kind, mode: 'ai', aiKey: 'easy'));
      await _playTubes(tester);
    });
  }

  testWidgets('split, top tier (11 colours)', (tester) async {
    await _pump(tester, const DuelTubeGameScreen(kind: 'split', mode: 'ai', levelNumber: 150));
    await _playTubes(tester);
  });

  testWidgets('fuse, pass & play', (tester) async {
    await _pump(tester, const FuseGameScreen(mode: 'pass'));
    final rnd = math.Random(3);
    final cells = find.byType(FuseCellView);
    for (var i = 0; i < 20000; i++) {
      if (find.byType(GameResultPanel).evaluate().isNotEmpty) break;
      final n = cells.evaluate().length;
      await tester.tapAt(tester.getCenter(cells.at(rnd.nextInt(n))));
      await tester.pump(const Duration(milliseconds: 400));
      if (i % 40 == 0) await tester.pumpAndSettle();
    }
    expect(find.byType(GameResultPanel), findsOneWidget);
    await tester.pump(const Duration(seconds: 1)); // the last claim's sound timers
  });
}
