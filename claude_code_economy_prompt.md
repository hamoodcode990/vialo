# DECANT — commercial restyle, player profile, lives, coins, level progression

Reference direction: mainstream water-sort puzzle games (e.g. Water Color Sort
Puzzle, Magic Sort). Bright, glossy, chunky, satisfying.

**Do not change any game rule, tuned constant, or mode balance.** The stall clock,
no-take-backs, Split's single gold colour, Fuse's no-chaining and komi, and the
Recipe rebalance all fix real bugs found by simulation. See CLAUDE.md.

---

## 1. Visual restyle — replace the parchment/atelier look

- Bright, high-saturation palette. Vivid blues, greens, oranges, purples, pinks,
  with clear separation between adjacent colours.
- Tubes: clean glass cylinders, strong specular highlight, rounded bottom, thin
  bright rim. Liquid glossy with a visible curved surface.
- Background: soft vertical gradient, subtly animated. Not flat.
- Buttons: rounded, filled, slight bevel and drop shadow. Chunky and tappable.
- Rounded sans-serif throughout. No serif wordmark. Large, bold, friendly.
- Big feedback: pour splash, colour-complete burst, level-complete celebration
  with coins flying to the counter.

---

## 2. Player profile

Persisted in localStorage. Visible from a header avatar on every screen.

```
profile {
  name            // editable, defaults to "Player"
  avatarId        // pick from ~8 built-in avatars
  lives           // starts 5, max 5
  livesUpdatedAt  // epoch ms, for regeneration
  coins           // starts 100
  levelProgress   // per mode: highest unlocked level
  stars           // per level: 0-3
  totalStars
  streak          // daily play streak
  stats           // wins, losses, best times, per mode
}
```

Header bar, always visible: avatar · lives (with countdown to next) · coins.
Tapping lives or coins opens the store.

---

## 3. Lives

- Start with 5. Maximum 5 from regeneration.
- **One life regenerates every 2 hours.** Show a live countdown to the next one.
- Regeneration is computed from `livesUpdatedAt` on load — it must accrue while
  the app is closed. Do not use a timer that only runs in-session.
- **A life is spent on FAILING, never on starting a level.** Specifically:
  - Solo: lose a life when the board becomes unsolvable or the player restarts a
    level they were stuck on.
  - Duel: lose a life when you lose a match to the bot.
  - Winning costs nothing. Quitting a level you have not failed costs nothing.
- At 0 lives: the player can still watch a rewarded ad for 1 life, spend coins, or
  wait. Never a hard wall with only a purchase option.
- Purchases can push the balance above 5; regeneration stops at 5 but bought lives
  are not lost.

---

## 4. Coins

- Start with 100.
- **Earn:** finishing a level (10, +5 per star), daily challenge (50), beating a
  bot (25 Easy / 40 Normal / 60 Hard), achievements, daily streak bonus,
  rewarded video (25).
- **Spend:** extra undo (20), add-a-tube hint (60), reveal-a-move hint (40),
  refill 1 life (75), cosmetic bottle styles and backgrounds (300–800).
- Coin counter animates on change. Coins fly from the board to the counter on a win.

---

## 5. Level progression

Every mode gets its own level ladder. Level 1 unlocked, everything else locked
until the previous level is cleared.

| Mode | Levels | Progression |
|---|---|---|
| Solo sort | 300 | colours 4→12, empty tubes 3→1, gradual |
| Pour (vs bot) | 150 | bot Easy→Normal→Hard, board grows |
| Split (vs bot) | 150 | same curve |
| Fuse (vs bot) | 100 | same curve |
| Recipe (vs bot) | 100 | same curve |

- Levels are **generated from a seed derived from the level number**, not stored.
  `seed = hash(modeId, levelNumber)` — deterministic, so level 47 is the same board
  for every player, and 800 levels cost no file size.
- Difficulty curve must be a defined function of level number, not hand-tuned.
- 3 stars per level: 3 = won under the par move count, 2 = won, 1 = won with hints.
- Level select: scrolling map or grid, locked levels greyed with a padlock, stars
  shown under each. Show the next milestone.

**No multiplayer.** Human vs AI only for now.

---

## 6. IAP — no Pro tier, no level gating

Remove the existing Pro tier entirely. All 800 levels are free to reach.

| Item | Price |
|---|---|
| Refill lives to 5 | $0.99 |
| Unlimited lives, 2 hours | $1.99 |
| Unlimited lives, 7 days | $6.99 |
| 500 coins | $1.99 |
| 1,200 coins | $3.99 |
| 3,000 coins | $7.99 |
| Remove ads | $2.99 |
| Starter pack (unlimited lives 24h + 1,000 coins + a bottle skin) | $2.99, shown once, first 48 hours |

Never sell gameplay advantage in a duel. Hints and lives only.

---

## 7. Ads — deliberately light

- Rewarded video only, always player-initiated: +1 life, +25 coins, or a free hint.
- At most one interstitial every 5 levels, never mid-level, never before the
  player's first game.
- No banners. No floating ads.
- This is a deliberate difference from the reference apps, whose reviews complain
  specifically about ad volume.

---

## 8. Keep

- Single self-contained HTML file, no external assets.
- iOS layer: safe-area insets, 100dvh, audio unlock on first touch, blocked
  double-tap zoom and pinch, blocked rubber-band scroll.
- Engine classes stay pure logic with no DOM access — they get ported to Dart later.

---

## Verify before reporting done

1. All four duel modes and Solo play to completion.
2. Lives regenerate correctly across a page reload with time elapsed (test by
   setting `livesUpdatedAt` back 4 hours — should grant 2 lives, cap at 5).
3. A life is never deducted for starting or winning.
4. Level 2 is locked until level 1 is cleared, in every mode.
5. Coins, lives, level progress and stars all survive a reload.
6. At 0 lives the player still has a non-paying route forward.
