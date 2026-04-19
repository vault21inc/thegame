import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:puzzle_core/puzzle_core.dart';

/// Harness types for synthetic deduction-family scenarios. These live in
/// `test/` rather than `lib/` because they are only meant to be consumed by
/// the deduction-engine tests once the engine lands in milestone 3.
///
/// A [DeductionScenario] declares a concrete starting [CandidateGrid] state
/// (region layout + initial eliminations + any initial placements) plus an
/// [ExpectedOutcome] describing what the solver should do first.
///
/// Milestone 3's scenario runner loads each scenario, constructs a real
/// [CandidateGrid], steps the solver once, and asserts the produced trace
/// entry matches [DeductionScenario.expected].

/// The outcome the solver is expected to produce from the scenario's
/// initial state.
@immutable
sealed class ExpectedOutcome {
  const ExpectedOutcome();
}

/// The next trace entry should be a placement of [cell] attributed to
/// [family].
final class ExpectedPlacement extends ExpectedOutcome {
  const ExpectedPlacement({required this.cell, required this.family});
  final Cell cell;
  final DeductionFamily family;

  @override
  bool operator ==(Object other) =>
      other is ExpectedPlacement &&
      other.cell == cell &&
      other.family == family;

  @override
  int get hashCode => Object.hash('ExpectedPlacement', cell, family);

  @override
  String toString() => 'ExpectedPlacement($cell, ${family.name})';
}

/// The next trace entry should eliminate exactly [cells] attributed to
/// [family]. Set comparison is order-independent.
final class ExpectedElimination extends ExpectedOutcome {
  ExpectedElimination({required Set<Cell> cells, required this.family})
      : cells = Set<Cell>.unmodifiable(cells);
  final Set<Cell> cells;
  final DeductionFamily family;

  @override
  bool operator ==(Object other) =>
      other is ExpectedElimination &&
      other.family == family &&
      const SetEquality<Cell>().equals(cells, other.cells);

  @override
  int get hashCode => Object.hash(
        'ExpectedElimination',
        family,
        const SetEquality<Cell>().hash(cells),
      );

  @override
  String toString() =>
      'ExpectedElimination(${cells.length} cells, ${family.name})';
}

/// The solver should make no progress from the initial state — no placement,
/// no elimination, no family fires. Used for negative scenarios.
final class ExpectedNoProgress extends ExpectedOutcome {
  const ExpectedNoProgress();

  @override
  bool operator ==(Object other) => other is ExpectedNoProgress;

  @override
  int get hashCode => 'ExpectedNoProgress'.hashCode;

  @override
  String toString() => 'ExpectedNoProgress()';
}

/// A single hand-designed deduction-engine input plus its expected first step.
@immutable
final class DeductionScenario {
  DeductionScenario({
    required this.id,
    required this.description,
    required this.gridSize,
    required List<Region> regions,
    required Set<Cell> initialEliminations,
    required Set<Cell> initialPlacements,
    required this.expected,
    Set<DeductionFamily> mustNotFireFirst = const <DeductionFamily>{},
  })  : regions = List<Region>.unmodifiable(regions),
        initialEliminations = Set<Cell>.unmodifiable(initialEliminations),
        initialPlacements = Set<Cell>.unmodifiable(initialPlacements),
        mustNotFireFirst = Set<DeductionFamily>.unmodifiable(mustNotFireFirst);

  /// Stable identifier, matches [docs/test-fixtures.md].
  final String id;

  /// One-line human-readable summary of what this scenario exercises.
  final String description;

  /// Square grid side length.
  final int gridSize;

  /// Region partition. Must cover every cell in `[0, gridSize) x [0, gridSize)`
  /// exactly once.
  final List<Region> regions;

  /// Cells whose state starts as [CellState.eliminated].
  final Set<Cell> initialEliminations;

  /// Cells whose state starts as [CellState.placed]. Housekeeping is NOT
  /// auto-applied — if the scenario assumes housekeeping ran, declare the
  /// resulting eliminations explicitly in [initialEliminations].
  final Set<Cell> initialPlacements;

  /// What the solver's first trace entry is expected to look like.
  final ExpectedOutcome expected;

  /// Families that must NOT fire before the family referenced by [expected].
  /// Used by ordering scenarios (e.g., O-family-1-before-2 forbids family 2
  /// from firing first).
  final Set<DeductionFamily> mustNotFireFirst;

  @override
  String toString() => 'DeductionScenario($id: $description)';
}

/// Validation errors surfaced by [validateScenario].
///
/// Each represents one way a scenario can be structurally ill-formed.
@immutable
sealed class ScenarioDefect {
  const ScenarioDefect(this.scenarioId, this.message);
  final String scenarioId;
  final String message;

