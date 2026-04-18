# Project Logic Grid

`Project Logic Grid` is the current working title for a mobile-first logic puzzle game based on 1-star Star Battle rules. The name is intentionally generic and should remain easy to replace later. The placed object should be called a `piece` or `token` in code and design documentation, even if the current visual theme presents it as a queen.

The first development phase should focus on a polished local/offline mobile experience: a responsive puzzle board, smooth touch feedback, verified logic-only puzzles, local progress, stars, coins, and a minimum first content set of 500 levels.

## Current Status

This repository currently contains planning and design documents. No app scaffold has been created yet.

Primary documents:

- [TheGame.md](TheGame.md): Canonical core game concept and v1 scope.
- [Star Battle.md](Star%20Battle.md): Rules reference for the intended 1-star Star Battle model.
- [The classic N-Queens puzzle.md](The%20classic%20N-Queens%20puzzle.md): Theme and historical reference only.
- [Reward System.md](Reward%20System.md): V1 stars/coins reward model and later-phase reward ideas.
- [reward and progression system.md](reward%20and%20progression%20system.md): Local progression loop and deferred systems.
- [Questions and Answers.md](Questions%20and%20Answers.md): Raw decision notes that informed the current spec.

## Game Summary

Each puzzle is played on an N x N grid divided into exactly N irregular colored regions. The player places exactly N pieces on the board.

The game is solved when:

- Every row contains exactly one piece.
- Every column contains exactly one piece.
- Every colored region contains exactly one piece.
- No two pieces touch horizontally, vertically, or diagonally.

This is a 1-star Star Battle puzzle. It is not classic N-Queens. Longer shared diagonals are allowed as long as the pieces are not adjacent.

## Canonical Rules

For an N x N puzzle:

- There are exactly N colored regions.
- Every region contains at least one cell.
- A completed solution contains exactly N pieces.
- Each row has one piece.
- Each column has one piece.
- Each region has one piece.
- Any two pieces must have Chebyshev distance >= 2.

The no-touch rule means a placed piece forbids its 3x3 neighborhood, excluding the center cell that contains the piece.

## Solution Requirements

Every puzzle must have exactly one valid solution.

A valid puzzle must pass both checks:

1. **Unique-solution check:** exactly one arrangement satisfies all row, column, region, and no-touch constraints.
2. **Logic-solve check:** the puzzle can be solved through the official deduction set without guessing, trial-and-error, or player backtracking.

Developer tools may use search/backtracking to prove uniqueness. Player-facing hints and difficulty grading should be based on the official deduction set.

## Official Deduction Set

The hint engine, difficulty grader, and logic-solve validator should use these four deduction families plus placement housekeeping.

| # | Deduction | Meaning |
|---|---|---|
| 1 | Giveaway Cell | A row, column, or region has only one remaining candidate, so the piece must go there. |
| 2 | Confinement / Row-Column Forcing | All remaining candidates for a region lie in one row or column, so other cells in that row or column can be eliminated. |
| 3 | Touch-All Elimination | A candidate outside a region touches every remaining candidate inside that region, so the outside candidate can be eliminated. |
| 4 | Contradiction / Blocking Elimination | Placing a piece in a candidate cell would immediately eliminate all candidates in another row, column, or region, so that candidate can be eliminated. |

After a correct placement, housekeeping should mark:

- All other cells in the same row.
- All other cells in the same column.
- All other cells in the same region.
- All adjacent cells in the 3x3 no-touch neighborhood.

## Player Interaction

V1 should use simple mobile-first controls:

- Single tap: toggle an X mark on a cell.
- Double tap: attempt to place a piece.
- Correct double tap: place the piece and perform housekeeping marks.
- Incorrect double tap: lose 1 life.
- Start each puzzle with 3 lives.
- Reaching 0 lives fails the puzzle and requires a restart.

Double-tap validation checks against the hidden unique solution immediately. It does not only check whether the move breaks visible current constraints. A cell can appear possible and still be wrong if it is not the predefined solution cell.

## V1 Product Scope

V1 is local/offline and pay-once.

Included:

- Mobile puzzle board.
- Local level selection.
- At least 500 curated or generated-and-verified puzzles.
- Unique-solution validation tooling.
- Logic-solve validation tooling.
- Three-life attempts.
- X marks.
- Automatic housekeeping marks after correct placements.
- Undo and restart.
- Hint system based on the four official deductions.
- Local stars and coins progression.
- Local settings such as sound, haptics, and accessibility outlines.

