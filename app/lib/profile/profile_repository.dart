import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'player_profile.dart';

/// Loads/saves [PlayerProfile] as a single JSON blob in shared_preferences,
/// mirroring decant.html's single `localStorage` key. This is the only file
/// in lib/profile/ that touches a platform plugin or the wall clock — the
/// profile's own rules (lives regen, coin spend, level-win bookkeeping) stay
/// pure and are tested separately in player_profile_test.dart.
class ProfileRepository {
  static const String storageKey = 'vialo_profile_v1';

  /// Loads the saved profile (or creates a fresh one on first launch /
  /// corrupt data), then regenerates lives up to now so they've accrued
  /// correctly even while the app was closed.
  Future<PlayerProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    final now = DateTime.now().millisecondsSinceEpoch;

    PlayerProfile profile;
    if (raw == null) {
      profile = PlayerProfile(livesUpdatedAt: now, firstOpenAt: now);
    } else {
      try {
        profile = PlayerProfile.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (_) {
        // Corrupt save data — start fresh rather than crash on launch.
        profile = PlayerProfile(livesUpdatedAt: now, firstOpenAt: now);
      }
    }

    profile.regenLives(now);
    return profile;
  }

  Future<void> save(PlayerProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(profile.toJson()));
  }
}
