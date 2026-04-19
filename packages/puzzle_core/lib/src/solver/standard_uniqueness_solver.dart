import '../models/cell.dart';
import '../models/puzzle_definition.dart';
import '../models/region.dart';
import 'uniqueness_solver.dart';

/// Backtracking uniqueness checker for 1-star Star Battle puzzles.
///
/// The search is allowed to use backtracking because it is a generator and
/// validation tool, not a player-facing hint source. It processes rows in
/// order, enforces one token per column and region, applies only adjacent-cell
/// no-touch conflicts, and stops as soon as a second solution is found.
final class StandardUniquenessSolver implements UniquenessSolver {
  /// Creates a solver that returns `0`, `1`, or `2` (`2` means at least two).
  const StandardUniquenessSolver();

  @override
  int countSolutions(PuzzleDefinition puzzle) {
    final Map<Cell, int> regionIdByCell = _buildRegionLookup(puzzle.regions);
    final Set<int> usedColumns = <int>{};
    final Set<int> usedRegions = <int>{};
    final List<Cell> placed = <Cell>[];
    var solutions = 0;

    void search(int row) {
      if (solutions >= 2) {
        return;
      }
      if (row == puzzle.size) {
        solutions += 1;
        return;
      }

      for (int col = 0; col < puzzle.size; col++) {
        final Cell candidate = Cell(row, col);
        final int regionId = regionIdByCell[candidate]!;
        if (usedColumns.contains(col) || usedRegions.contains(regionId)) {
          continue;
        }
        if (placed.any(candidate.touches)) {
          continue;
        }

        usedColumns.add(col);
        usedRegions.add(regionId);
        placed.add(candidate);

        if (_unusedRegionsCanStillPlace(
          puzzle: puzzle,
          nextRow: row + 1,
          regionIdByCell: regionIdByCell,
          usedColumns: usedColumns,
          usedRegions: usedRegions,
          placed: placed,
        )) {
          search(row + 1);
        }

        placed.removeLast();
        usedRegions.remove(regionId);
        usedColumns.remove(col);
      }
    }

    search(0);
    return solutions > 2 ? 2 : solutions;
  }

  bool _unusedRegionsCanStillPlace({
    required PuzzleDefinition puzzle,
    required int nextRow,
    required Map<Cell, int> regionIdByCell,
    required Set<int> usedColumns,
    required Set<int> usedRegions,
    required List<Cell> placed,
  }) {
    for (final Region region in puzzle.regions) {
      if (usedRegions.contains(region.id)) {
        continue;
      }
      final bool hasFutureCandidate = region.cells.any((Cell cell) {
        if (cell.row < nextRow || usedColumns.contains(cell.col)) {
          return false;
        }
        if (regionIdByCell[cell] != region.id) {
          return false;
        }
        return !placed.any(cell.touches);
      });
      if (!hasFutureCandidate) {
        return false;
      }
    }
    return true;
  }
}

Map<Cell, int> _buildRegionLookup(List<Region> regions) {
  final Map<Cell, int> regionIdByCell = <Cell, int>{};
  for (final Region region in regions) {
    for (final Cell cell in region.cells) {
      regionIdByCell[cell] = region.id;
    }
  }
  return regionIdByCell;
}
