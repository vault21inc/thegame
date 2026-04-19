# Project Status

Living document. Updated after each meaningful completion. For the authoritative spec, see the root [README.md](../README.md). For the full milestone list and acceptance criteria, see [§Development Priorities](../README.md#development-priorities).

---

## Current phase

**Milestone 4 (part A) complete — `tools/level_generator` is scaffolded with a tested CLI contract and deterministic empty-pack export. Non-empty puzzle generation is the next generator slice.**

What runs today:

- `dart pub get` resolves the workspace cleanly.
- `dart analyze --fatal-infos --fatal-warnings` reports **no issues**.
- `dart test packages/puzzle_core` runs **132 tests, all passing**.
- `dart test tools/level_generator` runs **10 tests, all passing**.
- `dart run level_generator --help` prints the generator CLI usage.
- `dart run level_generator -- --seed <n> --count 0 --output <path> --max-candidates 0` writes a deterministic empty pack shell.
- `packages/puzzle_core` now includes concrete implementations for `StandardCandidateGrid`, the five pure deduction-family functions, `StandardLogicSolver`, `StandardUniquenessSolver`, and `DifficultyGrader`.
- All 17 synthetic deduction scenarios now run against the real deduction engine, including ordering checks.

What does not exist yet:

- Non-empty generator stages: placement generation, region growth, uniqueness/logic filtering integration, canonicalization/dedup, quota enforcement, and curated ordering.
- The `apps/mobile` Flutter app. Milestone 5 scaffolds it.
- The bundled 500-puzzle level pack. Milestone 9 produces it.
- The three full-puzzle fixtures and trace companions from Milestone 2 part B. These require the generator bootstrap so the fixtures can be honestly selected from verified Easy / Medium / Hard puzzles.

---

## Milestone status

| # | Milestone | Status | Notes |
|---|---|---|---|
| 1 | Build `puzzle_core` with board models, validator, and solution checker | **Done** | All core types, validators, and abstract solver interfaces implemented and tested. Strict-casts, strict-inference, strict-raw-types compliant. |
| 2 | Add fixtures for small known-valid 8 x 8 puzzles | **Part A done; part B blocked** | Part A: 17 synthetic deduction scenarios authored, structurally verified by integrity tests. Part B (three full-puzzle fixtures) requires milestones 3 and 4 to produce. |
| 3 | Implement the deduction families, logic solver, uniqueness solver, and difficulty grader | **Part A done; fixture closeout blocked** | Concrete solver/grader code is implemented and synthetic scenarios pass. End-to-end fixture assertions wait for M4 to bootstrap verified full-puzzle fixtures. |
| 4 | Build a CLI that generates, verifies, and exports level packs | **Part A done; generation pipeline pending** | `tools/level_generator` is a workspace package with CLI parsing, deterministic config/metadata, and empty-pack export. Non-empty Stage 1–8 generation is next. |
| 5 | Scaffold the Flutter app | **Not started** | Can run in parallel with M3/M4 in principle; user is handling this personally. Docs at [docs/repo-scaffolding.md](repo-scaffolding.md). |
| 6 | Render a playable board with tap, X marks, double-tap, lives, and restart | **Not started; blocked by M5** | |
| 7 | Add local progress, stars (cumulative), and coins | **Not started; blocked by M5, M6** | |
| 8 | Add animations and sound polish | **Not started; blocked by M6** | |
| 9 | Generate and verify the first level pack (500 puzzles) | **Not started; blocked by M4** | |
| 10 | Wire linear level progression | **Not started; blocked by M6, M7, M9** | |

---

## Known issues / calibration TODOs

- **Difficulty thresholds are heuristic:** `DifficultyGrader` implements the current Stage 5 rules, but Easy / Medium / Hard / Master thresholds should be calibrated once the first generated fixture set exists.
- **Visual design for auto X marks (skull-and-crossbones) vs player X marks (charcoal-sketch X):** the concept is pinned in [README.md §X Marks](../README.md#x-marks), but there is no concrete asset spec yet. Assets in [assets/](../assets/) may serve as references during M6.
- **Workspace membership:** `packages/puzzle_core` and `tools/level_generator` are workspace members. `apps/mobile` joins the root `pubspec.yaml` `workspace:` list when it is scaffolded (M5).

---

## Recent changes

Newest first. Date format: YYYY-MM-DD.

- **2026-04-19** — Milestone 4 part A complete. Scaffolded `tools/level_generator` as a Dart workspace package with the required CLI flags (`--seed`, `--count`, `--quota`, `--output`, `--over-fill`, `--max-candidates`), strict config validation, default quota derivation, deterministic metadata JSON, and an honest empty-pack export path for scaffold smoke runs. Non-empty generation returns a pipeline-incomplete exit code until Stage 1–8 candidate generation lands. `dart analyze --fatal-infos --fatal-warnings` is clean; `dart test tools/level_generator` passes 10 tests; `dart test packages/puzzle_core` still passes 132 tests.
- **2026-04-19** — Milestone 3 part A complete. Implemented concrete candidate-grid state, pure deduction functions for all five official families, deterministic logic solving with placement housekeeping traces, backtracking uniqueness counting with early exit at 2, and heuristic difficulty grading. Added runner tests for all 17 synthetic deduction scenarios, solver-loop coverage for stalled and non-giveaway states, grader threshold tests, and calibrated the previously-authored S5/O-family expectations against the real engine. `dart analyze --fatal-infos --fatal-warnings` is clean; `dart test packages/puzzle_core` passes 132 tests.
- **2026-04-19** — Milestone 2 part A complete. Authored 17 synthetic deduction scenarios (8 required, 5 negative, 4 ordering) under `packages/puzzle_core/test/deduction_scenarios/` plus a structural-integrity test suite that runs without the deduction engine. 23 new tests pass (total now 97).
- **2026-04-19** — Milestone 1 verified green. Fixed 95 analyze issues surfaced once Dart was installed: dropped retired `avoid_returning_null_for_future` lint, removed unused `dart:collection` import, consolidated barrel exports, added `const` to static `FormatException`s, added trailing commas, and converted `const <Cell>{...}` literals to `<Cell>{const Cell(...)}` (Cell overrides `==`, so it cannot be a const-set element). 74 tests pass.
- **2026-04-18** — Milestone 1 code-complete (pending verification). Wrote the entire `packages/puzzle_core` package: models (Cell, Region, Difficulty, DeductionFamily, DifficultyMetadata, PuzzleSolution, PuzzleDefinition), validators (PlacementValidator, SolutionValidator + violations + result), solver-layer abstractions (CandidateGrid, CellState, TraceEntry, SolveResult, LogicSolver, UniquenessSolver), barrel file, and full test coverage. Also added a dedicated golden-placement test (σ = `[0, 2, 4, 6, 1, 3, 5, 7]`) at [non_n_queens_test.dart](../packages/puzzle_core/test/validation/non_n_queens_test.dart) to lock in the non-N-Queens guardrail.
- **2026-04-18** — Planning documents filled in. Created [docs/data-model.md](data-model.md) (Dart type sketches with invariants), [docs/test-fixtures.md](test-fixtures.md) (synthetic scenario + full-fixture spec), [docs/repo-scaffolding.md](repo-scaffolding.md) (workspace + pubspec spec). README §Development Priorities got per-milestone "Done when" acceptance criteria. Open Decisions section resolved and removed.
- **2026-04-18** — Pipeline spec broken out into [docs/level-generation.md](level-generation.md) (retry topology, canonicalization + dedup, band quotas, curated ordering, reproducibility, expanded 5-family grader deduction set with Family 2 rephrased as bidirectional Confinement). README's Level Generation Strategy section slimmed to an orientation summary + link.

---

## How to update this file

After finishing a milestone or meaningful partial completion:

1. Update the **Current phase** paragraph.
2. Flip the **Milestone status** row (Not started → In progress → Done / Blocked).
3. Add a **Recent changes** entry at the top with the date and what changed.
4. Add any new calibration TODOs or remove resolved ones.

Keep entries short. If you catch yourself writing paragraphs, consider whether it belongs in a design doc under `docs/` instead.