  @override
  String toString() => '[$scenarioId] $message';
}

final class MalformedPartition extends ScenarioDefect {
  const MalformedPartition(super.scenarioId, super.message);
}

final class InconsistentInitialState extends ScenarioDefect {
  const InconsistentInitialState(super.scenarioId, super.message);
}

final class ExpectationInvalid extends ScenarioDefect {
  const ExpectationInvalid(super.scenarioId, super.message);
}

/// Returns a list of defects found in [scenario]. An empty list means the
/// scenario is structurally sound (regions partition the grid, initial state
/// is internally consistent, and the expected outcome targets cells that are
/// actually in the grid).
///
/// This does NOT attempt to run the deduction engine or verify that the
/// expected family is actually the family that would fire — that is what
/// milestone 3's scenario runner is for.
List<ScenarioDefect> validateScenario(DeductionScenario scenario) {
  final List<ScenarioDefect> defects = <ScenarioDefect>[];
  final int size = scenario.gridSize;
  final String id = scenario.id;

  void addMalformed(String message) {
    defects.add(MalformedPartition(id, message));
  }

  void addInconsistent(String message) {
    defects.add(InconsistentInitialState(id, message));
  }

  void addInvalidExpectation(String message) {
    defects.add(ExpectationInvalid(id, message));
  }

  // --- partition validity ---
  final Map<Cell, int> cellOwner = <Cell, int>{};
  for (final Region region in scenario.regions) {
    for (final Cell cell in region.cells) {
      if (cell.row < 0 ||
          cell.row >= size ||
          cell.col < 0 ||
          cell.col >= size) {
        addMalformed(
          'Region ${region.id} contains out-of-bounds cell $cell for '
          'gridSize $size',
        );
        continue;
      }
      final int? existing = cellOwner[cell];
      if (existing != null) {
        addMalformed(
          'Cell $cell assigned to both region $existing and region '
          '${region.id}',
        );
        continue;
      }
      cellOwner[cell] = region.id;
    }
  }

  final int expectedCellCount = size * size;
  if (cellOwner.length != expectedCellCount) {
    addMalformed(
      'Regions cover ${cellOwner.length} cells; expected '
      '$expectedCellCount for a $size x $size grid',
    );
  }

  final Set<int> seenIds = <int>{};
  for (final Region region in scenario.regions) {
    if (!seenIds.add(region.id)) {
      addMalformed('Duplicate region id: ${region.id}');
    }
  }

  // --- initial state consistency ---
  for (final Cell cell in scenario.initialEliminations) {
    if (scenario.initialPlacements.contains(cell)) {
      addInconsistent(
        'Cell $cell is both eliminated and placed in the initial state',
      );
    }
    if (!cellOwner.containsKey(cell)) {
      addInconsistent('Initial elimination at $cell is not in any region');
    }
  }
  for (final Cell cell in scenario.initialPlacements) {
    if (!cellOwner.containsKey(cell)) {
      addInconsistent('Initial placement at $cell is not in any region');
    }
  }

  // --- expected-outcome consistency ---
  final ExpectedOutcome expected = scenario.expected;
  switch (expected) {
    case ExpectedPlacement(:final Cell cell):
      if (!cellOwner.containsKey(cell)) {
        addInvalidExpectation(
          'ExpectedPlacement cell $cell is not in any region',
        );
      }
      if (scenario.initialEliminations.contains(cell)) {
        addInvalidExpectation(
          'ExpectedPlacement cell $cell is already eliminated in the '
          'initial state',
        );
      }
      if (scenario.initialPlacements.contains(cell)) {
        addInvalidExpectation(
          'ExpectedPlacement cell $cell is already placed in the initial '
          'state',
        );
      }
    case ExpectedElimination(:final Set<Cell> cells):
      if (cells.isEmpty) {
        addInvalidExpectation(
          'ExpectedElimination must list at least one cell',
        );
      }
      for (final Cell cell in cells) {
        if (!cellOwner.containsKey(cell)) {
          addInvalidExpectation(
            'ExpectedElimination cell $cell is not in any region',
          );
        }
        if (scenario.initialEliminations.contains(cell)) {
          addInvalidExpectation(
            'ExpectedElimination cell $cell is already eliminated; it '
            'cannot be eliminated twice',
          );
        }
        if (scenario.initialPlacements.contains(cell)) {
          addInvalidExpectation(
            'ExpectedElimination cell $cell is already placed; cannot be '
            'eliminated',
          );
        }
      }
    case ExpectedNoProgress():
      break;
  }

  return defects;
}
