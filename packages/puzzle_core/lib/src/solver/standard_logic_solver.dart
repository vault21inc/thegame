import '../models/cell.dart';
import '../models/puzzle_definition.dart';
import '../models/region.dart';
import 'deduction_rules.dart';
import 'deduction_step.dart';
import 'logic_solver.dart';
import 'solve_result.dart';
import 'standard_candidate_grid.dart';
import 'trace_entry.dart';

/// Default deterministic implementation of the official logic solver.
///
/// The solver starts with every cell as a candidate, repeatedly asks the pure
/// deduction functions for the next easiest step, applies that step, and
/// records a [TraceEntry]. Placements include their immediate housekeeping in
/// the candidate count delta, but housekeeping is not emitted as a separate
/// family because it is automatic consequence, not a deduction family.
final class StandardLogicSolver implements LogicSolver {
  /// Creates a solver using the fixed deduction order from the generator spec.
  const StandardLogicSolver();

  @override
  SolveResult solve(PuzzleDefinition puzzle) {
    return _solveGrid(
      size: puzzle.size,
      regions: puzzle.regions,
      grid: StandardCandidateGrid.fromPuzzle(puzzle),
    );
  }

  /// Solves an explicit candidate-grid state using the same loop as [solve].
  ///
  /// This exists for deduction scenario verification and future hint/debug
  /// tooling where the engine needs to start from a partially-eliminated
  /// candidate state instead of a pristine [PuzzleDefinition]. [regions] must
  /// partition the `size x size` grid. [initialEliminations] and
  /// [initialPlacements] are applied before the first deduction is searched.
  SolveResult solveState({
    required int size,
    required List<Region> regions,
    Set<Cell> initialEliminations = const <Cell>{},
    Set<Cell> initialPlacements = const <Cell>{},
  }) {
    return _solveGrid(
      size: size,
      regions: regions,
      grid: StandardCandidateGrid(
        size: size,
        regions: regions,
        initialEliminations: initialEliminations,
        initialPlacements: initialPlacements,
      ),
    );
  }

  SolveResult _solveGrid({
    required int size,
    required List<Region> regions,
    required StandardCandidateGrid grid,
  }) {
    final List<TraceEntry> trace = <TraceEntry>[];
    var chainDepth = 0;

    while (!_isSolved(size: size, regions: regions, grid: grid)) {
      final DeductionStep? step = findNextDeduction(
        size: size,
        regions: regions,
        grid: grid,
      );
      if (step == null) {
        break;
      }

      final int candidatesBefore = grid.candidateCount;
      if (step.isPlacement) {
        final Cell placed = step.placed!;
        grid.place(placed);
        _applyHousekeeping(
          size: size,
          regions: regions,
          grid: grid,
          placed: placed,
        );
        trace.add(
          TraceEntry(
            family: step.family,
            eliminated: const <Cell>[],
            placed: placed,
            candidatesBefore: candidatesBefore,
            candidatesAfter: grid.candidateCount,
            chainDepthSinceLastPlacement: 0,
          ),
        );
        chainDepth = 0;
      } else {
        for (final Cell cell in step.eliminated) {
          grid.eliminate(cell);
        }
        chainDepth += 1;
        trace.add(
          TraceEntry(
            family: step.family,
            eliminated: step.eliminated,
            placed: null,
            candidatesBefore: candidatesBefore,
            candidatesAfter: grid.candidateCount,
            chainDepthSinceLastPlacement: chainDepth,
          ),
        );
      }
    }

    final List<Cell> placedTokens = grid.placedCells.toList(growable: false);
    return SolveResult(
      solved: _isSolved(size: size, regions: regions, grid: grid),
      trace: trace,
      placedTokens: placedTokens,
    );
  }

  void _applyHousekeeping({
    required int size,
    required List<Region> regions,
    required StandardCandidateGrid grid,
    required Cell placed,
  }) {
    final Set<Cell> eliminated = housekeepingCandidates(
      size: size,
      regions: regions,
      grid: grid,
      placed: placed,
    );
    for (final Cell cell in eliminated) {
      grid.eliminate(cell);
    }
  }

  bool _isSolved({
    required int size,
    required List<Region> regions,
    required StandardCandidateGrid grid,
  }) {
    final Set<Cell> placed = grid.placedCells;
    if (placed.length != size) {
      return false;
    }
    final Set<int> rows = <int>{};
    final Set<int> columns = <int>{};
    final Set<int> regionIds = <int>{};
    final List<Cell> tokens = placed.toList(growable: false);
    for (final Cell token in tokens) {
      rows.add(token.row);
      columns.add(token.col);
      regionIds.add(grid.regionIdAt(token));
    }
    if (rows.length != size ||
        columns.length != size ||
        regionIds.length != regions.length) {
      return false;
    }
    for (int i = 0; i < tokens.length; i++) {
      for (int j = i + 1; j < tokens.length; j++) {
        if (tokens[i].touches(tokens[j])) {
          return false;
        }
      }
    }
    return true;
  }
}
