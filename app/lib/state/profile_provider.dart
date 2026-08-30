import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) => ProfileRepository());

/// Owns the single [PlayerProfile] for the app session, persisting every
/// mutation via [ProfileRepository]. `PlayerProfile` is a mutable, in-place
/// class (matching decant.html's `S` object) with no `==` override, so
/// every mutating method here commits a [PlayerProfile.clone] — a distinct
/// instance — rather than the same mutated reference, which is what
/// actually drives Riverpod's change notification.
class ProfileController extends AsyncNotifier<PlayerProfile> {
  late final ProfileRepository _repo;

  @override
  Future<PlayerProfile> build() async {
    _repo = ref.watch(profileRepositoryProvider);
    return _repo.load();
  }

  PlayerProfile get _current => state.value ?? PlayerProfile();

  /// Public read of the current profile — used by AccountController, which
  /// lives outside this file and needs a snapshot to compare/serialize
  /// rather than a mutation method of its own.
  PlayerProfile get currentProfile => _current;

  int _now() => DateTime.now().millisecondsSinceEpoch;

  void _commit(PlayerProfile p) {
    state = AsyncValue.data(p);
    unawaited(_repo.save(p));
  }

  /// Escape hatch for callers with their own pure mutation logic (e.g.
  /// monetization/reward_mapping.dart) instead of a bespoke method per
  /// action — still goes through the same clone-then-commit path so
  /// persistence and change notification stay correct.
  int get nowMs => _now();

  void applyMutation(void Function(PlayerProfile profile) mutate) {
    final p = _current;
    mutate(p);
    _commit(p.clone());
  }

  /// Call whenever a screen that shows lives is shown/resumed, so the
  /// countdown/regeneration stays live.
  void regenLivesNow() {
    final p = _current;
    p.regenLives(_now());
    _commit(p.clone());
  }

  void loseLife() {
    final p = _current;
    p.loseLife(_now());
    _commit(p.clone());
  }

  void addLives(int n) {
    final p = _current;
    p.addLives(n);
    _commit(p.clone());
  }

  void grantUnlimitedLives(Duration duration) {
    final p = _current;
    final until = _now() + duration.inMilliseconds;
    if (until > p.tempLivesUntil) p.tempLivesUntil = until;
    _commit(p.clone());
  }

  void addCoins(int n) {
    final p = _current;
    p.addCoins(n);
    _commit(p.clone());
  }

  bool spendCoins(int n) {
    final p = _current;
    final ok = p.spendCoins(n, _now());
    if (ok) _commit(p.clone());
    return ok;
  }

  /// Returns the coins awarded.
  int recordLevelWin(String mode, int levelNumber, int starsEarned) {
    final p = _current;
    final earned = p.recordLevelWin(mode, levelNumber, starsEarned);
    _commit(p.clone());
    return earned;
  }

  void recordAiResult(String kind, bool won, int myScore) {
    final p = _current;
    p.recordAiResult(kind, won, myScore);
    _commit(p.clone());
  }

  void recordPassPlay() {
    final p = _current;
    p.recordPassPlay();
    _commit(p.clone());
  }

  bool completeDailyNow() {
    final p = _current;
    final done = p.completeDaily(DateTime.now());
    if (done) _commit(p.clone());
    return done;
  }

  void setName(String name) {
    final p = _current;
    p.name = name.trim().isEmpty ? 'Player' : name.trim();
    _commit(p.clone());
  }

  void setAvatar(String id) {
    final p = _current;
    p.avatarId = id;
    _commit(p.clone());
  }

  void setMuted(bool muted) {
    final p = _current;
    p.muted = muted;
    _commit(p.clone());
  }

  void setBestOf(int n) {
    final p = _current;
    p.bestOf = n;
    _commit(p.clone());
  }

  void completeOnboarding() {
    final p = _current;
    if (p.onboarded) return;
    p.onboarded = true;
    _commit(p.clone());
  }

  void linkAppleAccount(String appleUserId) {
    final p = _current;
    p.appleUserId = appleUserId;
    _commit(p.clone());
  }

  void unlinkAppleAccount() {
    final p = _current;
    p.appleUserId = null;
    _commit(p.clone());
  }

  /// Wholesale-replaces the profile — used only for the explicit "Restore
  /// from iCloud" choice (CLAUDE.md Step 7), never as a side effect of any
  /// other action, since it discards whatever local progress preceded it.
  void replaceProfile(PlayerProfile replacement) {
    _commit(replacement.clone());
  }

  void setAdsRemoved() {
    final p = _current;
    p.adsRemoved = true;
    _commit(p.clone());
  }

  void setStarterUsed() {
    final p = _current;
    p.starterUsed = true;
    _commit(p.clone());
  }

  /// Unlocks (if needed) and selects a tube palette. Returns false if it
  /// wasn't already owned and the coin spend failed.
  bool selectPalette(String id, int price) {
    final p = _current;
    if (!p.unlockedPalettes.contains(id)) {
      if (!p.spendCoins(price, _now())) return false;
      p.unlockedPalettes.add(id);
    }
    p.paletteId = id;
    _commit(p.clone());
    return true;
  }

  bool selectBackground(String id, int price) {
    final p = _current;
    if (!p.unlockedBackgrounds.contains(id)) {
      if (!p.spendCoins(price, _now())) return false;
      p.unlockedBackgrounds.add(id);
    }
    p.backgroundId = id;
    _commit(p.clone());
    return true;
  }
}

final profileControllerProvider = AsyncNotifierProvider<ProfileController, PlayerProfile>(
  ProfileController.new,
);

/// Convenience read of the current profile, defaulting to a fresh one
/// during the brief window before the first load resolves — main.dart
/// gates the app shell on that load, so screens can treat this as always
/// "the real profile."
final profileProvider = Provider<PlayerProfile>((ref) {
  return ref.watch(profileControllerProvider).value ?? PlayerProfile();
});
