# VIALO

Single self-contained HTML file (`decant.html`). No build step, no dependencies,
no CDN, no external assets. Open it in Chrome to test.

Shared-board strategy game themed as Madame Corvel's atelier — the player is an
apprentice perfumer.

**Visual identity (updated, supersedes earlier "no dark mode" decision):**
dark, futuristic, simple. The original theme was warm ivory/parchment with a
serif wordmark and an explicit "no dark mode, no neon, no glow" rule, settled
after several rounds of iteration — that rule is now explicitly overridden by
the user (2026-08-30): the app is moving to a dark, tech-forward look (deep
near-black/navy chrome, saturated neon-adjacent accents, glow effects
permitted) while staying simple/uncluttered, not busy or gaudy. This applies
to the Flutter app (`app/`), which is the actual shipping target. decant.html
hasn't been re-themed to match as of this note — it's still the original warm
light theme — since it's the reference implementation, not the shipping
vehicle (see Shipping below); re-theme it too if it's ever used for anything
user-facing again.

The tube colour palettes (`app/lib/theme/tube_palettes.dart` /
decant.html's `PAL`) are unaffected by this — those are deuteranopia-audited
gameplay cosmetics, not app chrome, and stay as measured regardless of what
the surrounding UI looks like.

## Do not change these without being asked

Every value below was tuned by simulation. Each fixes a real bug that took hundreds
of simulated games to find. In the source they look arbitrary. They are not.

**POUR** (sort duel, 9 colours / 5 empty tubes)
- Sealed tubes cannot be poured from. Claiming keeps your turn.
- No take-backs: you cannot immediately reverse the move just played against you.
- 24-move stall clock: if nobody claims within 24 moves the board locks.
- Removing any one of these makes games run 480+ turns with ~50% draws.

**SPLIT** (7 colours / 3 empty — 3 each plus 1 neutral gold)
- The single neutral colour is essential. An even split produced **100% draws**
  across 400 games, because every colour completes and the scores always tie.
- A tube scores for the owner of the colour, not whoever poured it.
- No chaining here.

**FUSE** (6x6, values 1–3, target 4)
- No keep-turn on a claim. With chaining, player 1 won 82%.
- Ties go to player 2 (komi). Balance measured at 52/48.

**RECIPE**
- Rebalanced from a 62/38 first-mover skew to ~50/50 by measurement. Do not adjust
  by feel — re-measure if you touch it.

## Monetization

- Pro is **$4.99**, one-time, no subscription.
- Gate **content only**: levels 1–80 free, 81–200 Pro.
- Never gate difficulty or any duel mode. All three difficulties and all four modes
  stay free. Gating competitive access costs more in reviews than it earns.
- Never sell gameplay advantage.

## Technical constraints

- Must remain a single file with no external references.
- Keep the iOS layer intact: safe-area insets, `100dvh`, WebAudio unlock on first
  touch, blocked double-tap zoom and pinch, blocked rubber-band scroll.
- Engine classes (`Pour`, `Split`, `Fuse`, `Recipe`, `genTubes`, `invMoves`, `best`)
  are pure logic with no DOM access. Keep them that way — they get ported to Dart
  for the iOS build.
- localStorage is used for saves. Do not add other browser storage APIs.

## How to work on this

State problems, then solve them your way — prescriptive implementation detail is
not wanted. But when a change touches game rules or balance, **measure it**: run a
few hundred bot-vs-bot games and report win rates, draw rate, and average game
length before and after. That method is what found every bug listed above.

After any change, confirm all four duel modes and Solo still play to completion.

## Shipping

iOS via a Flutter port, reusing the Codemagic and Apple signing pipeline from the
game61 project. The HTML is the reference implementation, not the shipping vehicle
— Apple rejects web wrappers under guideline 4.2.