Deferred:

- Accounts.
- Cloud sync.
- Global leaderboards.
- Daily missions and streaks.
- Events and tournaments.
- Pets or companions.
- Cosmetic shards/fragments.
- Advanced treasure chest reward presentation.
- Remote level delivery.
- Remote economy tuning.
- Live operations.

The long-term content ambition is 5,000+ verified puzzles. That is not a launch requirement.

## Monetization Model

The game should be pay-once.

Do not design around post-purchase monetization. V1 rewards, hints, coins, and progression should all be compatible with a premium offline game.

## Recommended Tech Stack

The recommended stack is Flutter-first:

| Area | Recommendation | Why |
|---|---|---|
| App framework | Flutter + Dart | Strong mobile UI, custom rendering, animation control, one iOS/Android codebase. |
| Puzzle engine | Pure Dart package | Testable rules, solver, hints, generator support, and no UI coupling. |
| Board rendering | Flutter `CustomPainter` / Canvas | Precise control over cells, regions, marks, highlights, and animated overlays. |
| State management | Riverpod | Testable app state for sessions, progress, settings, and level selection. |
| Local database | Drift / SQLite | Robust local progress, level metadata, packs, stars, coins, and future migrations. |
| Tiny settings | shared_preferences | Good for non-critical settings such as sound, haptics, and accessibility toggles. |
| Interactive animation | Rive | Best fit for stateful, premium-feeling vector animation and future pets/mascots. |
| One-shot animation | Lottie | Useful for canned noninteractive celebrations if an artist pipeline needs it. |
| Game effects | Flame, selectively | Use only if particle effects, sprite systems, or a game loop become useful. |
| Generator tooling | Dart CLI first | Keeps the generator close to the puzzle engine; optimize later only if needed. |

## Why Flutter

Flutter is a strong fit because this is a polished 2D puzzle game with mobile-first interactions, not a physics-heavy 3D game. The board needs custom drawing, fast tap feedback, smooth animation, and clean integration with app screens such as level select, settings, hints, and progression.

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

## Why Not React Native First

React Native can build good mobile apps, but this game depends heavily on custom animated board interactions. React Native performance still requires careful attention to JS thread work, native-driver animation behavior, and library compatibility. Flutter gives more direct control over painting and animation in one rendering model, which is a better starting point for this project.

React Native may be reconsidered only if the team has a much stronger React Native skill base than Flutter and is prepared to invest heavily in custom native animation/performance work.

## Why Not Unity First

Unity is powerful, but it is more engine than this game currently needs. This project is a 2D logic puzzle with a lot of precise UI, local progression, accessibility settings, text, and level management. Flutter should deliver a smaller, cleaner, more app-native implementation.

Unity becomes more attractive only if the game direction shifts toward heavy particles, 3D scenes, complex sprite scenes, or a broader arcade-game presentation.

## Proposed Repository Layout

When implementation begins, use a structure like this:

```text
apps/
  mobile/
    Flutter app shell
    screens, routing, themes, audio, settings, persistence

packages/
  puzzle_core/
    pure Dart rules, models, validator, solver, hints, difficulty grading

tools/
  level_generator/
    Dart CLI for generation, uniqueness checks, logic-solve checks, exports

assets/
  levels/
    bundled verified level packs
  animations/
    Rive or Lottie animation assets
  audio/
    sound effects and music loops
```

The core rule engine should not depend on Flutter. It should be usable from:

- The mobile app.
- Unit tests.
- Generator tools.
- Future level editors.
- Future server or batch-generation tools, if ever needed.

## Core Data Model Direction

Suggested pure-Dart model concepts:

```text
PuzzleDefinition
  id
  size
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
  placedPieces
  xMarks
  livesRemaining
  undoStack
  hintHistory
  startedAt
  completedAt

ProgressRecord
  puzzleId
  bestStars
  bestTime
  completed
  coinsEarned
```

Puzzle files can start as JSON assets for simplicity. If the level catalog grows large, level metadata and progress should move into Drift/SQLite.

## Rendering And Interaction Strategy

The board should be rendered as layered visual concerns:

1. Static board layer: region fills, region boundaries, grid lines.
2. Mark layer: X marks and candidate/hint indicators.
3. Piece layer: placed tokens.
4. Feedback layer: tap ripples, mistake shakes, success pulses, hint focus, completion effects.

Implementation principles:

