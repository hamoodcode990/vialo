import 'daily_challenge.dart';
import 'duel_stats.dart';
import 'level_counts.dart';

/// The player's persisted state, modelled on decant.html's `S` profile
/// fields (see CLAUDE.md / claude_code_economy_prompt.md §2-3).
///
/// This class holds pure data + pure logic — no Flutter, no I/O. Time is
/// always passed in explicitly (as epoch milliseconds) rather than read via
/// `DateTime.now()` internally, so every rule here is deterministic and
/// testable. `ProfileRepository` (profile_repository.dart) is the only
/// thing that touches `shared_preferences` or the wall clock.
class PlayerProfile {
  static const int lifeMax = 5;
  static const int lifeRegenMs = 2 * 60 * 60 * 1000; // 2 hours

  String name;
  String avatarId;

  int lives;
  int livesUpdatedAt; // epoch ms
  int coins;

  /// Epoch ms until which lives are unlimited (an IAP), or 0 if none active.
  int tempLivesUntil;

  bool adsRemoved;
  int firstOpenAt; // epoch ms, gates the 48h starter-pack offer
  bool starterUsed;

  /// Highest unlocked level per mode (1-based; level 1 is always unlocked).
  final Map<String, int> levelProgress;

  /// mode -> (level number as string) -> stars earned (1-3).
  final Map<String, Map<String, int>> stars;

  final List<String> unlockedPalettes;
  final List<String> unlockedBackgrounds;
  String paletteId;
  String backgroundId;

  bool muted;
  int bestOf; // 3 or 5, Quick Match match length

  final DuelStats stats;
  final DailyChallenge daily;
  final Set<String> achievements;

  PlayerProfile({
    this.name = 'Player',
    this.avatarId = 'a1',
    this.lives = lifeMax,
    int? livesUpdatedAt,
    this.coins = 100,
    this.tempLivesUntil = 0,
    this.adsRemoved = false,
    int? firstOpenAt,
    this.starterUsed = false,
    Map<String, int>? levelProgress,
    Map<String, Map<String, int>>? stars,
    List<String>? unlockedPalettes,
    List<String>? unlockedBackgrounds,
    this.paletteId = 'lab',
    this.backgroundId = 'bg1',
    this.muted = false,
    this.bestOf = 3,
    DuelStats? stats,
    DailyChallenge? daily,
    Set<String>? achievements,
  })  : livesUpdatedAt = livesUpdatedAt ?? 0,
        firstOpenAt = firstOpenAt ?? 0,
        levelProgress = levelProgress ?? {for (final m in kModes) m: 1},
        stars = stars ?? {for (final m in kModes) m: <String, int>{}},
        unlockedPalettes = unlockedPalettes ?? ['lab', 'hc'],
        unlockedBackgrounds = unlockedBackgrounds ?? ['bg1'],
        stats = stats ?? DuelStats(),
        daily = daily ?? DailyChallenge(),
        achievements = achievements ?? <String>{};

  // ---- lives -------------------------------------------------------------

  bool livesUnlimited(int nowMs) => tempLivesUntil > 0 && tempLivesUntil > nowMs;

  /// Catches lives up to how many 2-hour ticks have elapsed since
  /// [livesUpdatedAt], capped at [lifeMax]. Call this before reading/using
  /// [lives] so regeneration accrues correctly even while the app was
  /// closed. Mirrors decant.html's `regenLives()`.
  void regenLives(int nowMs) {
    if (lives >= lifeMax) {
      livesUpdatedAt = nowMs;
      return;
    }
    final ticks = ((nowMs - livesUpdatedAt) / lifeRegenMs).floor();
    if (ticks > 0) {
      lives = lives + ticks > lifeMax ? lifeMax : lives + ticks;
      livesUpdatedAt += ticks * lifeRegenMs;
      if (lives >= lifeMax) livesUpdatedAt = nowMs;
    }
  }

  /// Milliseconds until the next life, or 0 if already full / unlimited.
  int nextLifeMs(int nowMs) {
    if (lives >= lifeMax || livesUnlimited(nowMs)) return 0;
    final remain = lifeRegenMs - (nowMs - livesUpdatedAt);
    return remain < 0 ? 0 : remain;
  }

  /// A life is spent on failing a level-ladder attempt — never on starting
  /// or winning. No-op while an unlimited-lives purchase is active.
  void loseLife(int nowMs) {
    if (livesUnlimited(nowMs)) return;
    regenLives(nowMs);
    if (lives > 0) lives--;
  }

  void addLives(int n) {
    lives = lives + n > lifeMax ? lifeMax : lives + n;
  }

  // ---- coins ---------------------------------------------------------------

  void addCoins(int n) {
    if (n == 0) return;
    coins += n;
  }

  /// Spends [n] coins if affordable; returns whether the spend succeeded.
  bool spendCoins(int n, int nowMs) {
    regenLives(nowMs);
    if (coins < n) return false;
    coins -= n;
    return true;
  }

  // ---- level progress / stars ---------------------------------------------

  int starsFor(String mode, int levelNumber) =>
      stars[mode]?[levelNumber.toString()] ?? 0;

