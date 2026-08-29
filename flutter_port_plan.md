# VIALO — Flutter port

Port the working `decant.html` prototype to Flutter for iOS. The HTML is the
reference implementation and the source of truth for rules and balance.

Reuse the pipeline from the game61 project: Codemagic CI, existing Apple developer
account, existing signing setup.

---

## Order of work — do not reorder

The engines first, alone, with tests. Nothing else until they pass.

### Phase 1 — Engines (no UI, no Flutter widgets)

Port these from the HTML to pure Dart in `lib/game/`:

| HTML | Dart |
|---|---|
| `genTubes`, `invMoves`, `mb32` | `lib/game/generator.dart` |
| `Pour` | `lib/game/pour.dart` |
| `Split` | `lib/game/split.dart` |
| `Fuse` | `lib/game/fuse.dart` |
| `Recipe` | `lib/game/recipe.dart` |
| `best` (AI) | `lib/game/ai.dart` |

**No Flutter imports in any of these files.** Pure Dart only. They must be runnable
in a plain Dart test with no widget binding.

**Critical: the RNG must produce identical output to the JS version.** `mb32` is
mulberry32 using `Math.imul` and `>>> 0`. Dart ints are 64-bit, so you must mask to
32 bits explicitly. Verify by generating boards for seeds 1..50 in both JS and Dart
and diffing them. If they diverge, every tuned balance number is invalid.

### Phase 2 — Engine tests

Port the invariants and add balance tests. All must pass before any UI work:

- Same seed produces an identical board (required for reproducible levels)
- No board is born solved or stuck
- Piece counts conserved
- Boards contain mixed tubes — a regression guard: scrambling with the *forward*
  legality rule leaves every tube uniform and produces no puzzle
- Sealed tubes can never be poured from
- Games always terminate (guard at 400 moves)
- Claiming keeps the turn in Pour; turns always alternate in Fuse and Split
- **Balance**: run 300 bot-vs-bot games per mode and assert win rates stay near the
  measured values. Pour ~50/50 with the stall clock active; Split ~50/50 with the
  single gold colour; Fuse ~52/48 with ties to player 2; Recipe ~50/50.

Any deviation means the port broke something. Fix it before continuing.

### Phase 3 — Persistence

`shared_preferences` (or Isar if the attempt log grows). Model on the HTML profile:
lives, `livesUpdatedAt`, coins, per-mode level progress, stars, streak, stats.

Lives regenerate from the stored timestamp so they accrue while the app is closed.
A life is spent on failing, never on starting or winning.

### Phase 4 — UI

Rebuild the screens. The CSS glass and liquid rendering becomes `CustomPainter`.
Match the HTML's look and feel; it is the design reference.

Screens: home, level select per mode, game board (tube modes), game board (Fuse
grid), result, store, profile, settings.

### Phase 5 — Monetization

RevenueCat for IAP. AdMob for rewarded video only. Products as specified in the
HTML build. `Restore Purchases` must exist and be tested: buy → delete app →
reinstall → restore.

### Phase 6 — Ship

Bundle ID under the existing Sabla Studio account. Codemagic build, TestFlight
first, then submit.

---

## Apple submission checklist

- Description claims match the build exactly
- Price in description matches App Store Connect
- No mention of Android or Google Play anywhere
- Terms of Use and privacy policy links in the description
- Restore Purchases implemented and tested
- Content visible before the user does anything — no empty first screen
- Subscription/IAP pricing and terms plain on the paywall
- Review notes explaining the app plus a promo code
- Distinctive design — guideline 4.3 (spam/duplicate) is the most common rejection
  and this is a crowded genre. The duel modes are the defence; make them visible
  early in the screenshots.
- MinimumOSVersion 15.0 or above

---

## Do not

- Do not "improve" any rule or tuned constant. See CLAUDE.md. Every one fixes a bug
  found by simulation, and the balance tests in Phase 2 will catch it if you do.
- Do not start UI work before the engine tests pass.
- Do not port the HTML's DOM structure. Rebuild the UI idiomatically in Flutter.
