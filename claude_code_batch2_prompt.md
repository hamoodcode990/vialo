# Vialo — next batch: theme, onboarding, sign-in, Fuse rework, Recipe visibility, juice, audio

Read this in full before starting. It's ordered on purpose — do the cheap
verification items first, because two of these ("no Recipe," "no sound") might
already be fixed or half-fixed and just not wired up or not noticed. Don't start
new art/animation work until you've confirmed what's actually broken vs. what's
just not visible yet.

Do not touch `lib/game/` engine logic, tuned constants, or balance in this pass.
See CLAUDE.md. This entire batch is UI, content, and presentation.

---

## Step 0 — Triage first (fast, do this before anything else)

1. **Recipe mode**: is it implemented in the engine (`lib/game/recipe.dart` per the
   port plan) but just missing from the mode-select screen? Or was it never
   finished? Report which, before doing any work on it.
2. **Sound**: is there an audio system in the code at all (even the SFX synth
   approach from the HTML prototype) that isn't hooked up to the Flutter UI, or
   was audio never ported? Report which.

Fix whichever of these is a "just not wired up" problem immediately — that's a
connection bug, not new work, and should take minutes not hours.

---

## Step 1 — Recipe mode: make it visible

If Recipe exists in the engine, add it to the mode-select screen alongside Pour,
Split, and Fuse, with the same card treatment. It needs a level ladder like the
other three duel modes if that wasn't already built — check the port plan's
scope before assuming it's missing.

---

## Step 2 — Fuse: replace the number tiles

Current Fuse board uses bare numbers on flat squares — confirmed ugly, hard to
read at a glance, and out of step with the rest of the game.

Replace with something that shows value **through appearance, not just a
numeral**, the way 2048-style games and candy-match games do it:
- Each value tier gets a distinct shape/color/size treatment — e.g. small round
  gems that grow rounder, brighter and more faceted as their value increases, or
  fruit/gem icons that visually escalate.
- Keep a small numeral as a secondary cue for accessibility, but it should not be
  the primary way the player reads the board.
- Fusing two tiles should have a clear, satisfying merge animation (see Step 5) —
  currently this is likely just a value swap with no motion.
- Claimed/sealed squares need a distinct "locked in" visual treatment already
  described in CLAUDE.md (owner-colored border) — keep that, just re-skin the
  base tile.

---

## Step 3 — Theme pass: bright commercial puzzle look

Push further toward Candy Crush / Toon Blast territory, not just "brighter than
before":
- Rounded, chunky, candy-like shapes throughout — buttons, cards, tiles, tube
  caps.
- Bold outlines (dark, 3-4px) around key interactive elements — this is a huge
  part of why games like this read as "juicy" rather than flat.
- Background: full-screen soft gradient per section (menu, board, results),
  animated slowly, not a static flat color.
- Typography: rounded, heavy-weight sans-serif for numbers/scores/headers.
- Confirm this direction doesn't conflict with anything already built in the
  commercial restyle pass — if it's mostly there already, this step is a
  refinement, not a rebuild.

---

## Step 4 — App intro and loading screen

- On cold launch: animated logo/wordmark reveal, 1.5-2.5s max, then straight into
  the home screen (or onboarding on first-ever launch, see Step 6).
- Show a loading indicator if any asset loading takes visible time — never a
  blank white/black frame.
- This is a small, contained addition. Keep it snappy; do not let it become a
  mandatory splash the player sits through on every launch.

---

## Step 5 — Pour animation upgrade

Current pour animation is flat/basic. Improve using the reference approach
already validated in the HTML prototype's `animPour` function (arc trajectory,
droplet stretch, splash on landing, staggered multi-piece pours) — port that
technique's *behavior*, not literal HTML/CSS, into Flutter using
`AnimationController` + `CustomPainter` or a small particle-style overlay.

Also add: a squash-and-stretch settle when liquid lands, and a brief surface
ripple/wobble when a tube is disturbed. Keep it performant — no full-board
rebuilds per frame.

---

## Step 6 — Onboarding (first launch only)

