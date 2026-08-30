// Pure-logic tests for PlayerProfile — no Flutter, no shared_preferences.
// Deliberately import only the pure files (not profile.dart, whose barrel
// also re-exports profile_repository.dart, which pulls in the
// shared_preferences plugin and transitively package:flutter — that would
// stop this suite from running under plain `dart test`). See
// ProfileRepository's own tests (flutter test) for the persistence I/O.
import 'package:vialo/profile/player_profile.dart';
import 'package:test/test.dart';

const _hour = 60 * 60 * 1000;

void main() {
  group('lives regeneration', () {
    test('one life regenerates every 2 hours, accruing while closed', () {
      final p = PlayerProfile(lives: 3, livesUpdatedAt: 0);
      p.regenLives(2 * _hour); // exactly one tick
      expect(p.lives, 4);
      expect(p.livesUpdatedAt, 2 * _hour);
    });

    test('4 hours elapsed grants +2 lives, capped at 5', () {
      final p = PlayerProfile(lives: 1, livesUpdatedAt: 0);
      p.regenLives(4 * _hour);
      expect(p.lives, 3);
    });

    test('regeneration caps at lifeMax even with a huge elapsed time', () {
      final p = PlayerProfile(lives: 1, livesUpdatedAt: 0);
      p.regenLives(1000 * _hour);
      expect(p.lives, PlayerProfile.lifeMax);
    });

    test('does not overshoot when already at or above lifeMax', () {
      final p = PlayerProfile(lives: PlayerProfile.lifeMax, livesUpdatedAt: 0);
      p.regenLives(10 * _hour);
      expect(p.lives, PlayerProfile.lifeMax);
      // Timestamp should track "now" while full, not accrue a backlog.
      expect(p.livesUpdatedAt, 10 * _hour);
    });

    test('partial progress toward the next life is preserved, not reset', () {
      final p = PlayerProfile(lives: 2, livesUpdatedAt: 0);
      p.regenLives(90 * 60 * 1000); // 1.5h: not a full tick yet
      expect(p.lives, 2);
      expect(p.livesUpdatedAt, 0); // unconsumed, still counting from 0
      p.regenLives(2 * _hour); // now past the 2h mark
      expect(p.lives, 3);
    });
  });

  group('nextLifeMs', () {
    test('0 when already full', () {
      final p = PlayerProfile(lives: PlayerProfile.lifeMax, livesUpdatedAt: 0);
      expect(p.nextLifeMs(0), 0);
    });

    test('0 while unlimited lives are active', () {
      final p = PlayerProfile(lives: 1, livesUpdatedAt: 0, tempLivesUntil: 10 * _hour);
      expect(p.nextLifeMs(_hour), 0);
    });

    test('counts down correctly otherwise', () {
      final p = PlayerProfile(lives: 1, livesUpdatedAt: 0);
      expect(p.nextLifeMs(30 * 60 * 1000), 90 * 60 * 1000);
    });
  });

  group('life spending — never on start or win', () {
    test('loseLife decrements by exactly one, floor 0', () {
      final p = PlayerProfile(lives: 1, livesUpdatedAt: 0);
      p.loseLife(0);
      expect(p.lives, 0);
      p.loseLife(0); // already 0, stays 0
      expect(p.lives, 0);
    });

    test('loseLife is a no-op while unlimited lives are active', () {
      final p = PlayerProfile(lives: 2, livesUpdatedAt: 0, tempLivesUntil: 5 * _hour);
      p.loseLife(_hour);
      expect(p.lives, 2);
    });

    test('nothing in PlayerProfile deducts a life except loseLife', () {
      // recordLevelWin (a win) and addLives/addCoins must never touch lives.
      final p = PlayerProfile(lives: 3, livesUpdatedAt: 0, coins: 0);
      p.recordLevelWin('pour', 1, 3);
      expect(p.lives, 3);
      p.addCoins(100);
      expect(p.lives, 3);
      p.addLives(1);
      expect(p.lives, 4);
    });
  });

  group('coins', () {
    test('addCoins increases balance; spendCoins requires affordability', () {
      final p = PlayerProfile(coins: 50, livesUpdatedAt: 0);
      p.addCoins(25);
      expect(p.coins, 75);
      expect(p.spendCoins(100, 0), isFalse);
      expect(p.coins, 75);
      expect(p.spendCoins(75, 0), isTrue);
      expect(p.coins, 0);
    });
  });

  group('level progress and stars', () {
    test('recordLevelWin unlocks the next level only at the frontier', () {
      final p = PlayerProfile(livesUpdatedAt: 0);
      expect(p.levelProgress['pour'], 1);
      p.recordLevelWin('pour', 1, 2);
      expect(p.levelProgress['pour'], 2);
      expect(p.starsFor('pour', 1), 2);

      // Replaying an already-cleared, non-frontier level does not skip
      // levels or reduce progress.
      p.recordLevelWin('pour', 1, 1);
      expect(p.levelProgress['pour'], 2);
      expect(p.starsFor('pour', 1), 2, reason: 'stars keep the best result, never downgrade');
    });

    test('recordLevelWin keeps the best star rating across replays', () {
      final p = PlayerProfile(livesUpdatedAt: 0);
      p.recordLevelWin('solo', 5, 1);
      p.recordLevelWin('solo', 5, 3);
      p.recordLevelWin('solo', 5, 2);
      expect(p.starsFor('solo', 5), 3);
    });

    test('progress never exceeds the mode\'s level count', () {
      final p = PlayerProfile(
        livesUpdatedAt: 0,
        levelProgress: {'fuse': 100}, // already at the last level
      );
      p.recordLevelWin('fuse', 100, 3);
      expect(p.levelProgress['fuse'], 100);
    });

    test('isLevelUnlocked reflects progress', () {
      final p = PlayerProfile(livesUpdatedAt: 0);
      expect(p.isLevelUnlocked('recipe', 1), isTrue);
      expect(p.isLevelUnlocked('recipe', 2), isFalse);
      p.recordLevelWin('recipe', 1, 2);
      expect(p.isLevelUnlocked('recipe', 2), isTrue);
      expect(p.isLevelUnlocked('recipe', 3), isFalse);
    });

    test('coins awarded are 10 + 5*stars', () {
      final p = PlayerProfile(livesUpdatedAt: 0, coins: 0);
      final earned = p.recordLevelWin('split', 1, 3);
      expect(earned, 25);
      expect(p.coins, 25);
    });
  });

  group('daily challenge', () {
    test('completing once increments the streak and awards 50 coins', () {
      final p = PlayerProfile(livesUpdatedAt: 0, coins: 0);
      final day1 = DateTime(2026, 1, 10);
      expect(p.completeDaily(day1), isTrue);
      expect(p.daily.streak, 1);
      expect(p.coins, 50);
      expect(p.dailyDoneToday(day1), isTrue);
    });

    test('completing again the same day is a no-op', () {
      final p = PlayerProfile(livesUpdatedAt: 0, coins: 0);
      final day1 = DateTime(2026, 1, 10);
      p.completeDaily(day1);
      expect(p.completeDaily(day1), isFalse);
      expect(p.coins, 50, reason: 'no double coin award for the same day');
    });

    test('completing on the next consecutive day extends the streak', () {
      final p = PlayerProfile(livesUpdatedAt: 0);
      p.completeDaily(DateTime(2026, 1, 10));
      p.completeDaily(DateTime(2026, 1, 11));
      expect(p.daily.streak, 2);
    });

    test('skipping a day resets the streak to 1', () {
      final p = PlayerProfile(livesUpdatedAt: 0);
      p.completeDaily(DateTime(2026, 1, 10));
      p.completeDaily(DateTime(2026, 1, 12)); // skipped the 11th
      expect(p.daily.streak, 1);
    });
  });

  group('serialization round-trip', () {
    test('toJson/fromJson preserves every field', () {
      final p = PlayerProfile(livesUpdatedAt: 1000, firstOpenAt: 500);
      p.name = 'Tester';
      p.avatarId = 'a3';
      p.coins = 777;
      p.tempLivesUntil = 999999;
      p.adsRemoved = true;
      p.starterUsed = true;
      p.paletteId = 'neon';
      p.backgroundId = 'bg2';
      p.muted = true;
      p.bestOf = 5;
      p.onboarded = true;
      p.appleUserId = 'apple.user.001';
      p.unlockedPalettes.add('neon');
      p.unlockedBackgrounds.add('bg2');
      p.achievements.add('first_win');
      p.recordLevelWin('pour', 1, 3);
      p.recordAiResult('fuse', true, 4);
      p.completeDaily(DateTime(2026, 1, 10));

      final restored = PlayerProfile.fromJson(p.toJson());

      expect(restored.name, p.name);
      expect(restored.avatarId, p.avatarId);
      expect(restored.lives, p.lives);
      expect(restored.livesUpdatedAt, p.livesUpdatedAt);
      expect(restored.coins, p.coins);
      expect(restored.tempLivesUntil, p.tempLivesUntil);
      expect(restored.adsRemoved, p.adsRemoved);
      expect(restored.firstOpenAt, p.firstOpenAt);
      expect(restored.starterUsed, p.starterUsed);
      expect(restored.levelProgress, equals(p.levelProgress));
      expect(restored.stars, equals(p.stars));
      expect(restored.unlockedPalettes, equals(p.unlockedPalettes));
      expect(restored.unlockedBackgrounds, equals(p.unlockedBackgrounds));
      expect(restored.paletteId, p.paletteId);
      expect(restored.backgroundId, p.backgroundId);
      expect(restored.muted, p.muted);
      expect(restored.bestOf, p.bestOf);
      expect(restored.onboarded, p.onboarded);
      expect(restored.appleUserId, p.appleUserId);
      expect(restored.stats.toJson(), equals(p.stats.toJson()));
      expect(restored.daily.toJson(), equals(p.daily.toJson()));
      expect(restored.achievements, equals(p.achievements));
    });

    test('fromJson tolerates missing fields (fresh-install-shaped defaults)', () {
      final restored = PlayerProfile.fromJson(const {});
      expect(restored.lives, PlayerProfile.lifeMax);
      expect(restored.coins, 100);
      expect(restored.levelProgress['solo'], 1);
    });
  });
}
