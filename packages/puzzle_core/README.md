# puzzle_core

Pure Dart engine for Skully Bones Treasure Adventure — a 1-star Star Battle puzzle game.

This package owns:

- Core value types (`Cell`, `Region`, `PuzzleDefinition`, `PuzzleSolution`, ...).
- `PlacementValidator` and `SolutionValidator` — the two validation surfaces defined in [docs/data-model.md](../../docs/data-model.md).
- Solver-layer abstractions plus concrete implementations: `StandardCandidateGrid`, the five official deduction-family functions, `StandardLogicSolver`, `StandardUniquenessSolver`, and `DifficultyGrader`.

No Flutter imports. No platform-specific dependencies.

Full Easy / Medium / Hard fixture JSON files are still pending the generator
bootstrap; until then, the solver contract is covered by synthetic deduction
scenarios and focused solver tests.

See the root [README.md](../../README.md) for the game spec and [docs/data-model.md](../../docs/data-model.md) for the authoritative type reference.
