import '../models/cell.dart';
import '../models/puzzle_definition.dart';
import '../models/region.dart';
import 'candidate_grid.dart';
import 'cell_ordering.dart';
import 'cell_state.dart';

/// Concrete mutable candidate grid for solver and deduction tests.
///
/// The grid owns only runtime cell state. Region topology is supplied at
/// construction so deduction families can query row, column, and region
/// candidate sets without depending on Flutter or on generator-only types.
/// Placement housekeeping intentionally remains outside this class because the
/// logic solver needs to attribute those candidate removals to the placement
/// that caused them.
final class StandardCandidateGrid implements CandidateGrid {
  /// Builds a candidate grid from a region partition and optional starting
  /// states.
  ///
  /// [size] and [regions] define the board topology. Every cell starts as a
  /// candidate, then [initialEliminations] and [initialPlacements] are applied.
  /// The constructor throws [ArgumentError] if the topology is not a complete
  /// partition or if an initial state references an out-of-bounds cell.
  StandardCandidateGrid({
    required this.size,
    required List<Region> regions,
    Set<Cell> initialEliminations = const <Cell>{},
    Set<Cell> initialPlacements = const <Cell>{},
  })  : _regionsById = _indexRegions(regions),
        _cellToRegionId = _buildCellToRegionId(size, regions),
        _states = <Cell, CellState>{} {
    _validatePartition(size, regions, _cellToRegionId);
    _initializeStates();
    _applyInitialStates(initialEliminations, initialPlacements);
  }

  /// Builds a fresh all-candidate grid for [puzzle].
  ///
  /// This is the production entry point used by [LogicSolver] implementations
  /// because a [PuzzleDefinition] already guarantees a valid region partition.
  factory StandardCandidateGrid.fromPuzzle(PuzzleDefinition puzzle) {
    return StandardCandidateGrid(size: puzzle.size, regions: puzzle.regions);
  }

  @override
  final int size;

  final Map<int, Region> _regionsById;
  final Map<Cell, int> _cellToRegionId;
  final Map<Cell, CellState> _states;

  /// Number of cells still available as candidates.
  int get candidateCount => candidateCells.length;

