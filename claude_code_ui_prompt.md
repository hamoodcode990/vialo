# Task: UI and polish pass on DECANT

Single file: `decant.html`. Self-contained — no build step, no dependencies, no CDN.
Open it in Chrome to test.

## Absolute constraints — do not break these

1. **Do not change any game rule, constant, or engine class.** `Pour`, `Split`, `Fuse`,
   `genTubes`, `invMoves`, `best`, `CAP`, `STALL`, the 7/3/3 SPLIT config, the 9/5
   POUR config, the 6x6 target-4 FUSE config. All of these were tuned by simulation:
   - POUR: sealed tubes + no-take-backs + 24-move stall clock. Removing any one of
     these makes games run 480+ turns and half end in draws.
   - SPLIT: 3 colours each + 1 neutral gold. An even split gives 100% draws.
   - FUSE: no keep-turn, ties to player 2. Keep-turn made P1 win 82%.
2. **No localStorage or sessionStorage.** Keep all state in memory.
3. **Must stay one file.** No external scripts, stylesheets, fonts, or images.
4. **Keep the iOS layer intact**: safe-area insets, 100dvh, audio unlock on first
   touch, blocked double-tap zoom and pinch, blocked rubber-band scroll.
5. After every change, verify in Chrome that all three modes are playable start to
   finish against the Normal bot.

## What to improve

### 1. Screen transitions
Screens currently swap instantly. Add a shared slide-and-fade: forward navigation
slides in from the right, back slides from the left, 260ms, `cubic-bezier(.2,.8,.3,1)`.
Only one screen animates at a time — do not cross-fade two full screens.

### 2. Menu depth
The menu is flat cards on flat background. Give it a real first impression:
- Animate the four logo droplets on load — stagger a fall-and-settle instead of the
  current idle bob.
- Cards should lift on hover/press with a soft shadow, not just change border colour.
- Add a subtle animated gradient in the background that drifts slowly (30s+ cycle,
  very low contrast — it must never compete with the board).

### 3. Win celebration
Winning currently just shows a card. Add:
- The winner's tubes or tiles pulse in sequence, 80ms apart.
- Score counts up from 0 over 600ms with tabular figures.
- Result card scales in from 0.92 with a slight overshoot.
- For a SPLIT win on the gold tube specifically, make the gold flash distinct — that
  tube decides every match and should feel like it.

### 4. Board polish
- Liquid should have a slow, very subtle surface shimmer when idle (2% opacity max).
- When a tube seals, the liquid should settle with a single damped wobble.
- Selected tube: add a faint upward light beam or glow above the rim.
- In SPLIT, make the owner labels (YOU / THEM / GOLD) clearer — currently tiny text.
  Consider a coloured underline bar on the tube instead.

### 5. First-run
Add a 3-step overlay on first launch (in-memory flag, no storage):
one board, claim to seal, claiming keeps your turn. Skippable. Must not appear again
in the same session.

### 6. Match play
Add best-of-3 to all duel modes. Show a small pip indicator (● ● ○) in the score bar.
Alternate who moves first between games. Only offer Rematch at match end.

## Deliverable

Report what you changed and confirm all three modes still play to completion.
Do not add features not listed here.
