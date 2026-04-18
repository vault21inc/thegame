# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Testing Philosophy

When puzzle tests fail, **never modify puzzle_core logic just to make a test pass**. Always:
1. Confirm whether the test expectation matches the intended behavior before changing anything.
2. If the puzzle logic is correct, fix the test.
3. If the puzzle logic is wrong, fix the logic.
4. If the expected behavior is ambiguous, flag it for user review before making changes.

The golden placement test (`[0, 2, 4, 6, 1, 3, 5, 7]` must be **valid**) is a non-negotiable invariant — never change behavior to make it fail.

## General Development

When running in "bypass permissions" or "auto accept edits" mode, stop at reasonable intervals for user review and potential commit events.

For complex work expected to span multiple sessions or phases, create an implementation plan before starting.

### DO NOT
- Commit or push changes to git
- Attempt to run the Flutter app yourself
  - If you need the app running, notify the user what needs to be running and why
- Add new deduction families beyond the five defined below — flag the need and wait for user approval
- Implement N-Queens diagonal attack rules (see Critical Rules)

## Project Overview

**Skully Bones Treasure Adventure** is a mobile logic puzzle game based on 1-star Star Battle rules, built with Flutter + Dart. The project is in pre-implementation design phase; no application code exists yet.

## Planned Repository Layout

```
apps/mobile/          # Flutter app — UI, screens, state via Riverpod, persistence via Drift/SQLite
packages/puzzle_core/ # Pure Dart package — zero Flutter dependencies
tools/level_generator/# Dart CLI — generates, validates, and exports the 500+ puzzle pack
assets/levels/        # Pre-generated JSON puzzle packs
assets/animations/    # Rive (interactive) and Lottie (one-shot) assets
docs/                 # Authoritative specifications
```

`puzzle_core` must remain Flutter-free so it can be used from the app, CLI tools, tests, and future editors.

## Development Commands

Once Dart/Flutter packages are scaffolded, expected commands follow standard Flutter patterns:

```bash
# Build
flutter build apk --release
flutter build ios --release

# Tests (run puzzle_core tests before any UI work)
flutter test                          # all tests
flutter test packages/puzzle_core/    # puzzle engine only
dart test tools/level_generator/      # generator CLI tests

# Lint and analysis
flutter analyze
dart fix --apply

# Generate puzzle pack
dart run tools/level_generator/

# Format
dart format .
```

## Architecture

### Package Responsibilities

- **`puzzle_core`** — models (`Grid`, `Region`, `Cell`, `Token`), validator, logic solver (five deductions only), uniqueness checker, difficulty grader. No Flutter imports.
- **`apps/mobile`** — Flutter app consuming `puzzle_core`. Board rendered via `CustomPainter`. State managed via Riverpod. Progress persisted via Drift/SQLite.
- **`tools/level_generator`** — Dart CLI following the 8-stage pipeline in `docs/level-generation.md`. Outputs JSON puzzle packs to `assets/levels/`.

### Key Design Patterns

1. **Solver is deduction-only**: the solver must never backtrack/guess. If none of the five deduction families can make progress, the puzzle is invalid.
2. **Validator is pure**: `validate(grid, placements) → ValidationResult` with no side effects.
3. **Grader uses solver trace**: difficulty is derived from which deduction families the solver invoked, not heuristics.

## Critical Implementation Rules

### Non-N-Queens Constraint

**CRITICAL**: This game uses **adjacency-only conflicts**, not full chess-diagonal attack rules.

- Forbidden: any two tokens with Chebyshev distance < 2 (i.e., sharing a cell edge or corner).
- Allowed: tokens on the same row/column/diagonal as long as they are not adjacent.
- **Golden placement test**: column indices `[0, 2, 4, 6, 1, 3, 5, 7]` must be **valid**. Tokens at `(row 0, col 0)` and `(row 7, col 7)` share a long diagonal but are not adjacent — both placements are legal.
- **How to verify**: run the golden placement test first. If it returns invalid, the conflict check is wrong.

### The Five Deduction Families

These are the only legal deductions. The solver, hint system, and difficulty grader all use exactly these — no others.

| # | Name | Description |
|---|------|-------------|
| 1 | **Giveaway Cell** | A row, column, or region has exactly one candidate remaining. |
| 2 | **Confinement** | All candidates of one axis are confined to an intersection with another axis; eliminate candidates outside that intersection. |
| 3 | **Touch-All Elimination** | A candidate cell outside a region is adjacent (Chebyshev) to every candidate inside the region; eliminate it. |
| 4 | **Contradiction / Blocking** | Placing a token at a cell would leave another row, column, or region with zero candidates; eliminate that cell. |
| 5 | **Higher-Order Confinement** | K regions occupy exactly K rows or columns; eliminate candidates in those rows/columns belonging to other regions. **Grader-only** — used for Master-tier validation; not exposed to players. |

