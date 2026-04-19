import '../models/cell.dart';
import '../models/deduction_family.dart';
import '../models/region.dart';
import 'candidate_grid.dart';
import 'cell_ordering.dart';
import 'cell_state.dart';
import 'deduction_step.dart';

/// Finds the next deduction using the official easiest-first family order.
///
/// This function is pure: it inspects [grid] but does not mutate it. The
/// returned [DeductionStep] can then be applied by a solver, test harness, or
/// future hint system that wants the same deterministic ordering.
DeductionStep? findNextDeduction({
  required int size,
  required List<Region> regions,
  required CandidateGrid grid,
}) {
  return findGiveawayCell(size: size, regions: regions, grid: grid) ??
      findConfinement(size: size, regions: regions, grid: grid) ??
      findTouchAllElimination(size: size, regions: regions, grid: grid) ??
      findContradictionElimination(
        size: size,
        regions: regions,
        grid: grid,
      ) ??
      findHigherOrderConfinement(size: size, regions: regions, grid: grid);
}

/// Finds a Family 1 Giveaway Cell placement.
///
/// Rows, then columns, then regions are scanned in stable order. The first
/// row/column/region with exactly one remaining candidate forces that cell to
/// contain a token.
DeductionStep? findGiveawayCell({
  required int size,
  required List<Region> regions,
  required CandidateGrid grid,
}) {
  for (int row = 0; row < size; row++) {
    final Set<Cell> candidates = grid.candidatesInRow(row);
    if (candidates.length == 1) {
      return DeductionStep.place(
        family: DeductionFamily.giveawayCell,
        cell: candidates.single,
      );
    }
  }
  for (int col = 0; col < size; col++) {
    final Set<Cell> candidates = grid.candidatesInColumn(col);
    if (candidates.length == 1) {
      return DeductionStep.place(
        family: DeductionFamily.giveawayCell,
        cell: candidates.single,
      );
    }
  }
  for (final Region region in _regionsById(regions)) {
    final Set<Cell> candidates = grid.candidatesInRegion(region.id);
    if (candidates.length == 1) {
      return DeductionStep.place(
        family: DeductionFamily.giveawayCell,
        cell: candidates.single,
      );
    }
  }
  return null;
}

/// Finds a Family 2 Confinement elimination.
///
/// The region-to-row/column direction is tried before the symmetric
/// row/column-to-region direction, matching the grader ordering. Singleton
/// candidate sets are ignored here because Family 1 owns forced placements.
DeductionStep? findConfinement({
  required int size,
  required List<Region> regions,
  required CandidateGrid grid,
}) {
  final Map<Cell, int> regionIdByCell = _buildRegionLookup(regions);

  for (final Region region in _regionsById(regions)) {
    final Set<Cell> candidates = grid.candidatesInRegion(region.id);
    if (candidates.length < 2) {
      continue;
    }

    final Set<int> rows = <int>{for (final Cell cell in candidates) cell.row};
    if (rows.length == 1) {
      final int row = rows.single;
      final Set<Cell> eliminated = grid
          .candidatesInRow(row)
          .where((Cell cell) => regionIdByCell[cell] != region.id)
          .toSet();
      if (eliminated.isNotEmpty) {
        return DeductionStep.eliminate(
          family: DeductionFamily.confinement,
          cells: eliminated,
        );
      }
    }

    final Set<int> cols = <int>{for (final Cell cell in candidates) cell.col};
    if (cols.length == 1) {
      final int col = cols.single;
      final Set<Cell> eliminated = grid
          .candidatesInColumn(col)
          .where((Cell cell) => regionIdByCell[cell] != region.id)
          .toSet();
      if (eliminated.isNotEmpty) {
        return DeductionStep.eliminate(
          family: DeductionFamily.confinement,
          cells: eliminated,
        );
      }
    }
  }

  for (int row = 0; row < size; row++) {
    final Set<Cell> candidates = grid.candidatesInRow(row);
    if (candidates.length < 2) {
      continue;
    }
    final Set<int> regionIds = <int>{
      for (final Cell cell in candidates) regionIdByCell[cell]!,
    };
    if (regionIds.length == 1) {
      final int regionId = regionIds.single;
      final Set<Cell> eliminated = grid
          .candidatesInRegion(regionId)
          .where((Cell cell) => cell.row != row)
          .toSet();
      if (eliminated.isNotEmpty) {
        return DeductionStep.eliminate(
          family: DeductionFamily.confinement,
          cells: eliminated,
        );
      }
    }
  }

  for (int col = 0; col < size; col++) {
    final Set<Cell> candidates = grid.candidatesInColumn(col);
    if (candidates.length < 2) {
      continue;
    }
    final Set<int> regionIds = <int>{
      for (final Cell cell in candidates) regionIdByCell[cell]!,
    };
    if (regionIds.length == 1) {
      final int regionId = regionIds.single;
      final Set<Cell> eliminated = grid
          .candidatesInRegion(regionId)
          .where((Cell cell) => cell.col != col)
          .toSet();
      if (eliminated.isNotEmpty) {
        return DeductionStep.eliminate(
          family: DeductionFamily.confinement,
          cells: eliminated,
        );
      }
    }
  }

  return null;
}

