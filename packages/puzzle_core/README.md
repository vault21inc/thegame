# puzzle_core

Pure Dart engine for Skully Bones Treasure Adventure — a 1-star Star Battle puzzle game.

This package owns:

- Core value types (`Cell`, `Region`, `PuzzleDefinition`, `PuzzleSolution`, ...).
- `PlacementValidator` and `SolutionValidator` — the two validation surfaces defined in [docs/data-model.md](../../docs/data-model.md).
- Solver-layer abstractions (`CandidateGrid`, `LogicSolver`, `UniquenessSolver`). Concrete solver implementations and the deduction families land in milestone 3.

No Flutter imports. No platform-specific dependencies.

See the root [README.md](../../README.md) for the game spec and [docs/data-model.md](../../docs/data-model.md) for the authoritative type reference.
