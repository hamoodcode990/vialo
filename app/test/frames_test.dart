// Vialo 1.0.1 Phase 6: static screens render nothing; 120Hz key stays on.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vialo/main.dart';
import 'package:vialo/screens/duel_tube_game_screen.dart';
import 'package:vialo/screens/solo_game_screen.dart';
import 'package:vialo/screens/store_screen.dart';

void main() {
  test('ProMotion stays enabled', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(
      RegExp(r'<key>CADisableMinimumFrameDurationOnPhone</key>\s*<true/>').hasMatch(plist),
      isTrue,
    );
  });

  Future<void> settle(WidgetTester tester, Widget child) async {
    SharedPreferences.setMockInitialValues({'vialo_profile_v1': '{"onboarded":true}'});
    await tester.pumpWidget(ProviderScope(child: MaterialApp(home: child)));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
  }

  for (final (name, screen) in [
    ('Solo', const SoloGameScreen(levelNumber: 1) as Widget),
    ('a duel', const DuelTubeGameScreen(kind: 'split', mode: 'pass')),
    ('the Store', const StoreScreen()),
  ]) {
    testWidgets('$name schedules no frames when nothing moves', (tester) async {
      await settle(tester, screen);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pump(const Duration(seconds: 3));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  }

  testWidgets('Home schedules no frames when nothing moves', (tester) async {
    SharedPreferences.setMockInitialValues({'vialo_profile_v1': '{"onboarded":true}'});
    await tester.pumpWidget(const ProviderScope(child: VialoApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();
    expect(find.text('VIALO'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
