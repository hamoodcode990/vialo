// Vialo 1.0.1 Phase 3: the tilt-and-pour.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vialo/screens/duel_tube_game_screen.dart';
import 'package:vialo/screens/solo_game_screen.dart';
import 'package:vialo/widgets/pour_animation.dart';
import 'package:vialo/widgets/tube_geometry.dart';
import 'package:vialo/widgets/tube_painter.dart';
import 'package:vialo/widgets/tube_view.dart';

const _size = Size(40, 160);

List<int> _flatten(Iterable<List<int>> tubes) => [for (final t in tubes) ...t]..sort();

void main() {
  group('timeline', () {
    test('matches the plan: 200 move, 150 tilt, 110 per unit, 200 return, 250 wobble', () {
      const t = PourTimeline(3);
      expect(t.streamStart, 350);
      expect(t.streamEnd, 350 + 330);
      expect(t.total, 350 + 330 + 250);
      expect(t.travel(0), 0);
      expect(t.travel(200), 1);
      expect(t.travel(t.streamEnd + 200), 0);
      expect(t.angle(0), 0);
      expect(t.angle(350) * 180 / math.pi, closeTo(60, 0.01));
      expect(t.angle(t.streamEnd - 0.01) * 180 / math.pi, closeTo(80, 0.1));
      expect(t.angle(t.streamEnd + 200), 0);
    });

    test('levels move continuously and in sync, never jumping', () {
      for (final n in [1, 2, 3, 4]) {
        final t = PourTimeline(n);
        var last = 0.0;
        for (var ms = 0.0; ms <= t.total; ms += 8) {
          final moved = t.moved(ms);
          expect(moved - last, lessThanOrEqualTo(8 / 110 + 1e-9), reason: 'jump at $ms');
          expect(moved, greaterThanOrEqualTo(last));
          last = moved;
        }
        expect(last, n);
      }
    });

    test('Reduce Motion skips the move and tilt and takes 200ms', () {
      const t = PourTimeline(3, reduceMotion: true);
      expect(t.streamStart, 0);
      expect(t.total, 200);
    });
  });

  group('tilted liquid', () {
    final upright = tubeOutline(_size);

    test('upright, solved surfaces match the plain band heights', () {
      final surfaces = solveBandSurfaces(
        uprightPoly: upright,
        rotatedPoly: upright,
        size: _size,
        capacity: 4,
        bandUnits: [1, 2],
      );
      expect(surfaces[0], closeTo(120, 0.05));
      expect(surfaces[1], closeTo(40, 0.05));
    });

    for (final degrees in [30, 60, 70, 80]) {
      test('at $degrees° the volume is conserved and bands stay stacked', () {
        final a = degrees * math.pi / 180;
        final rotated = [for (final p in upright) rotateAbout(p, Offset(_size.width, 0), a, const Offset(200, 50))];
        expect(polygonArea(rotated), closeTo(polygonArea(upright), 0.01));
        final surfaces = solveBandSurfaces(
          uprightPoly: upright,
          rotatedPoly: rotated,
          size: _size,
          capacity: 4,
          bandUnits: [1, 1, 1],
        );
        expect(surfaces[1], lessThan(surfaces[0]));
        expect(surfaces[2], lessThan(surfaces[1]));
        for (var units = 1; units <= 3; units++) {
          expect(
            areaBelow(rotated, surfaces[units - 1]),
            closeTo(volumeOfUnits(upright, _size, 4, units.toDouble()), 1.0),
          );
        }
      });
    }
  });

  test('draining and filling: the drawn bands land exactly on the engine result', () {
    const red = Color(0xFFFF0000), blue = Color(0xFF0000FF);
    Color colorOf(int i) => i == 0 ? red : blue;
    final before = mergeSegments([1, 0, 0], colorOf);
    final after = adjustTop(before, red, -2);
    expect(after.single.color, blue);
    expect(after.single.count, 1);

    final target = mergeSegments([0], colorOf);
    final filled = adjustTop(target, red, 2);
    expect(filled.single.count, 3);
    expect(adjustTop(target, blue, 1).length, 2);
  });

  group('source side', () {
    const from = Rect.fromLTWH(10, 100, 40, 180);
    test('keeps its own side when it fits', () {
      expect(pourSide(from, const Rect.fromLTWH(300, 100, 40, 180), 170, 390), -1);
    });
    test('flips to stay on screen', () {
      const farRight = Rect.fromLTWH(300, 100, 40, 180);
      expect(pourSide(farRight, const Rect.fromLTWH(10, 100, 40, 180), 170, 390), 1);
      expect(pourSide(const Rect.fromLTWH(60, 100, 40, 180), const Rect.fromLTWH(20, 100, 40, 180), 170, 390), 1);
    });
  });

  group('on the board', () {
    Future<void> pump(WidgetTester tester, Widget screen, {bool reduceMotion = false}) async {
      SharedPreferences.setMockInitialValues({'vialo_profile_v1': '{"onboarded":true}'});
      // Wide: the test font's square glyphs overflow the hint chips at phone width.
      tester.view.physicalSize = const Size(2700, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (c) => MediaQuery(
              data: MediaQuery.of(c).copyWith(disableAnimations: reduceMotion),
              child: screen,
            ),
          ),
        ),
      ));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }

    List<List<int>> tubes(WidgetTester tester) =>
        tester.widgetList<TubeView>(find.byType(TubeView)).map((t) => List<int>.of(t.contents)).toList();

    /// Finds any legal Solo pour on screen: top colour matches, or target empty.
    (int, int) legalMove(List<List<int>> t) {
      for (var s = 0; s < t.length; s++) {
        if (t[s].isEmpty) continue;
        for (var d = 0; d < t.length; d++) {
          if (d == s || t[d].length >= 4) continue;
          if (t[d].isEmpty || t[d].last == t[s].last) return (s, d);
        }
      }
      throw StateError('no legal move');
    }

    Future<void> tapTube(WidgetTester tester, int i) async {
      await tester.tapAt(tester.getCenter(find.byType(TubeView).at(i)));
      await tester.pump(const Duration(milliseconds: 16));
    }

    testWidgets('the board only changes when the stream ends, and ends equal to the engine', (tester) async {
      await pump(tester, const SoloGameScreen(levelNumber: 1));
      final before = tubes(tester);
      final (s, d) = legalMove(before);
      await tapTube(tester, s);
      await tapTube(tester, d);

      await tester.pump(const Duration(milliseconds: 300)); // mid tilt
      expect(tubes(tester), before, reason: 'no engine change before the stream ends');
      expect(tester.widgetList<TubeView>(find.byType(TubeView)).elementAt(s).bodyHidden, isTrue);
      expect(tester.widgetList<TubeView>(find.byType(TubeView)).elementAt(d).live, isNotNull);

      await tester.pumpAndSettle();
      final after = tubes(tester);
      expect(after, isNot(before));
      expect(_flatten(after), _flatten(before), reason: 'no liquid lost or made');
      for (final t in tester.widgetList<TubeView>(find.byType(TubeView))) {
        expect(t.live, isNull, reason: 'nothing is still animating over the engine state');
        expect(t.bodyHidden, isFalse);
      }
      expect(find.text('1/${RegExp(r'/(\d+)').firstMatch(_movesText(tester))!.group(1)}'), findsOneWidget);
    });

    testWidgets('rapid taps never double-pour', (tester) async {
      await pump(tester, const SoloGameScreen(levelNumber: 1));
      final (s, d) = legalMove(tubes(tester));
      await tapTube(tester, s);
      await tapTube(tester, d);
      for (var i = 0; i < 12; i++) {
        await tapTube(tester, i.isEven ? d : s);
        await tapTube(tester, i.isEven ? s : d);
      }
      // All of that landed while the stream was still running.
      await tester.pumpAndSettle();
      expect(_movesText(tester).split('/').first, '1');
    });

    testWidgets('a next selection is allowed during the return', (tester) async {
      await pump(tester, const SoloGameScreen(levelNumber: 1));
      final before = tubes(tester);
      final (s, d) = legalMove(before);
      final moved = before[s].reversed.takeWhile((c) => c == before[s].last).length;
      final fits = math.min(moved, 4 - before[d].length);
      await tapTube(tester, s);
      await tapTube(tester, d);
      final streamEnd = PourTimeline(fits).streamEnd;
      await tester.pump(Duration(milliseconds: streamEnd.round() + 20));
      final other = [for (var i = 0; i < before.length; i++) i].firstWhere(
        (i) => i != s && i != d && tubes(tester)[i].isNotEmpty,
      );
      await tapTube(tester, other);
      expect(tester.widgetList<TubeView>(find.byType(TubeView)).elementAt(other).selected, isTrue);
      await tester.pumpAndSettle();
    });

    testWidgets('duels: the turn only passes when the stream ends', (tester) async {
      await pump(tester, const DuelTubeGameScreen(kind: 'split', mode: 'pass'));
      expect(find.textContaining('Player 1'), findsWidgets);
      final (s, d) = legalMove(tubes(tester));
      await tapTube(tester, s);
      await tapTube(tester, d);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Player 1 — your move'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Player 2 — your move'), findsOneWidget);
    });

    testWidgets('duels: the bot waits for the stream too, and plays its own pour to the end', (tester) async {
      await pump(tester, const DuelTubeGameScreen(kind: 'pour', mode: 'ai', aiKey: 'easy'));
      final before = _flatten(tubes(tester));
      final (s, d) = legalMove(tubes(tester));
      await tapTube(tester, s);
      await tapTube(tester, d);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('is thinking'), findsNothing);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1)); // the bot's thinking delay
      await tester.pumpAndSettle();
      expect(_flatten(tubes(tester)), before);
    });

    testWidgets('Reduce Motion cross-fades in place, with no tube leaving its slot', (tester) async {
      await pump(tester, const SoloGameScreen(levelNumber: 1), reduceMotion: true);
      final before = tubes(tester);
      final (s, d) = legalMove(before);
      await tapTube(tester, s);
      await tapTube(tester, d);
      await tester.pump(const Duration(milliseconds: 100));
      final views = tester.widgetList<TubeView>(find.byType(TubeView)).toList();
      expect(views[s].bodyHidden, isFalse);
      expect(views[s].live?.crossfade, isNotNull);
      expect(views[d].live?.crossfade, isNotNull);
      expect(tubes(tester), before);
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pumpAndSettle();
      expect(tubes(tester), isNot(before));
    });
  });
}

String _movesText(WidgetTester tester) {
  final texts = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').toList();
  return texts[texts.indexOf('MOVES') + 1];
}
