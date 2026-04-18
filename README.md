# Skully Bones Treasure Adventure

`Skully Bones Treasure Adventure` is a mobile-first logic puzzle game based on 1-star Star Battle rules. The placed object should be called a `token` in code and design documentation, even if the current visual theme presents it as a queen.

The first development phase should focus on a polished local/offline mobile experience: a responsive puzzle board, smooth touch feedback, verified logic-only puzzles, local progress, stars, coins, and a minimum first content set of 500 levels.

## Current Status

This repository currently contains planning and design documents. No app scaffold has been created yet.

The `docs/archive/` folder contains the original brainstorming and research documents that informed this spec.

---

## Game Summary

Each puzzle is played on an N x N grid divided into exactly N irregular colored regions. The player places exactly N tokens on the board.

The game is solved when:

- Every row contains exactly one token.
- Every column contains exactly one token.
- Every colored region contains exactly one token.
- No two tokens touch horizontally, vertically, or diagonally.

This is a 1-star Star Battle puzzle. It is not classic N-Queens. Longer shared diagonals are allowed as long as the tokens are not adjacent.

---

## Canonical Rules

For an N x N puzzle:

- There are exactly N colored regions.
- Every region contains at least one cell.
- A completed solution contains exactly N tokens.
- Each row has one token.
- Each column has one token.
- Each region has one token.
- Any two tokens must have Chebyshev distance >= 2.

The no-touch rule means a placed token forbids its 3x3 neighborhood, excluding the center cell that contains the token.

### Star Battle Origin

Star Battle puzzles use an N x N grid divided into N irregular regions. For a K-star puzzle, place exactly K stars in every row, column, and region, with no two stars touching in any of the 8 directions. This project uses K = 1.

| Star Battle Term | Project Term |
|---|---|
| Star | Token (currently themed as a queen) |
| Region / shape | Colored region |
| 1 star per row | 1 token per row |
| 1 star per column | 1 token per column |
| 1 star per region | 1 token per colored region |
| Stars cannot touch | Tokens cannot touch in all 8 directions |

### Why Not N-Queens

The classic N-Queens puzzle forbids any two queens from sharing a diagonal of any length. This project only forbids adjacent cells (Chebyshev distance < 2). The queen theme borrows the feel of N-Queens, but the validator must not reject longer shared diagonals. The canonical constraint is Star Battle adjacency, not chess attack lines.

---

## Solution Requirements

Every puzzle must have exactly one valid solution.

A valid puzzle must pass both checks:

1. **Unique-solution check:** exactly one arrangement satisfies all row, column, region, and no-touch constraints.
2. **Logic-solve check:** the puzzle can be solved through the official deduction set without guessing, trial-and-error, or player backtracking.

Developer tools may use search/backtracking to prove uniqueness. Difficulty grading should be based on the official deduction set.

---

## Official Deduction Set

These four deduction families plus placement housekeeping are the **player-facing vocabulary** — the techniques the game teaches and the hint system explains. The grader uses one additional family internally (higher-order confinement) to validate Master-band puzzles; see [docs/level-generation.md](docs/level-generation.md) Stage 4 for the full grader set.

| # | Deduction | Meaning |
|---|---|---|
| 1 | Giveaway Cell | A row, column, or region has only one remaining candidate, so the token must go there. |
| 2 | Confinement | If all remaining candidates of one axis lie within another axis, cells outside that intersection can be eliminated. Applies in both directions: if a region's candidates all lie in one row (or column), the rest of that row (or column) can be cleared; and if a row (or column) has all its candidates inside one region, the rest of that region can be cleared. |
| 3 | Touch-All Elimination | A candidate outside a region touches every remaining candidate inside that region, so the outside candidate can be eliminated. |
| 4 | Contradiction / Blocking Elimination | Placing a token in a candidate cell would immediately eliminate all candidates in another row, column, or region, so that candidate can be eliminated. |

After a correct placement, housekeeping should mark:

- All other cells in the same row.
- All other cells in the same column.
- All other cells in the same region.
- All adjacent cells in the 3x3 no-touch neighborhood.

### Difficulty Grading

Difficulty should be based on:

- Number of required deduction steps.
- Depth of deduction chains before the next forced placement appears.
- Which deduction families are required.
- How visually obvious or hidden the deductions are.
- Region complexity and candidate density.
- Whether early progress is available immediately or only after layered eliminations.

Suggested bands:

- **Easy:** mostly Giveaway Cell plus housekeeping.
- **Medium:** frequent Confinement and Touch-All cases with short chains.
- **Hard:** all four deduction families, including repeated Touch-All and Contradiction chains.
- **Master:** long chains, subtle spatial eliminations, and tight candidate layouts.

---

## Board Size

V1 uses a fixed **8 x 8** grid (8 regions, 8 tokens per puzzle).

