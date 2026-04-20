import 'package:puzzle_core/puzzle_core.dart';

import 'placement_generator.dart';

/// Minimum generated region size accepted by the V1 shape-quality heuristic.
///
/// The core rules allow smaller regions, but generated launch content rejects
/// tiny islands so puzzles have enough candidate structure for deductions.
const int kMinGeneratedRegionSize = 3;

/// Maximum generated region size accepted by the V1 shape-quality heuristic.
///
/// Oversized regions tend to create bland boards and poor deduction variety,
/// so Stage 2 retries layouts that grow beyond this cap.
const int kMaxGeneratedRegionSize = 15;

/// Default number of Stage 2 attempts for one solution placement.
///
/// A failed attempt discards only the grown regions, not the Stage 1 placement.
/// The default is intentionally modest because 8 x 8 flood-fill attempts are
/// cheap and later pipeline stages own the larger candidate retry budget.
const int kDefaultRegionGrowthAttempts = 32;

/// Grows connected V1 regions from a valid solution placement.
///
/// Stage 2 starts each region at one solution token, then uses randomized
/// competitive flood-fill to assign every remaining cell. Region ownership is
/// deterministic for a given [GeneratorRng] stream. The generated layout is
/// accepted only when all regions satisfy the documented size-quality bounds;
/// uniqueness and logic-solvability are deliberately left to later stages.
final class RegionGrowthGenerator {
  /// Creates a generator with retry and size-quality settings.
  ///
  /// [maxAttempts] is the number of flood-fill layouts to try for one
  /// placement. [minRegionSize] and [maxRegionSize] are hard quality bounds
  /// for generated content, not core puzzle-rule constraints.
  const RegionGrowthGenerator({
    this.maxAttempts = kDefaultRegionGrowthAttempts,
    this.minRegionSize = kMinGeneratedRegionSize,
    this.maxRegionSize = kMaxGeneratedRegionSize,
  })  : assert(maxAttempts > 0, 'maxAttempts must be positive'),
        assert(minRegionSize > 0, 'minRegionSize must be positive'),
        assert(
          maxRegionSize >= minRegionSize,
          'maxRegionSize must be >= minRegionSize',
        );

  /// Maximum flood-fill layouts to try for one placement.
  final int maxAttempts;

  /// Minimum accepted cell count for any generated region.
  final int minRegionSize;

  /// Maximum accepted cell count for any generated region.
  final int maxRegionSize;