/// Finds a Family 3 Touch-All Elimination.
///
/// For the first region whose remaining candidates are all touched by one or
/// more outside candidates, those outside candidates are removed together as
/// one application of the family.
DeductionStep? findTouchAllElimination({
  required int size,
  required List<Region> regions,
  required CandidateGrid grid,
}) {
  final Map<Cell, int> regionIdByCell = _buildRegionLookup(regions);

  for (final Region region in _regionsById(regions)) {
    final Set<Cell> regionCandidates = grid.candidatesInRegion(region.id);
    if (regionCandidates.length < 2) {
      continue;
    }

    final Set<Cell> eliminated = <Cell>{};
    for (final Cell candidate in _candidateCells(size, grid)) {
      if (regionIdByCell[candidate] == region.id) {
        continue;
      }
      final bool touchesAll = regionCandidates.every(candidate.touches);
      if (touchesAll) {
        eliminated.add(candidate);
      }
    }
    if (eliminated.isNotEmpty) {
      return DeductionStep.eliminate(
        family: DeductionFamily.touchAllElimination,
        cells: eliminated,
      );
    }
  }

  return null;
}

/// Finds a Family 4 Contradiction / Blocking elimination.
///
/// Candidate cells are tried in row-major order. A candidate is eliminated if
/// placing a token there would immediately leave an unsolved row, column, or
/// region with no remaining candidates.
DeductionStep? findContradictionElimination({
  required int size,
  required List<Region> regions,
  required CandidateGrid grid,
}) {
  final Map<Cell, int> regionIdByCell = _buildRegionLookup(regions);

  for (final Cell candidate in _candidateCells(size, grid)) {
    final Set<Cell> removedByPlacement = _housekeepingCandidates(
      size: size,
      grid: grid,
      placed: candidate,
      regionIdByCell: regionIdByCell,
    );
    final int candidateRegionId = regionIdByCell[candidate]!;

    for (int row = 0; row < size; row++) {
      if (row == candidate.row || _rowHasPlacedToken(size, grid, row)) {
        continue;
      }
      final Set<Cell> rowCandidates = grid.candidatesInRow(row);
      if (rowCandidates.isEmpty) {
        continue;
      }
      final bool wouldEmpty = rowCandidates
          .where((Cell cell) => !removedByPlacement.contains(cell))
          .isEmpty;
      if (wouldEmpty) {
        return DeductionStep.eliminate(
          family: DeductionFamily.contradictionElimination,
          cells: <Cell>{candidate},
        );
      }
    }

    for (int col = 0; col < size; col++) {
      if (col == candidate.col || _columnHasPlacedToken(size, grid, col)) {
        continue;
      }
      final Set<Cell> columnCandidates = grid.candidatesInColumn(col);
      if (columnCandidates.isEmpty) {
        continue;
      }
      final bool wouldEmpty = columnCandidates
          .where((Cell cell) => !removedByPlacement.contains(cell))
          .isEmpty;
      if (wouldEmpty) {
        return DeductionStep.eliminate(
          family: DeductionFamily.contradictionElimination,
          cells: <Cell>{candidate},
        );
      }
    }

    for (final Region region in _regionsById(regions)) {
      if (region.id == candidateRegionId ||
          _regionHasPlacedToken(grid, region)) {
        continue;
      }
      final Set<Cell> regionCandidates = grid.candidatesInRegion(region.id);
      if (regionCandidates.isEmpty) {
        continue;
      }
      final bool wouldEmpty = regionCandidates
          .where((Cell cell) => !removedByPlacement.contains(cell))
          .isEmpty;
      if (wouldEmpty) {
        return DeductionStep.eliminate(
          family: DeductionFamily.contradictionElimination,
          cells: <Cell>{candidate},
        );
      }
    }
  }

  return null;
}