In later phases, grid size becomes dynamic and scales with difficulty and progression. Larger grids introduce more complex region layouts and deeper deduction chains.

---

## Player Interaction

V1 uses simple mobile-first controls:

- **Single tap:** toggle a player-placed X mark on a cell.
- **Double tap:** attempt to place a token.
- **Correct double tap:** place the token and perform auto-housekeeping marks.
- **Incorrect double tap:** lose 1 life.
- Start each puzzle with **3 lives**.
- Reaching 0 lives fails the puzzle and requires a restart.

Double-tap validation checks against the hidden unique solution immediately. It does not only check whether the move breaks visible current constraints. A cell can appear possible and still be wrong if it is not the predefined solution cell.

### X Marks

There are two visual categories of X marks:

- **Player-placed X marks:** toggled by single tap. The player can add and remove these freely. Visually, a player X is rendered as a **treasure-map "X marks the spot"** — a hand-drawn charcoal/ink X, evoking a pirate treasure map. Tactile and "sketched" rather than geometric.
- **Auto-housekeeping X marks:** placed automatically after a correct token placement. Visually, an auto X is rendered as a **skull and crossbones**, clearly and immediately distinct from the player X. Auto marks **cannot be removed** by the player.

The two mark styles must remain distinguishable for colorblind and low-vision players — the distinction is carried by shape (charcoal X vs. skull-and-crossbones silhouette), not color alone.

### Undo and Restart

- **Undo:** reverts the last player action (placing or removing an X mark). Undo does **not** reverse a life loss or remove a placed token. Basic undo is free in V1.
- **Restart:** fully resets the puzzle. Lives reset to 3. All marks and placed tokens are cleared. The player can still earn the full 3 stars on a restarted puzzle. Previous failed attempts do not affect the star rating of a successful run.

---

## Progression System

### Stars (Cumulative Score)

Stars are the primary progression metric and serve as the effective **score**. They are **persistent and cumulative** across every play session.

Star awards per successful level completion:

| Result | Stars |
|---|---:|
| Perfect clear — 0 lives lost | 3 |
| Clear with 1 life lost | 2 |
| Clear with 2 lives lost | 1 |
| Puzzle failed — 0 lives remaining | 0 (must restart) |

Stars are awarded based solely on the **successful completion run**, not on previous failed attempts. A restarted puzzle is scored exactly as if it were played for the first time.

Total accumulated stars represent the player's overall progress and achievement.

### Coins

Coins are an earnable local currency. They are awarded on level completion:

| Result | Coins |
|---|---:|
| Perfect clear | 100 |
| Clear with 1 life lost | 60 |
| Clear with 2 lives lost | 30 |

Coins are **spending money**. The exact coin sinks are deferred to a later phase. Planned future uses include purchasing hints, undo-life-loss operations, and cosmetic unlocks. Coins must not be connected to paid purchases; the game is pay-once.

### Level Progression

Levels are **linear**. Level completion gates progression to the next level. There are no branching paths, world maps, or pack-based unlocks in V1.

---

## V1 Product Scope

V1 is local/offline and pay-once.

**Included:**

- Mobile puzzle board (8 x 8 grid).
- Linear level selection.
- At least 500 pre-generated and verified puzzles.
- Unique-solution validation tooling.
- Logic-solve validation using the official deduction set.
- Three-life puzzle attempts.
- Player X marks (toggleable) and auto-housekeeping marks (visually distinct, non-removable).
- Basic undo and full restart.
- Local stars (cumulative) and coins progression.
- Local settings: sound, haptics, and accessibility outlines.

**Deferred to later phases:**

- Hint system (player-facing hints based on the four deductions).
- Coin spending (hints, undo-life-loss, cosmetics).
- Dynamic grid sizes beyond 8 x 8.
- Timed levels.
- Accounts and cloud sync.
- Global leaderboards.
- Daily missions and streaks.
- Events and tournaments.
- Pets or companions.
- Cosmetic shards/fragments.
- Advanced treasure chest reward presentation.
- Remote level delivery.
- Remote economy tuning and A/B testing.
- Live operations.
- Boosters.

The long-term content ambition is 5,000+ verified puzzles. That is not a launch requirement.

---

## Monetization Model

The game is **pay-once**.

Do not design around post-purchase monetization, ads, or IAP. V1 rewards, coins, and progression should all be compatible with a premium offline game.

---

## Tech Stack

The recommended stack is **Flutter-first**:

