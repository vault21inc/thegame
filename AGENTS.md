# Project Guidelines — Skully Bones Treasure Adventure

## What This Is

A mobile-first logic puzzle game based on **1-star Star Battle** rules, built with **Flutter + Dart**. Currently in pre-development (design docs only, no code yet).

## Core Development Principles

- **KISS** — Keep It Simple. Prefer the straightforward solution over the clever one.
- **YAGNI** — Don't build it until you need it. No speculative features or abstractions.
- **DRY** — Don't Repeat Yourself. Extract shared logic, but not at the cost of clarity.
- **Readability first** — Code is read far more than it is written. Favor clear naming, small functions, and obvious control flow over terse or "smart" code.
- **Single Responsibility** — Each class, function, and module should do one thing well.
- **Composition over inheritance** — Prefer composing small, focused objects over deep class hierarchies.
- **Fail fast** — Surface errors early at system boundaries; don't silently swallow or defer them.
- **Minimal surface area** — Keep public APIs small. Expose only what consumers need.

## DO NOT

- Commit or push changes to git.
- Run the Flutter app yourself — notify the user of what needs to be running and why.
- Add new deduction families beyond the five defined below — flag the need and wait for approval.
- Implement N-Queens diagonal attack rules (see Critical Rules).
- Modify puzzle_core logic just to make a failing test pass — confirm intent first.

## Testing Philosophy

When tests fail:
1. Confirm whether the test expectation matches the intended behavior.
2. If the logic is correct, fix the test.
3. If the logic is wrong, fix the logic.
4. If ambiguous, flag for user review before changing anything.

Test updates are **mandatory in the same session** as any behavior change. Do not defer.

## Critical Domain Rules

- The placed object is a **token** in all code and docs (themed visually as a queen). Never use `piece`, `star`, or `queen` as identifiers.
- This is **NOT N-Queens**. Only adjacent-cell (Chebyshev distance < 2) conflicts are forbidden. Longer shared diagonals are legal. Never implement full chess-diagonal attack rules.
- **Golden test**: placement `[0, 2, 4, 6, 1, 3, 5, 7]` must be **valid** — tokens at `(0,0)` and `(7,7)` share a diagonal but are not adjacent. If this test fails, the conflict check is wrong.
- Every puzzle must have **exactly one** valid solution and be solvable through pure logic (no guessing/backtracking).

## Architecture (Planned)

```
apps/mobile/          — Flutter app (screens, routing, themes, state via Riverpod, persistence via Drift)
packages/puzzle_core/ — Pure Dart: rules, models, validator, solver, grader. Zero Flutter dependencies.
tools/level_generator/— Dart CLI: 8-stage generation pipeline, uniqueness check, export to JSON
assets/levels/        — Bundled verified JSON level packs
assets/animations/    — Rive (interactive) / Lottie (one-shot) assets
docs/                 — Authoritative specifications
```

`puzzle_core` must have **zero Flutter dependencies** — usable from app, tests, CLI tools, and future editors.

## Tech Stack

- **Framework:** Flutter + Dart
- **State management:** Riverpod
- **Local DB:** Drift / SQLite
- **Settings:** shared_preferences
- **Animation:** Rive (interactive), Lottie (one-shot)
- **Board rendering:** Flutter `CustomPainter` / Canvas

## The Five Deduction Families

The solver, hint system, and grader use **only** these families. No others.

| # | Name | Who sees it |
|---|------|-------------|
| 1 | **Giveaway Cell** — one candidate left in a row/column/region | Player |
| 2 | **Confinement** — candidates of one axis confined to another; eliminate outside intersection | Player |
| 3 | **Touch-All Elimination** — outside candidate adjacent to every candidate inside a region | Player |
| 4 | **Contradiction / Blocking** — placing a token would empty another row/column/region | Player |
| 5 | **Higher-Order Confinement** — K regions in K rows/columns; eliminate other-region candidates | Grader only (Master band) |

## Documentation Standards

Every new class, function, and public method must have a Dartdoc comment covering WHY it exists, HOW it fits the architecture, key constraints, and param/return semantics. No parrot docs (`/// Gets the name.`). If you change behavior, update the doc in the same change.

## Implementation Planning

Create a plan before starting:
- Any feature spanning more than one session
- Solver, grader, or generator architecture decisions
- Any change to the deduction system

Skip for simple bug fixes, doc edits, and config-only changes.

## V1 Constraints

- **Grid:** fixed 8×8, 8 regions, 8 tokens
- **Content:** ≥500 pre-generated verified puzzles
- **Monetization:** pay-once, no ads, no IAP
- **Offline-only:** no accounts, no cloud sync
- **Difficulty bands:** Easy (40%) / Medium (35%) / Hard (20%) / Master (5%)
- **Performance target:** 60 fps on mid-range Android; profile in release mode

## Conventions

- Player marks: **X mark** (player-placed, removable) vs **auto mark** (housekeeping, non-removable).
- Visuals must be distinguishable by shape, not color alone (colorblind accessibility).

## Key Specs

| Topic | Document |
|---|---|
| Game rules, interactions, progression, V1 scope | [README.md](README.md) |
| Level generator pipeline (8-stage generate-and-test) | [docs/level-generation.md](docs/level-generation.md) |
| Archived brainstorming (historical only) | [docs/archive/](docs/archive/) |

If archived docs contradict the root README, **README wins**.