3-4 step skippable overlay, shown once (persisted flag), covering:
1. One board, two players (for duel modes) / sort to win (for Solo)
2. Claim a tube/tile to score it — it locks
3. Lives and coins — what they are, how they work
4. Optional: quick tap-through interactive tutorial on the first Solo level
   rather than static slides, if time allows — static slides are the fallback.

---

## Step 7 — Sign in with Apple

- Add native **Sign in with Apple** (required by App Store guidelines if you offer
  any third-party sign-in — using Sign in with Apple alone avoids that
  requirement entirely, so no need for Google/Facebook sign-in).
- Purpose: let the player's profile (progress, coins, lives, purchases) sync
  across devices. Use CloudKit or a lightweight backend — do not build a full
  backend for this; prefer Apple's own iCloud key-value store or CloudKit
  private database, consistent with the no-analytics, no-tracking posture
  already established.
- Sign-in must be **optional**. The game must remain fully playable and its
  current local-only progress must not be lost for a player who never signs in.
- If already signed in for the same iCloud account on a new device, offer to
  restore progress; do not silently overwrite local progress without asking.

---

## Step 8 — Avatars

I've generated 8 simple placeholder avatars (attached: drop_blue, drop_pink,
star_gold, leaf_green, bolt_purple, flame_orange, moon_teal, heart_red — SVG and
PNG both provided). These are functional placeholders, not final art — flat
vector, simple icon-on-gradient-circle style, chosen only so profile selection
isn't blocked or using generic default circles.

Wire these in now so the profile/avatar-picker screen works end to end. Treat
final avatar art as a separate future task — flag it back to me rather than
spending significant time hand-polishing these; the priority here is a working
picker, not final-quality art.

---

## Step 9 — Sound and music

Confirmed currently missing or not wired up. Add:
- SFX: pour/pour-drip, splash/land, claim (tube/tile sealed), invalid move,
  level win, level lose, button tap, coin gain.
- Background music: one light, non-intrusive loop during gameplay, a different
  calmer one on menu screens. Both must be mutable independently (SFX toggle,
  music toggle) in settings, and both must respect the iOS silent switch.
- If no licensed audio is available yet, generate simple placeholder tones the
  same way the HTML prototype did (synthesized, no files) so the game is not
  silent while real audio assets are sourced separately.

---

## Reporting back

For each step above, report: done / partially done / blocked, and specifically
call out anywhere you made a judgment call I should review (tuning of animation
timing, choice of onboarding copy, etc.) rather than silently deciding for me.

Do not let this turn into one giant unreviewable diff — commit in logical chunks
per step so I can look at Fuse separately from audio separately from sign-in.

---

## Step 10 — Level map: a "road" with story framing, not a flat grid

Currently levels are presumably shown as a flat list/grid. Reference feel: Candy
Crush's winding path map — a snaking road across a themed landscape, level nodes
along it, some kind of light story/chapter framing.

**Scope this honestly before building — report back on feasibility rather than
guessing:**

- Full 3D (real depth, camera, lighting) is out of scope for a Flutter app with
  no existing 3D pipeline. Do not add a 3D engine dependency for this.
- What's realistic and should be built instead: a **2D winding path** with
  perspective tricks — nodes of varying size/position to imply depth, parallax
  background layers, a moving path that curves left/right/up as you scroll, node
  states (locked/current/complete/starred). This is the actual technique games
  like Candy Crush and Toon Blast use — it reads as dimensional without being a
  real 3D scene.
- Group levels into chapters/worlds (e.g. every 20-25 levels = one themed zone
  with its own background/palette), each with a short title card when you enter
  it ("Chapter 2: The Deep Sort" or similar placeholder-style naming — I'll
  refine actual names later, just get the structure working).
- A one-line story blurb per chapter is enough for now — do not write extensive
  narrative content; this is a framing device, not a story mode.
- This applies to Solo's level ladder primarily. Decide and report whether the
  same path treatment makes sense for the duel modes' level ladders too, or
  whether those should stay as a simpler list since they're vs-AI progression
  rather than a narrative journey — your call, tell me which you picked and why.

Build this as its own scrollable widget so it doesn't entangle with the board
rendering work in other steps. This is likely the largest single item in this
batch — if it needs to be split into its own follow-up pass rather than done
alongside everything else here, say so up front rather than partially doing it.