| Area | Recommendation | Why |
|---|---|---|
| App framework | Flutter + Dart | Strong mobile UI, custom rendering, animation control, one iOS/Android codebase. |
| Puzzle engine | Pure Dart package | Testable rules, solver, generator support, and no UI coupling. |
| Board rendering | Flutter `CustomPainter` / Canvas | Precise control over cells, regions, marks, highlights, and animated overlays. |
| State management | Riverpod | Testable app state for sessions, progress, settings, and level selection. |
| Local database | Drift / SQLite | Robust local progress, level metadata, stars, coins, and future migrations. |
| Tiny settings | shared_preferences | Good for non-critical settings such as sound, haptics, and accessibility toggles. |
| Interactive animation | Rive | Best fit for stateful, premium-feeling vector animation and future pets/mascots. |
| One-shot animation | Lottie | Useful for canned noninteractive celebrations if an artist pipeline needs it. |
| Game effects | Flame, selectively | Use only if particle effects, sprite systems, or a game loop become useful. |
| Generator tooling | Dart CLI first | Keeps the generator close to the puzzle engine; optimize later only if needed. |

### Why Flutter

Flutter is a strong fit because this is a polished 2D puzzle game with mobile-first interactions, not a physics-heavy 3D game. The board needs custom drawing, fast tap feedback, smooth animation, and clean integration with app screens such as level select, settings, and progression.

Relevant references:

