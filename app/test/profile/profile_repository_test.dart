// Tests the shared_preferences integration itself. This is the one place
// in Phase 3 that needs flutter_test (for its shared_preferences mock, not
// for any widget) — everything else runs under plain `dart test`.
import 'package:vialo/profile/profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('load() on first launch returns fresh defaults and persists nothing yet', () async {
    final repo = ProfileRepository();
    final profile = await repo.load();
    expect(profile.lives, PlayerProfile.lifeMax);
    expect(profile.coins, 100);
    expect(profile.name, 'Player');
  });

  test('save() then load() round-trips every field', () async {
    final repo = ProfileRepository();
    final profile = await repo.load();
    profile.name = 'Tester';
    profile.coins = 250;
    final earned = profile.recordLevelWin('pour', 1, 3); // adds its own coins
    profile.recordAiResult('fuse', true, 4);
    await repo.save(profile);

    final reloaded = await repo.load();
    expect(reloaded.name, 'Tester');
    expect(reloaded.coins, 250 + earned);
    expect(reloaded.levelProgress['pour'], 2);
    expect(reloaded.starsFor('pour', 1), 3);
    expect(reloaded.stats.fw, 1);
  });

  test('lives regenerate across a reload as if the app had been closed', () async {
    final repo = ProfileRepository();
    final profile = await repo.load();
    profile.lives = 1;
    profile.livesUpdatedAt =
        DateTime.now().millisecondsSinceEpoch - 4 * 60 * 60 * 1000; // 4h ago
    await repo.save(profile);

    final reloaded = await repo.load(); // load() itself calls regenLives(now)
    expect(reloaded.lives, 3, reason: '4h / 2h-per-life = +2 lives while "closed"');
  });

  test('corrupt saved data falls back to fresh defaults instead of crashing', () async {
    SharedPreferences.setMockInitialValues({
      ProfileRepository.storageKey: 'not valid json {{{',
    });
    final repo = ProfileRepository();
    final profile = await repo.load();
    expect(profile.lives, PlayerProfile.lifeMax);
    expect(profile.coins, 100);
  });
}
