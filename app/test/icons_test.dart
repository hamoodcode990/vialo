// Vialo 1.0.1 Phase 5: one custom icon set, no emoji as UI.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vialo/widgets/app_icon.dart';

void main() {
  test('no emoji anywhere in lib/', () {
    final emoji = RegExp(r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{23E9}-\u{23FA}\u{FE0F}]', unicode: true);
    final hits = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (emoji.hasMatch(lines[i])) hits.add('${f.path}:${i + 1}: ${lines[i].trim()}');
      }
    }
    expect(hits, isEmpty);
  });

  test('every icon has its asset', () {
    for (final icon in AppIcons.values) {
      expect(File(icon.asset).existsSync(), isTrue, reason: icon.asset);
    }
  });
}