- Keep board geometry deterministic and cached.
- Repaint only what changed when possible.
- Keep solver/hint computation out of the paint path.
- Avoid expensive opacity/clipping patterns in hot animations.
- Avoid unnecessary `saveLayer` usage.
- Use release builds for performance testing.
- Test on a mid-range Android device, not only modern iOS hardware.

## Animation Direction

The game should feel tactile and responsive without becoming visually noisy.

Recommended interaction feedback:

- Tap down: quick cell press state.
- X mark: snap or fade in with a short scale change.
- Correct placement: piece drop/pop, region pulse, housekeeping marks sweep outward.
- Incorrect placement: cell shake, red flash, life counter decrement.
- Hint: soft focus pulse around the relevant row, column, region, or candidate group.
- Level complete: board success sweep, star count animation, coin count animation.

Use Flutter built-in animations for most board feedback. Use Rive for reusable premium animations such as future companions, reward moments, or a highly polished token animation.

## Performance Targets

Minimum target:

- Stable 60 fps during board interaction and screen transitions.
- Touch feedback feels immediate.
- No visible hitch when placing pieces or applying housekeeping marks.
- Hints do not block the UI thread.

Aspirational target:

- Smooth behavior on 120 Hz devices where practical.
- Board animations remain responsive on mid-range Android hardware.
- Cold start and level load feel lightweight.

Technical guardrails:

- Use Flutter DevTools performance profiling.
- Profile in release or profile mode, not debug mode.
- Move expensive generation/analysis work to CLI tools or Dart isolates.
- Keep widget rebuild areas small.
- Keep visual effects bounded and cache reusable assets.

## Level Generation Strategy

The long-term goal is an intelligent level generator that can produce thousands of verified puzzles. The first phase target is at least 500 puzzles.

Generator pipeline:

1. Generate a candidate N x N region layout.
2. Generate or search for a valid solution.
3. Verify the board has exactly one solution.
4. Run the logic-solve validator using the four official deductions.
5. Compute difficulty metrics.
6. Reject boards that require unsupported reasoning.
7. Export accepted puzzles into versioned level packs.

Difficulty metadata should include:

- Board size.
- Number of deduction steps.
- Maximum chain depth.
- Deduction families required.
- Candidate density.
- First-forced-placement depth.
- Estimated difficulty band.

## Testing Strategy

The puzzle core should have heavy unit test coverage before UI work gets deep.

Core tests:

- Row, column, region, and no-touch validation.
- Unique-solution detection.
- Hidden-solution double-tap validation.
- Housekeeping mark generation.
- Each official deduction family.
- Full logic-solve paths for known puzzle fixtures.
- Difficulty grading for known easy/medium/hard/master examples.

App tests:

- Level load.
- Tap and double-tap behavior.
- Life loss and failure.
- Star and coin awards.
- Undo and restart.
- Hint display.
- Progress persistence.

Visual/performance tests:

- Board layout at common phone sizes.
- Accessibility outline mode.
- Animation smoke tests.
- Release-build performance on at least one physical Android and one physical iOS device before launch.

## Accessibility

V1 should include:

- Colorblind-friendly region outlines.
- Clear region boundaries independent of color.
- Haptic toggle.
- Sound toggle.
- Reduced motion option if animation intensity grows.
- Large, readable touch targets.
- No reliance on color alone for hint or mistake feedback.

## Open Decisions

These decisions should be resolved before implementation reaches scoring and level generation:

- Whether hints reduce stars, score, coins, or only solve time.
- Whether coins can buy hints in v1 or only unlock cosmetic/local progression.
- Whether timed levels exist in v1 or remain deferred.
- Which board sizes are included in the first 500 levels.
- Whether the first 500 levels are generated, hand-curated, or generated then curated.
- Exact level pack unlock rules.
- Exact theme and final product name.

## Development Priorities

Recommended first milestones:

1. Build `puzzle_core` with board models, validator, and solution checker.
2. Add fixtures for small known-valid puzzles.
3. Implement the four deduction families.
4. Build a CLI that verifies uniqueness and logic-solvability.
5. Scaffold the Flutter app.
6. Render a playable board with tap, X marks, double-tap, lives, and restart.
7. Add hints wired to the deduction engine.
8. Add local progress, stars, and coins.
9. Add animations and sound polish.
10. Generate and verify the first level pack.

## Design Principle

The core promise is simple: every puzzle has one unique solution, every solution is reachable through logic, and every interaction should feel immediate, clear, and satisfying on a phone.