  /// All remaining candidates in row-major order.
  Set<Cell> get candidateCells {
    final Set<Cell> cells = <Cell>{};
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        final Cell cell = Cell(row, col);
        if (_states[cell] == CellState.candidate) {
          cells.add(cell);
        }
      }
    }
    return Set<Cell>.unmodifiable(cells);
  }

  /// All placed tokens in row-major order.
  Set<Cell> get placedCells {
    final Set<Cell> cells = <Cell>{};
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        final Cell cell = Cell(row, col);
        if (_states[cell] == CellState.placed) {
          cells.add(cell);
        }
      }
    }
    return Set<Cell>.unmodifiable(cells);
  }

  /// Returns the region id containing [cell].
  ///
  /// Throws [ArgumentError] if [cell] is outside this grid.
  int regionIdAt(Cell cell) {
    _checkCellInGrid(cell);
    return _cellToRegionId[cell]!;
  }

  @override
  CellState stateAt(Cell cell) {
    _checkCellInGrid(cell);
    return _states[cell]!;
  }

  @override
  Set<Cell> candidatesInRow(int row) {
    _checkAxis(row, 'row');
    final Set<Cell> cells = <Cell>{};
    for (int col = 0; col < size; col++) {
      final Cell cell = Cell(row, col);
      if (_states[cell] == CellState.candidate) {
        cells.add(cell);
      }
    }
    return Set<Cell>.unmodifiable(cells);
  }

  @override
  Set<Cell> candidatesInColumn(int col) {
    _checkAxis(col, 'col');
    final Set<Cell> cells = <Cell>{};
    for (int row = 0; row < size; row++) {
      final Cell cell = Cell(row, col);
      if (_states[cell] == CellState.candidate) {
        cells.add(cell);
      }
    }
    return Set<Cell>.unmodifiable(cells);
  }

  @override
  Set<Cell> candidatesInRegion(int regionId) {
    final Region? region = _regionsById[regionId];
    if (region == null) {
      throw ArgumentError.value(regionId, 'regionId', 'Unknown region id');
    }
    final List<Cell> sorted = sortCellsRowMajor(region.cells);
    final Set<Cell> cells = <Cell>{};
    for (final Cell cell in sorted) {
      if (_states[cell] == CellState.candidate) {
        cells.add(cell);
      }
    }
    return Set<Cell>.unmodifiable(cells);
  }

  @override
  void eliminate(Cell cell) {
    _checkCellInGrid(cell);
    switch (_states[cell]!) {
      case CellState.candidate:
        _states[cell] = CellState.eliminated;
      case CellState.eliminated:
        return;
      case CellState.placed:
        throw StateError('Cannot eliminate placed cell $cell');
    }
  }

  @override
  void place(Cell cell) {
    _checkCellInGrid(cell);
    switch (_states[cell]!) {
      case CellState.candidate:
        _states[cell] = CellState.placed;
      case CellState.placed:
        return;
      case CellState.eliminated:
        throw StateError('Cannot place eliminated cell $cell');
    }
  }

  void _initializeStates() {
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        _states[Cell(row, col)] = CellState.candidate;
      }
    }
  }

  void _applyInitialStates(
    Set<Cell> initialEliminations,
    Set<Cell> initialPlacements,
  ) {
    final Set<Cell> overlap = initialEliminations.intersection(
      initialPlacements,
    );
    if (overlap.isNotEmpty) {
      throw ArgumentError.value(
        overlap,
        'initialPlacements',
        'Initial cells cannot be both eliminated and placed',
      );
    }
    for (final Cell cell in initialEliminations) {
      eliminate(cell);
    }
    for (final Cell cell in initialPlacements) {
      place(cell);
    }
  }

  void _checkCellInGrid(Cell cell) {
    if (cell.row < 0 || cell.row >= size || cell.col < 0 || cell.col >= size) {
      throw ArgumentError.value(cell, 'cell', 'Cell is outside $size x $size');
    }
  }

  void _checkAxis(int value, String name) {
    if (value < 0 || value >= size) {
      throw ArgumentError.value(value, name, 'Axis is outside $size x $size');
    }
  }
}

Map<int, Region> _indexRegions(List<Region> regions) {
  final Map<int, Region> byId = <int, Region>{};
  for (final Region region in regions) {
    final Region? previous = byId[region.id];
    if (previous != null) {
      throw ArgumentError.value(
        region.id,
        'regions',
        'Duplicate region id ${region.id}',
      );
    }
    byId[region.id] = region;
  }
  return Map<int, Region>.unmodifiable(byId);
}

Map<Cell, int> _buildCellToRegionId(int size, List<Region> regions) {
  final Map<Cell, int> cellToRegionId = <Cell, int>{};
  for (final Region region in regions) {
    for (final Cell cell in region.cells) {
      if (cell.row < 0 ||
          cell.row >= size ||
          cell.col < 0 ||
          cell.col >= size) {
        throw ArgumentError.value(
          cell,
          'regions',
          'Region ${region.id} contains an out-of-bounds cell',
        );
      }
      final int? existing = cellToRegionId[cell];
      if (existing != null) {
        throw ArgumentError.value(
          cell,
          'regions',
          'Cell appears in both region $existing and ${region.id}',
        );
      }
      cellToRegionId[cell] = region.id;
    }
  }
  return Map<Cell, int>.unmodifiable(cellToRegionId);
}

void _validatePartition(
  int size,
  List<Region> regions,
  Map<Cell, int> cellToRegionId,
) {
  if (size <= 0) {
    throw ArgumentError.value(size, 'size', 'Grid size must be positive');
  }
  if (regions.isEmpty) {
    throw ArgumentError.value(regions, 'regions', 'Regions cannot be empty');
  }
  final int expectedCells = size * size;
  if (cellToRegionId.length != expectedCells) {
    throw ArgumentError.value(
      regions,
      'regions',
      'Regions cover ${cellToRegionId.length} cells; expected $expectedCells',
    );
  }
}
