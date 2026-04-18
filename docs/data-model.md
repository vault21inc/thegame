# Core Data Model

This document is the authoritative type specification for the `puzzle_core` package. It extends the prose model direction in the root [README.md](../README.md#core-data-model-direction) with concrete Dart class/enum/interface sketches, invariants, and construction contracts.

The types below are organized in three layers:

1. **Core types** — pure, immutable value types used everywhere. No Flutter imports.
2. **Runtime types** — mutable session state for an in-progress puzzle. No Flutter imports.
3. **Persistence types** — plain Dart data shapes stored by the Drift layer. No Flutter imports.

All three layers live in `packages/puzzle_core`. The Flutter app and the generator CLI both consume them.

---

## General conventions

- All types are **null-safe** and assume sound null safety.
- Immutable value types override `==` and `hashCode` via field-by-field equality.
- Constructors that can receive invalid input declare `assert(...)` checks for the invariants listed below.
- Collection fields in immutable types are always **unmodifiable views** (e.g., `List.unmodifiable`, `UnmodifiableSetView`), not the raw mutable collection.
- IDs are strings formatted as `level_0001`, `region_3`, etc. — prefix + zero-padded integer.

---

## 1. Core types

### `Cell`

Immutable coordinate value.

```dart
final class Cell {
  final int row;
  final int col;

  const Cell(this.row, this.col);

  /// Chebyshev distance to another cell.
  int chebyshevDistanceTo(Cell other);

  /// True if this cell and [other] are in each other's 3x3 no-touch neighborhood.
  bool touches(Cell other);
}
```

**Invariants**
- `0 <= row` and `0 <= col`. Upper bound is enforced by the containing `PuzzleDefinition`, not by `Cell` itself.

### `Region`

Immutable region definition — an ID plus a set of cells.

```dart
final class Region {
  final int id;
  final Set<Cell> cells; // unmodifiable view

  Region({required this.id, required Set<Cell> cells});

  bool containsCell(Cell cell);

  /// True if [cells] forms a 4-connected orthogonal region.
  bool get isContiguous;
}
```

**Invariants**
- `id >= 0`.
- `cells.isNotEmpty`.
- All cells are within the containing puzzle's size (checked by `PuzzleDefinition`).
- `isContiguous` is `true`.
- Two regions in the same puzzle are **disjoint** (checked by `PuzzleDefinition`).

### `Difficulty`

```dart
enum Difficulty { easy, medium, hard, master }
```

### `DeductionFamily`

Five families — four player-facing, one grader-only (see [docs/level-generation.md](level-generation.md#deduction-set)).

```dart
enum DeductionFamily {
  giveawayCell,              // Family 1 — player-facing
  confinement,               // Family 2 — player-facing, bidirectional
  touchAllElimination,       // Family 3 — player-facing
  contradictionElimination,  // Family 4 — player-facing
  higherOrderConfinement,    // Family 5 — grader-only
}
```

### `DifficultyMetadata`

```dart
final class DifficultyMetadata {
  final Difficulty band;
  final int steps;               // total deduction steps
  final int maxChainDepth;       // longest elimination chain between placements
  final Set<DeductionFamily> families;
  final int firstPlacementDepth;
  final double minCandidateDensity; // min (candidates / open cells) along the trace

  const DifficultyMetadata({...});
}
```

**Invariants**
- All numeric fields are non-negative.
- `families.isNotEmpty` and contains at least `DeductionFamily.giveawayCell` (housekeeping alone without giveaway implies an unsolved puzzle, which shouldn't reach grading).

### `PuzzleSolution`

```dart
final class PuzzleSolution {
  /// Tokens ordered by row index ascending. Length equals puzzle size.
  final List<Cell> tokens;

  const PuzzleSolution(this.tokens);

  Cell tokenForRow(int row);
}
```

**Invariants**
- `tokens.length == puzzle.size`.
- `tokens[i].row == i` for all `i`.
- Columns form a permutation of `0..size-1`.
- No two tokens touch (Chebyshev >= 2).
- Every region contains exactly one token.

### `PuzzleDefinition`

The top-level puzzle type. Immutable. Loaded from JSON; produced by the generator.

```dart
final class PuzzleDefinition {
  final String id;                 // "level_0001"
  final int schemaVersion;         // current: 1
  final int size;                  // 8 for V1
  final List<Region> regions;      // length == size
  final PuzzleSolution solution;
  final DifficultyMetadata difficulty;

  const PuzzleDefinition({...});

  Region regionContaining(Cell cell);
  bool cellIsInGrid(Cell cell);

  factory PuzzleDefinition.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

**Invariants**
- `size >= 4` (below 4 the rules are degenerate).
- `regions.length == size`.
- Every region's cells are within `0..size-1` on both axes.
- Regions are pairwise disjoint and their union is the full `size x size` grid.
- `solution` satisfies all canonical rules against `regions`.

### Validators

Two separate validators — the distinction matters for the double-tap behavior spec.

```dart
/// Checks whether a proposed set of placements satisfies
/// row / column / region / no-touch constraints against a puzzle's regions.
/// Does NOT compare against the puzzle's stored solution.
abstract class PlacementValidator {
  PlacementValidationResult validate(
    PuzzleDefinition puzzle,
    Iterable<Cell> proposedTokens,
  );
}

/// Checks whether a single proposed placement matches the puzzle's stored solution
/// for the given row. This is the hidden-solution check used by double-tap.
abstract class SolutionValidator {
  bool isSolutionCell(PuzzleDefinition puzzle, Cell cell);
}
```

```dart
final class PlacementValidationResult {
  final bool isValid;
  final List<PlacementViolation> violations;
  const PlacementValidationResult({...});
}

sealed class PlacementViolation {}
final class DuplicateRow extends PlacementViolation { final int row; }
final class DuplicateColumn extends PlacementViolation { final int col; }
final class DuplicateRegion extends PlacementViolation { final int regionId; }
final class AdjacentTokens extends PlacementViolation { final Cell a; final Cell b; }
```

### Solver types

Used by the logic-solvability verifier (Stage 4) and the uniqueness verifier (Stage 3).

```dart
/// Mutable candidate grid — each cell is either a candidate, eliminated, or placed.
abstract class CandidateGrid {
  int get size;
  CellState stateAt(Cell cell);
  Set<Cell> candidatesInRow(int row);
  Set<Cell> candidatesInColumn(int col);
  Set<Cell> candidatesInRegion(int regionId);

  void eliminate(Cell cell);
  void place(Cell cell); // triggers housekeeping via the deduction engine
}

enum CellState { candidate, eliminated, placed }
```

```dart
final class TraceEntry {
  final DeductionFamily family;
  final List<Cell> eliminated;  // empty if a placement step
  final Cell? placed;           // non-null if a placement step
  final int candidatesBefore;
  final int candidatesAfter;
  final int chainDepthSinceLastPlacement;

  const TraceEntry({...});
}
```

```dart
final class SolveResult {
  final bool solved;
  final List<TraceEntry> trace;
  final List<Cell> placedTokens;

  const SolveResult({...});
}
```

```dart
abstract class LogicSolver {
  SolveResult solve(PuzzleDefinition puzzle);
}

abstract class UniquenessSolver {
  /// Returns 0, 1, or 2. Early-exits at 2.
  int countSolutions(PuzzleDefinition puzzle);
}
```

---

## 2. Runtime types

State for an in-progress puzzle session. Consumed by the Flutter layer; mutated through well-defined session APIs.

### `PuzzleSession`

```dart
final class PuzzleSession {
  final PuzzleDefinition puzzle;
  final DateTime startedAt;
  DateTime? completedAt;

  final List<Cell> placedTokens;         // mutable; order of placement
  final Set<Cell> playerXMarks;          // mutable
  final Set<Cell> autoXMarks;            // mutable; not reversible by the player
  int livesRemaining;                    // starts at 3
  final List<UndoEntry> undoStack;       // mutable

  PuzzleSession.fresh(this.puzzle) : ...;

  // Mutation API
  void toggleXMark(Cell cell);           // player-placed only
  void attemptPlacement(Cell cell);      // triggers solution validation, housekeeping, or life loss
  void undo();                           // pops the last reversible action
  void restart();                        // resets to fresh state

  // Query API
  bool get isComplete;                   // all tokens placed
  bool get isFailed;                     // livesRemaining == 0
  SessionOutcome? get outcome;           // null until completion
}
```

**Invariants**
- `0 <= livesRemaining <= 3`.
- `playerXMarks` and `autoXMarks` are disjoint — a correct placement upgrades a cell's status, it doesn't stack marks.
- A cell cannot be both in `placedTokens` and have any X mark.
- `completedAt` is set exactly when `isComplete` first transitions to `true`.

### `UndoEntry`

Undo **only** reverses reversible player actions. Token placements and life loss are not reversible.

```dart
sealed class UndoEntry {
  final DateTime at;
}
final class PlaceXMarkAction extends UndoEntry { final Cell cell; }
final class RemoveXMarkAction extends UndoEntry { final Cell cell; }
```

### `SessionOutcome`

```dart
final class SessionOutcome {
  final bool won;
  final int livesLostDuringRun;
  final int starsEarned;   // 0-3 (0 only if !won)
  final int coinsEarned;   // per the tables in README
  const SessionOutcome({...});
}
```

**Invariants**
- `won == true` implies `starsEarned >= 1` and `coinsEarned > 0`.
- `won == false` implies `starsEarned == 0` and `coinsEarned == 0`.
- `livesLostDuringRun` is computed from the current run only — prior failed attempts do not contribute.

### Session → Outcome derivation

```dart
SessionOutcome deriveOutcome(PuzzleSession session) { /* applies the README tables */ }
```

The star/coin tables are the single source of truth for this derivation. See [README.md §Stars](../README.md#stars-cumulative-score) and [§Coins](../README.md#coins).

---

## 3. Persistence types

Plain data shapes mapped by the Drift layer. The puzzle_core package defines the shapes; the app defines the Drift tables.

### `ProgressRecord`

Per-puzzle best result.

```dart
final class ProgressRecord {
  final String puzzleId;
  final int bestStars;        // 0-3; persists the best across attempts
  final bool completed;       // bestStars >= 1 implies completed == true
  final int coinsEarnedLifetime; // cumulative across all successful runs
  final DateTime? firstCompletedAt;
  final DateTime? lastPlayedAt;

  const ProgressRecord({...});
}
```

**Invariants**
- `bestStars >= 1 <=> completed == true`.
- `completed == false <=> firstCompletedAt == null`.
- `coinsEarnedLifetime >= 0`.

### `PlayerProfile`

Single-row table for the local player.

```dart
final class PlayerProfile {
  final int totalStars;       // cumulative across all ProgressRecords
  final int totalCoins;       // spendable balance; NOT equal to sum of coinsEarnedLifetime
  final int currentLevel;     // 0-indexed linear progression cursor

  const PlayerProfile({...});
}
```

**Invariants**
- All fields non-negative.
- `totalStars == sum(progressRecords.bestStars)` — maintained by the persistence layer.
- `totalCoins` decreases only when coin sinks ship (deferred to later phase).

### `LevelPackMetadata`

Metadata bundled alongside each level pack JSON.

```dart
final class LevelPackMetadata {
  final int seed;                         // RNG seed used by the generator
  final String generatorVersion;          // semver
  final Map<String, Object?> pipelineParameters;
  final Map<Difficulty, int> bandCounts;  // {easy: 200, medium: 175, hard: 100, master: 25}
  final DateTime generatedAt;
  final int schemaVersion;                // matches PuzzleDefinition.schemaVersion

  const LevelPackMetadata({...});
}
```

**Reproducibility contract.** Given the same `seed`, `generatorVersion`, and `pipelineParameters`, the generator produces a byte-identical level pack. See [docs/level-generation.md §Reproducibility](level-generation.md#reproducibility).

---

## JSON schema

The puzzle JSON schema is authoritatively described in [docs/level-generation.md §Puzzle JSON structure](level-generation.md#puzzle-json-structure).

`PuzzleDefinition.fromJson` and `.toJson` round-trip that schema exactly. Add a round-trip unit test in `puzzle_core` that asserts `fromJson(toJson(p)) == p` for every bundled fixture.

---

## Invariant enforcement summary

| Type | Enforced at | Mechanism |
|---|---|---|
| Cell | construction | assert (row, col >= 0) |
| Region | construction | assert id, cells non-empty, contiguous |
| PuzzleSolution | construction | assert length, row mapping, column permutation, no-touch |
| PuzzleDefinition | construction + `fromJson` | assert size, regions count, disjoint partition, solution validity |
| CandidateGrid | mutation methods | throw StateError on illegal transitions (e.g., placing an eliminated cell) |
| PuzzleSession | mutation methods | throw StateError on illegal moves (e.g., undo with empty stack) |
| ProgressRecord / PlayerProfile | persistence layer | Drift `CHECK` constraints + application-level derivation |

Construction failures are assertions (development errors). Runtime mutation failures are `StateError` (can surface from bad input or buggy UI).

---

## Testing contract

Every type in this document has at least:

- **Equality test.** `a == b` iff all fields match; hashCode consistent.
- **Construction-invariant test.** Each documented invariant has a test that confirms invalid input throws (or asserts, under asserts-enabled test runs).
- **Round-trip test** where applicable (JSON, undo-redo).
- **Golden fixture test** for `PuzzleDefinition` against the fixtures in [docs/test-fixtures.md](test-fixtures.md).