  bool isLevelUnlocked(String mode, int levelNumber) =>
      levelNumber <= (levelProgress[mode] ?? 1);

  /// Records a level win: keeps the best star rating for that level, bumps
  /// [levelProgress] if this was the unlock frontier, and awards
  /// `10 + 5*stars` coins. Mirrors the shared shape of decant.html's
  /// `tapSolo` win branch and duel `finish()` level-run branch. Returns the
  /// number of coins awarded.
  int recordLevelWin(String mode, int levelNumber, int starsEarned) {
    final byLevel = stars.putIfAbsent(mode, () => <String, int>{});
    final key = levelNumber.toString();
    final prev = byLevel[key] ?? 0;
    byLevel[key] = starsEarned > prev ? starsEarned : prev;

    final progress = levelProgress[mode] ?? 1;
    if (levelNumber == progress) {
      final maxLevel = kLevelCounts[mode] ?? levelNumber;
      final next = levelNumber + 1;
      levelProgress[mode] = next > maxLevel ? maxLevel : next;
    }

    final coinsEarned = 10 + 5 * starsEarned;
    addCoins(coinsEarned);
    return coinsEarned;
  }

  // ---- duel stats ----------------------------------------------------------

  void recordAiResult(String kind, bool won, int myScore) =>
      stats.recordAiResult(kind, won, myScore);

  void recordPassPlay() => stats.recordPassPlay();

  // ---- daily challenge -----------------------------------------------------

  /// Marks today's daily challenge complete, updates the streak, and awards
  /// 50 coins. [now] must be local time (matches decant.html's `new
  /// Date()`, which reads the device's local calendar day). No-op (and
  /// returns false) if today was already completed. Mirrors
  /// decant.html's `completeDaily()`.
  bool completeDaily(DateTime now) {
    final today = dateStr(now);
    if (daily.lastDate == today) return false;
    final yesterday = dateStr(now.subtract(const Duration(days: 1)));
    daily.streak = daily.lastDate == yesterday ? daily.streak + 1 : 1;
    daily.lastDate = today;
    addCoins(50);
    return true;
  }

  bool dailyDoneToday(DateTime now) => daily.lastDate == dateStr(now);

  /// A deep-enough copy (round-trips through JSON) so state-management
  /// layers that key change notification off object identity/equality see
  /// a genuinely new instance after an in-place mutation.
  PlayerProfile clone() => PlayerProfile.fromJson(toJson());

  // ---- serialization ---------------------------------------------------

  factory PlayerProfile.fromJson(Map<String, dynamic> json) => PlayerProfile(
        name: json['name'] as String? ?? 'Player',
        avatarId: json['avatarId'] as String? ?? 'a1',
        lives: json['lives'] as int? ?? lifeMax,
        livesUpdatedAt: json['livesUpdatedAt'] as int?,
        coins: json['coins'] as int? ?? 100,
        tempLivesUntil: json['tempLivesUntil'] as int? ?? 0,
        adsRemoved: json['adsRemoved'] as bool? ?? false,
        firstOpenAt: json['firstOpenAt'] as int?,
        starterUsed: json['starterUsed'] as bool? ?? false,
        levelProgress: (json['levelProgress'] as Map?)?.map(
          (k, v) => MapEntry(k as String, v as int),
        ),
        stars: (json['stars'] as Map?)?.map(
          (mode, byLevel) => MapEntry(
            mode as String,
            (byLevel as Map).map((k, v) => MapEntry(k as String, v as int)),
          ),
        ),
        unlockedPalettes: (json['unlockedPalettes'] as List?)?.cast<String>(),
        unlockedBackgrounds:
            (json['unlockedBackgrounds'] as List?)?.cast<String>(),
        paletteId: json['paletteId'] as String? ?? 'lab',
        backgroundId: json['backgroundId'] as String? ?? 'bg1',
        muted: json['muted'] as bool? ?? false,
        bestOf: json['bestOf'] as int? ?? 3,
        stats: json['stats'] != null
            ? DuelStats.fromJson(json['stats'] as Map<String, dynamic>)
            : null,
        daily: json['daily'] != null
            ? DailyChallenge.fromJson(json['daily'] as Map<String, dynamic>)
            : null,
        achievements: (json['achievements'] as List?)?.cast<String>().toSet(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'avatarId': avatarId,
        'lives': lives,
        'livesUpdatedAt': livesUpdatedAt,
        'coins': coins,
        'tempLivesUntil': tempLivesUntil,
        'adsRemoved': adsRemoved,
        'firstOpenAt': firstOpenAt,
        'starterUsed': starterUsed,
        'levelProgress': levelProgress,
        'stars': stars,
        'unlockedPalettes': unlockedPalettes,
        'unlockedBackgrounds': unlockedBackgrounds,
        'paletteId': paletteId,
        'backgroundId': backgroundId,
        'muted': muted,
        'bestOf': bestOf,
        'stats': stats.toJson(),
        'daily': daily.toJson(),
        'achievements': achievements.toList(),
      };
}