  /// Generates connected regions for [solution] using [rng].
  ///
  /// The [solution] must satisfy the Stage 1 placement contract. The returned
  /// list is ordered by region id, where region `i` is seeded by the token in
  /// row `i`; therefore every region contains exactly one solution token.
  /// Throws [RegionGenerationException] if no size-valid layout is found within
  /// [maxAttempts].
  List<Region> generate(PuzzleSolution solution, GeneratorRng rng) {
    if (!const SolutionPlacementGenerator().isValidPlacement(solution)) {
      throw const RegionGenerationException(
        'Stage 2 requires a valid V1 solution placement.',
      );
    }

    RegionGenerationException? lastFailure;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final List<Region> regions = _growOnce(solution, rng);
        if (_satisfiesSizeBounds(regions)) {
          return regions;
        }
        lastFailure = const RegionGenerationException(
          'Stage 2 rejected layout outside generated region size bounds.',
        );
      } on RegionGenerationException catch (error) {
        lastFailure = error;
      }
    }

    throw RegionGenerationException(
      'Stage 2 could not grow size-valid regions after $maxAttempts attempts. '
              '${lastFailure?.message ?? ''}'
          .trim(),
    );
  }

  List<Region> _growOnce(PuzzleSolution solution, GeneratorRng rng) {
    final List<Set<Cell>> cellsByRegion = <Set<Cell>>[
      for (int id = 0; id < kGeneratorGridSize; id++)
        <Cell>{solution.tokenForRow(id)},
    ];
    final Map<Cell, int> ownerByCell = <Cell, int>{
      for (int id = 0; id < kGeneratorGridSize; id++)
        solution.tokenForRow(id): id,
    };

    while (ownerByCell.length < kGeneratorGridSize * kGeneratorGridSize) {
      final List<Set<Cell>> frontiers = _buildFrontiers(
        cellsByRegion,
        ownerByCell,
      );
      final List<int> expandableRegionIds = <int>[
        for (int id = 0; id < kGeneratorGridSize; id++)
          if (frontiers[id].isNotEmpty &&
              cellsByRegion[id].length < maxRegionSize)
            id,
      ];
      if (expandableRegionIds.isEmpty) {
        throw const RegionGenerationException(
          'Stage 2 frontier exhausted before all cells were assigned.',
        );
      }

      final int regionId = _chooseRegionId(
        expandableRegionIds,
        cellsByRegion,
        rng,
      );
      final Cell cell = _chooseCell(frontiers[regionId], rng);
      ownerByCell[cell] = regionId;
      cellsByRegion[regionId].add(cell);
    }

    return <Region>[
      for (int id = 0; id < kGeneratorGridSize; id++)
        Region(id: id, cells: cellsByRegion[id]),
    ];
  }

  List<Set<Cell>> _buildFrontiers(
    List<Set<Cell>> cellsByRegion,
    Map<Cell, int> ownerByCell,
  ) {
    return <Set<Cell>>[
      for (int id = 0; id < kGeneratorGridSize; id++)
        <Cell>{
          for (final Cell cell in cellsByRegion[id])
            for (final Cell neighbor in _orthogonalNeighbors(cell))
              if (!ownerByCell.containsKey(neighbor)) neighbor,
        },
    ];
  }

  int _chooseRegionId(
    List<int> regionIds,
    List<Set<Cell>> cellsByRegion,
    GeneratorRng rng,
  ) {
    final List<int> sortedRegionIds = regionIds.toList(growable: false)..sort();
    var totalWeight = 0;
    final List<int> weights = <int>[];
    for (final int id in sortedRegionIds) {
      final int distanceFromCap = maxRegionSize - cellsByRegion[id].length + 1;
      final int weight = distanceFromCap > 0 ? distanceFromCap : 1;
      weights.add(weight);
      totalWeight += weight;
    }

    var pick = rng.nextInt(totalWeight);
    for (int index = 0; index < sortedRegionIds.length; index++) {
      pick -= weights[index];
      if (pick < 0) {
        return sortedRegionIds[index];
      }
    }
    return sortedRegionIds.last;
  }

  Cell _chooseCell(Set<Cell> frontier, GeneratorRng rng) {
    final List<Cell> cells = frontier.toList(growable: false)
      ..sort(_compareCells);
    return cells[rng.nextInt(cells.length)];
  }

  bool _satisfiesSizeBounds(List<Region> regions) {
    for (final Region region in regions) {
      if (region.cells.length < minRegionSize ||
          region.cells.length > maxRegionSize) {
        return false;
      }
    }
    return true;
  }
}

/// Indicates Stage 2 could not grow an acceptable connected region layout.
///
/// This is a candidate-generation failure, not a command-line usage error.
/// The caller may retry Stage 2 with the same placement until its configured
/// attempt budget is exhausted, then advance to another candidate placement.
final class RegionGenerationException implements Exception {
  /// Creates an exception with a human-readable [message].
  const RegionGenerationException(this.message);

  /// Explanation suitable for logs and tests.
  final String message;

  @override
  String toString() => message;
}

Iterable<Cell> _orthogonalNeighbors(Cell cell) sync* {
  if (cell.row > 0) {
    yield Cell(cell.row - 1, cell.col);
  }
  if (cell.row < kGeneratorGridSize - 1) {
    yield Cell(cell.row + 1, cell.col);
  }
  if (cell.col > 0) {
    yield Cell(cell.row, cell.col - 1);
  }
  if (cell.col < kGeneratorGridSize - 1) {
    yield Cell(cell.row, cell.col + 1);
  }
}

int _compareCells(Cell a, Cell b) {
  final int rowCompare = a.row.compareTo(b.row);
  if (rowCompare != 0) {
    return rowCompare;
  }
  return a.col.compareTo(b.col);
}