Do not invent new deduction types. If a puzzle cannot be solved with these five families, it is invalid for this game.

### Terminology

- The placed object is a **token** in all code and docs (themed visually as a queen).
- Never use `piece`, `star`, or `queen` as identifiers in code.
- Player-placed elimination marks: **X mark** (removable). Auto housekeeping marks: **auto mark** (non-removable).

## Implementation Planning

Create an implementation plan before starting:
- Any feature expected to span more than one session
- Significant architectural decisions (e.g., solver algorithm, generator pipeline design)
- New external integrations or asset pipeline changes
- Anything touching the grading or deduction system

Skip planning for:
- Simple bug fixes
- Documentation-only edits
- Configuration-only changes

## Documentation Standards (Dartdoc)

Every new class, function, and public method must include a Dartdoc comment. No exceptions.

```dart
/// Brief one-line summary.
///
/// - WHY this exists (domain context)
/// - HOW it fits into the architecture
/// - Key behavior or side effects
/// - Important constraints or invariants
///
/// [paramName] Description including valid values or ranges.
/// Returns description including null semantics.
/// Throws [ExceptionType] when and why.
/// See also: [RelatedClass].
```

Anti-patterns to avoid:
- **Parrot docs**: `/// Gets the name. String getName()` — explain *what* name, *whose*, *why*.
- **Stale docs**: If you change behavior, update the Dartdoc in the same change. Period.

## Test Maintenance

> **THIS IS MANDATORY.** Any change to `puzzle_core` behavior MUST include corresponding
> test updates **in the same session**, before moving on to the next task.

### When to update tests

The following changes require updating both unit tests and, once they exist, integration/golden tests:

- Changing validator logic or conflict detection
- Adding, removing, or modifying a deduction family
- Changing the grading thresholds or difficulty band criteria
- Changing solver behavior (deduction order, termination conditions)
- Changing any public API in `puzzle_core` (model field names, method signatures, return types)
- Changing generator pipeline stages

### Process

1. Make the code change.
2. Run `flutter test packages/puzzle_core/` to identify broken unit tests.
3. For each failure, apply the Testing Philosophy (confirm intent before changing logic).
4. Verify **all** tests pass before considering the task complete.

**Do not defer this.** Test drift creates false confidence, especially for a deterministic puzzle engine.

## Difficulty Bands

| Band | % of 500 levels | Required deductions |
|------|-----------------|---------------------|
| Easy | 40% | Giveaway Cell + simple Confinement only |
| Medium | 35% | Touch-All Elimination or multi-step Confinement |
| Hard | 20% | Contradiction / Blocking |
| Master | 5% | Higher-Order Confinement |

## V1 Scope Constraints

- Grid: fixed 8×8, 8 regions, 8 tokens. No other sizes in V1.
- Content: ≥500 pre-generated, verified, unique-solution puzzles.
- Pay-once, offline-only. No ads, no IAP, no user accounts, no network calls.
- Player actions: single-tap (X mark toggle), double-tap (place token), undo, restart.
- 3 lives per puzzle; failure on third error.
- Colorblind-safe: region distinction must work via outline shape, not color alone.
- Performance target: 60 fps on mid-range Android. Profile in release mode.

## Authoritative Specifications

- **[README.md](README.md)** — complete game spec: rules, V1 scope, UX, progression, monetization, accessibility.
- **[AGENTS.md](AGENTS.md)** — architecture quick-reference and agent-mode guidelines.
- **[docs/level-generation.md](docs/level-generation.md)** — 8-stage pipeline for puzzle generation, validation, and export. Follow this exactly when implementing the generator.
- **[docs/archive/](docs/archive/)** — historical brainstorming only; not canonical. If archived docs contradict README, **README wins**.

## Troubleshooting

- **Golden placement test failing**: Conflict check is implementing N-Queens rules. Fix adjacency check to use Chebyshev distance < 2 only.
- **Solver returns no solution on valid puzzle**: Check that all five deduction families are implemented and firing in order.
- **Grading mismatch**: Confirm solver records which deduction family each elimination used; grader reads that trace.
- **Generator yield too low**: Consult stage-by-stage yield expectations in `docs/level-generation.md`.
- **Flutter analyze errors in puzzle_core**: `puzzle_core` must have zero Flutter imports — check `pubspec.yaml` dependencies.