/// Finds a Family 5 Higher-Order Confinement elimination.
///
/// K=2 cases are tried before K=3. For each K, region subsets confined to K
/// rows/columns are tried before the symmetric row/column subsets confined to
/// K regions. This mirrors the Master-band grader rule while keeping the
/// player-facing solver vocabulary unchanged.
DeductionStep? findHigherOrderConfinement({
  required int size,
  required List<Region> regions,
  required CandidateGrid grid,
}) {
  final Map<Cell, int> regionIdByCell = _buildRegionLookup(regions);
  final List<Region> sortedRegions = _regionsById(regions);

  for (final int subsetSize in <int>[2, 3]) {
    final DeductionStep? regionStep = _findHigherOrderByRegions(
      subsetSize: subsetSize,
      sortedRegions: sortedRegions,
      grid: grid,
      regionIdByCell: regionIdByCell,
    );
    if (regionStep != null) {
      return regionStep;
    }

    final DeductionStep? rowStep = _findHigherOrderByRows(
      size: size,
      subsetSize: subsetSize,
      regions: sortedRegions,
      grid: grid,
      regionIdByCell: regionIdByCell,
    );
    if (rowStep != null) {
      return rowStep;
    }

    final DeductionStep? columnStep = _findHigherOrderByColumns(
      size: size,
      subsetSize: subsetSize,
      regions: sortedRegions,
      grid: grid,
      regionIdByCell: regionIdByCell,
    );
    if (columnStep != null) {
      return columnStep;
    }
  }

  return null;
}

/// Returns candidates cleared by placement housekeeping for [placed].
///
/// The returned cells are the current candidates in [placed]'s row, column,
/// region, and 3x3 no-touch neighborhood, excluding [placed] itself. The
/// function is pure and is shared by the logic solver, Family 4 simulation,
/// and future app-side auto-marking behavior.
Set<Cell> housekeepingCandidates({
  required int size,
  required List<Region> regions,
  required CandidateGrid grid,
  required Cell placed,
}) {
  final Map<Cell, int> regionIdByCell = _buildRegionLookup(regions);
  return _housekeepingCandidates(
    size: size,
    grid: grid,
    placed: placed,
    regionIdByCell: regionIdByCell,
  );
}

Set<Cell> _housekeepingCandidates({
  required int size,
  required CandidateGrid grid,
  required Cell placed,
  required Map<Cell, int> regionIdByCell,
}) {
  final int regionId = regionIdByCell[placed]!;
  final Set<Cell> eliminated = <Cell>{};

  eliminated.addAll(grid.candidatesInRow(placed.row));
  eliminated.addAll(grid.candidatesInColumn(placed.col));
  eliminated.addAll(grid.candidatesInRegion(regionId));

  for (int row = placed.row - 1; row <= placed.row + 1; row++) {
    if (row < 0 || row >= size) {
      continue;
    }
    for (int col = placed.col - 1; col <= placed.col + 1; col++) {
      if (col < 0 || col >= size) {
        continue;
      }
      final Cell neighbor = Cell(row, col);
      if (neighbor != placed && grid.stateAt(neighbor) == CellState.candidate) {
        eliminated.add(neighbor);
      }
    }
  }

  eliminated.remove(placed);
  return Set<Cell>.unmodifiable(sortCellsRowMajor(eliminated));
}

DeductionStep? _findHigherOrderByRegions({
  required int subsetSize,
  required List<Region> sortedRegions,
  required CandidateGrid grid,
  required Map<Cell, int> regionIdByCell,
}) {
  for (final List<Region> subset in _combinations(sortedRegions, subsetSize)) {
    final Set<int> subsetIds = <int>{
      for (final Region region in subset) region.id,
    };
    final Set<Cell> candidates = <Cell>{};
    var allRegionsHaveCandidates = true;
    for (final Region region in subset) {
      final Set<Cell> regionCandidates = grid.candidatesInRegion(region.id);
      if (regionCandidates.isEmpty) {
        allRegionsHaveCandidates = false;
        break;
      }
      candidates.addAll(regionCandidates);
    }
    if (!allRegionsHaveCandidates) {
      continue;
    }

    final Set<int> rows = <int>{for (final Cell cell in candidates) cell.row};
    if (rows.length == subsetSize) {
      final Set<Cell> eliminated = <Cell>{};
      for (final int row in _sortedInts(rows)) {
        eliminated.addAll(
          grid
              .candidatesInRow(row)
              .where((Cell cell) => !subsetIds.contains(regionIdByCell[cell])),
        );
      }
      if (eliminated.isNotEmpty) {
        return DeductionStep.eliminate(
          family: DeductionFamily.higherOrderConfinement,
          cells: eliminated,
        );
      }
    }

    final Set<int> cols = <int>{for (final Cell cell in candidates) cell.col};
    if (cols.length == subsetSize) {
      final Set<Cell> eliminated = <Cell>{};
      for (final int col in _sortedInts(cols)) {
        eliminated.addAll(
          grid.candidatesInColumn(col).where(
                (Cell cell) => !subsetIds.contains(regionIdByCell[cell]),
              ),
        );
      }
      if (eliminated.isNotEmpty) {
        return DeductionStep.eliminate(
          family: DeductionFamily.higherOrderConfinement,
          cells: eliminated,
        );
      }
    }
  }
  return null;
}