- [Flutter Casual Games Toolkit](https://docs.flutter.dev/resources/games-toolkit)
- [Flutter Impeller rendering engine](https://docs.flutter.dev/perf/impeller)
- [Flutter animation library](https://api.flutter.dev/flutter/animation/)
- [Flutter CustomPainter](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html)
- [Flutter performance best practices](https://docs.flutter.dev/perf/best-practices)
- [Flame game engine](https://docs.flame-engine.org/latest/index.html)
- [Rive Flutter runtime](https://rive.mintlify.dev/docs/runtimes/flutter/flutter)
- [Lottie for Flutter](https://pub.dev/packages/lottie)
- [Riverpod](https://riverpod.dev/)
- [Drift](https://pub.dev/documentation/drift/latest/index.html)
- [shared_preferences](https://pub.dev/packages/shared_preferences)

### Why Not React Native

React Native can build good mobile apps, but this game depends heavily on custom animated board interactions. React Native performance requires careful attention to JS thread work, native-driver animation behavior, and library compatibility. Flutter gives more direct control over painting and animation in one rendering model.

React Native may be reconsidered only if the team has a much stronger React Native skill base and is prepared to invest heavily in custom native animation/performance work.

### Why Not Unity

Unity is powerful, but it is more engine than this game currently needs. This project is a 2D logic puzzle with a lot of precise UI, local progression, accessibility settings, text, and level management. Flutter should deliver a smaller, cleaner, more app-native implementation.

Unity becomes more attractive only if the game direction shifts toward heavy particles, 3D scenes, or a broader arcade-game presentation.

---

## Proposed Repository Layout

```text
apps/
  mobile/
    Flutter app shell
    screens, routing, themes, audio, settings, persistence

packages/
  puzzle_core/
    pure Dart rules, models, validator, solver, difficulty grading

tools/
  level_generator/
    Dart CLI for generation, uniqueness checks, logic-solve checks, exports

assets/
  levels/
    bundled verified level packs (pre-generated JSON)
  animations/
    Rive or Lottie animation assets
  audio/
    sound effects and music loops

docs/
  archive/
    original brainstorming and research documents
```

The core rule engine should not depend on Flutter. It should be usable from:

- The mobile app.
- Unit tests.
- Generator tools.
- Future level editors.

---

## Core Data Model Direction

Suggested pure-Dart model concepts:

```text
PuzzleDefinition
  id
  size              (8 for v1)
  regions
  solution
  difficulty
  metadata

Cell
  row
  col

Region
  id
  cells

PuzzleSession
  puzzleId
  placedTokens
  playerXMarks
  autoXMarks
  livesRemaining
  undoStack
  startedAt
  completedAt

ProgressRecord
  puzzleId
  bestStars
  completed
  coinsEarned

PlayerProfile
  totalStars        (cumulative across all levels)
  totalCoins
  currentLevel      (linear progression index)
```

Puzzle files should be pre-generated JSON assets bundled with the app. Level metadata and progress should be stored in Drift/SQLite.

---

## Rendering and Interaction Strategy

The board should be rendered as layered visual concerns:

1. **Static board layer:** region fills, region boundaries, grid lines.
2. **Mark layer:** player X marks and auto-housekeeping X marks (visually distinct styles).
3. **Token layer:** placed tokens.
4. **Feedback layer:** tap ripples, mistake shakes, success pulses, completion effects.

Implementation principles:

- Keep board geometry deterministic and cached.
- Repaint only what changed when possible.
- Keep solver computation out of the paint path.
- Avoid expensive opacity/clipping patterns in hot animations.
- Avoid unnecessary `saveLayer` usage.
- Use release builds for performance testing.
- Test on a mid-range Android device, not only modern iOS hardware.

---

## Animation Direction

The game should feel tactile and responsive without becoming visually noisy.

Recommended interaction feedback:

- **Tap down:** quick cell press state.
- **X mark:** snap or fade in with a short scale change.
- **Correct placement:** token drop/pop, region pulse, housekeeping marks sweep outward.
- **Incorrect placement:** cell shake, red flash, life counter decrement.
- **Level complete:** board success sweep, star count animation, coin count animation.

Use Flutter built-in animations for most board feedback. Use Rive for reusable premium animations such as future companions, reward moments, or a highly polished token animation.

---

## Performance Targets

**Minimum:**

- Stable 60 fps during board interaction and screen transitions.
- Touch feedback feels immediate.
- No visible hitch when placing tokens or applying housekeeping marks.

**Aspirational:**

- Smooth behavior on 120 Hz devices where practical.
- Board animations remain responsive on mid-range Android hardware.
- Cold start and level load feel lightweight.

**Technical guardrails:**

- Use Flutter DevTools performance profiling.
- Profile in release or profile mode, not debug mode.
- Move expensive generation/analysis work to CLI tools or Dart isolates.
- Keep widget rebuild areas small.
- Keep visual effects bounded and cache reusable assets.

---

## Level Generation Strategy

Puzzles are **pre-generated** using offline Dart CLI tooling and bundled with the app as verified JSON level packs. The first phase target is at least 500 puzzles for an 8 x 8 grid.

The generator is a **generate-and-test pipeline with structured retry**. Candidates are produced cheaply, then filtered through progressively stricter validators. Most rejections occur at the uniqueness and logic-solvability stages.

```text
1. Generate Placement    →  Valid token arrangement
2. Grow Regions          →  Partition into 8 connected regions
3. Verify Uniqueness     →  Backtracking solver, early exit on 2nd solution
4. Verify Logic-Solve    →  Deterministic deduction simulator
5. Grade Difficulty      →  Classify Easy / Medium / Hard / Master
6. Canonicalize + Dedup  →  Reject symmetric duplicates
7. Enforce Band Quota    →  Target a controlled difficulty distribution
8. Export + Order        →  Curate play order, write versioned JSON
```

The pipeline guarantees every shipped puzzle has a unique solution, is reachable through pure logic, carries a stable difficulty grade, and is distinct from every other puzzle in the pack. The 500-puzzle pack is ordered to ramp difficulty and introduce deduction families progressively.

**The authoritative specification for the generator — including the full grader deduction set, retry budgets, canonicalization scheme, band quotas, and ordering strategy — is [docs/level-generation.md](docs/level-generation.md).**

The player-facing deduction vocabulary is the 4 families in [Official Deduction Set](#official-deduction-set). The grader uses one additional family internally — higher-order confinement — to validate Master-band puzzles. This extra family is not taught explicitly; Master-tier players are expected to discover it through play.

---

## Testing Strategy

The puzzle core should have heavy unit test coverage before UI work gets deep.

**Core tests:**

- Row, column, region, and no-touch validation.
- Unique-solution detection.
- Hidden-solution double-tap validation.
- Housekeeping mark generation (both player and auto marks).
- Each deduction family — the four player-facing families and the grader-only higher-order confinement extension.
- Full logic-solve paths for known puzzle fixtures.
- Difficulty grading for known easy/medium/hard/master examples.

**App tests:**

- Level load from bundled JSON.
- Tap and double-tap behavior.
- Life loss and failure.
- Restart resets lives to 3.
- Star and coin awards on successful completion.
- Cumulative star tracking.
- Undo behavior.
- Linear level progression gating.
- Progress persistence.

**Visual/performance tests:**

- Board layout at common phone sizes.
- Accessibility outline mode.
- Animation smoke tests.
- Auto X mark vs player X mark visual distinction.
- Release-build performance on at least one physical Android and one physical iOS device before launch.

---

## Accessibility

V1 should include:

- Colorblind-friendly region outlines.
- Clear region boundaries independent of color.
- Haptic toggle.
- Sound toggle.
- Reduced motion option if animation intensity grows.
- Large, readable touch targets.
- No reliance on color alone for mistake feedback.

---

## Development Priorities

Recommended first milestones:

1. Build `puzzle_core` with board models, validator, and solution checker.
2. Add fixtures for small known-valid 8 x 8 puzzles.
3. Implement the four player-facing deduction families and the grader-only higher-order confinement extension for validation and difficulty grading.
4. Build a CLI that verifies uniqueness and logic-solvability.
5. Scaffold the Flutter app.
6. Render a playable board with tap, X marks, double-tap, lives, and restart.
7. Add local progress, stars (cumulative), and coins.
8. Add animations and sound polish.
9. Generate and verify the first level pack (500 puzzles).
10. Wire linear level progression.

---

## Design Principle

The core promise is simple: every puzzle has one unique solution, every solution is reachable through logic, and every interaction should feel immediate, clear, and satisfying on a phone.