DeductionStep? _findHigherOrderByRows({
  required int size,
  required int subsetSize,
  required List<Region> regions,
  required CandidateGrid grid,
  required Map<Cell, int> regionIdByCell,
}) {
  for (final List<int> rows in _combinations(_range(size), subsetSize)) {
    final Set<Cell> candidates = <Cell>{};
    var allRowsHaveCandidates = true;
    for (final int row in rows) {
      final Set<Cell> rowCandidates = grid.candidatesInRow(row);
      if (rowCandidates.isEmpty) {
        allRowsHaveCandidates = false;
        break;
      }
      candidates.addAll(rowCandidates);
    }
    if (!allRowsHaveCandidates) {
      continue;
    }

    final Set<int> regionIds = <int>{
      for (final Cell cell in candidates) regionIdByCell[cell]!,
    };
    if (regionIds.length != subsetSize) {
      continue;
    }

    final Set<int> rowSet = rows.toSet();
    final Set<Cell> eliminated = <Cell>{};
    for (final int regionId in _sortedInts(regionIds)) {
      eliminated.addAll(
        grid
            .candidatesInRegion(regionId)
            .where((Cell cell) => !rowSet.contains(cell.row)),
      );
    }
    if (eliminated.isNotEmpty) {
      return DeductionStep.eliminate(
        family: DeductionFamily.higherOrderConfinement,
        cells: eliminated,
      );
    }
  }
  return null;
}

DeductionStep? _findHigherOrderByColumns({
  required int size,
  required int subsetSize,
  required List<Region> regions,
  required CandidateGrid grid,
  required Map<Cell, int> regionIdByCell,
}) {
  for (final List<int> cols in _combinations(_range(size), subsetSize)) {
    final Set<Cell> candidates = <Cell>{};
    var allColumnsHaveCandidates = true;
    for (final int col in cols) {
      final Set<Cell> columnCandidates = grid.candidatesInColumn(col);
      if (columnCandidates.isEmpty) {
        allColumnsHaveCandidates = false;
        break;
      }
      candidates.addAll(columnCandidates);
    }
    if (!allColumnsHaveCandidates) {
      continue;
    }

    final Set<int> regionIds = <int>{
      for (final Cell cell in candidates) regionIdByCell[cell]!,
    };
    if (regionIds.length != subsetSize) {
      continue;
    }

    final Set<int> columnSet = cols.toSet();
    final Set<Cell> eliminated = <Cell>{};
    for (final int regionId in _sortedInts(regionIds)) {
      eliminated.addAll(
        grid
            .candidatesInRegion(regionId)
            .where((Cell cell) => !columnSet.contains(cell.col)),
      );
    }
    if (eliminated.isNotEmpty) {
      return DeductionStep.eliminate(
        family: DeductionFamily.higherOrderConfinement,
        cells: eliminated,
      );
    }
  }
  return null;
}

bool _rowHasPlacedToken(int size, CandidateGrid grid, int row) {
  for (int col = 0; col < size; col++) {
    if (grid.stateAt(Cell(row, col)) == CellState.placed) {
      return true;
    }
  }
  return false;
}

bool _columnHasPlacedToken(int size, CandidateGrid grid, int col) {
  for (int row = 0; row < size; row++) {
    if (grid.stateAt(Cell(row, col)) == CellState.placed) {
      return true;
    }
  }
  return false;
}

bool _regionHasPlacedToken(CandidateGrid grid, Region region) {
  for (final Cell cell in region.cells) {
    if (grid.stateAt(cell) == CellState.placed) {
      return true;
    }
  }
  return false;
}

Set<Cell> _candidateCells(int size, CandidateGrid grid) {
  final Set<Cell> cells = <Cell>{};
  for (int row = 0; row < size; row++) {
    cells.addAll(grid.candidatesInRow(row));
  }
  return cells;
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

List<Region> _regionsById(List<Region> regions) {
  return regions.toList(growable: false)
    ..sort((Region a, Region b) => a.id.compareTo(b.id));
}

List<int> _range(int size) {
  return <int>[for (int value = 0; value < size; value++) value];
}

List<int> _sortedInts(Iterable<int> values) {
  return values.toList(growable: false)..sort();
}

Iterable<List<T>> _combinations<T>(List<T> items, int length) sync* {
  if (length == 0) {
    yield <T>[];
    return;
  }
  if (length > items.length) {
    return;
  }
  for (int i = 0; i <= items.length - length; i++) {
    final T head = items[i];
    final List<T> tail = items.sublist(i + 1);
    for (final List<T> rest in _combinations(tail, length - 1)) {
      yield <T>[head, ...rest];
    }
  }
}
