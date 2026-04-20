import 'package:puzzle_core/puzzle_core.dart';

/// V1 generator grid size.
///
/// The product scope is fixed at 8 x 8 for launch, so generator stages keep
/// this as an explicit constant instead of pretending to support arbitrary
/// sizes before the rest of the pipeline can be calibrated for them.
const int kGeneratorGridSize = 8;

/// Default cap on Stage 1 search nodes for one placement.
///
/// Valid 8 x 8 placements are common, but a hard cap keeps corrupted future
/// changes from turning generation into an accidental infinite search.
const int kDefaultPlacementSearchNodeLimit = 1024;

/// Small deterministic RNG used by generator stages.
///
/// `dart:math.Random` is fine for local gameplay effects, but level packs need
/// a reproducibility contract that is owned by this tool. This linear
/// congruential generator is intentionally simple: it provides stable seeded
/// shuffling for offline generation, not cryptographic randomness.
final class GeneratorRng {
  /// Creates a deterministic RNG from [seed].
  ///
  /// The seed is normalized into an unsigned 32-bit state so negative CLI seeds
  /// still map to a stable sequence instead of being rejected inconsistently by
  /// different generator stages.
  GeneratorRng(int seed) : _state = seed & _uint32Mask;

  static const int _uint32Mask = 0xffffffff;
  static const int _multiplier = 1664525;
  static const int _increment = 1013904223;

  int _state;

  /// Returns a deterministic integer in `[0, maxExclusive)`.
  ///
  /// Throws [RangeError] when [maxExclusive] is not positive. Generator stages
  /// use this method for bounded choices so all randomness can be replayed from
  /// the pack seed.
  int nextInt(int maxExclusive) {
    RangeError.checkValueInInterval(maxExclusive, 1, 0x7fffffff);
    _state = (_multiplier * _state + _increment) & _uint32Mask;
    return _state % maxExclusive;
  }

  /// Shuffles [items] in place using this deterministic RNG.
  ///
  /// The implementation is Fisher-Yates so every Stage 1 row uses the same
  /// stable ordering logic, and future stages can reuse the method for frontier
  /// choices without pulling in another source of randomness.
  void shuffle<T>(List<T> items) {
    for (int index = items.length - 1; index > 0; index--) {
      final int swapIndex = nextInt(index + 1);
      final T value = items[index];
      items[index] = items[swapIndex];
      items[swapIndex] = value;
    }
  }
}

/// Generates valid Stage 1 solution placements for the V1 8 x 8 board.
///
/// Stage 1 owns only the hidden token arrangement: exactly one token per row,
/// exactly one per column, and no adjacent tokens. It deliberately does not
/// enforce long diagonal attacks because Skully Bones uses 1-star Star Battle
/// rules, not N-Queens rules. Later stages grow regions around this placement
/// and then run uniqueness and logic-solvability filters.
final class SolutionPlacementGenerator {
  /// Creates a placement generator with a bounded [searchNodeLimit].
  ///
  /// Each node is one candidate column considered during randomized
  /// backtracking. The default is intentionally generous for 8 x 8 generation;
  /// tests pass a tiny limit to verify exhaustion behavior.
  const SolutionPlacementGenerator({
    this.searchNodeLimit = kDefaultPlacementSearchNodeLimit,
  }) : assert(searchNodeLimit > 0, 'searchNodeLimit must be positive');

  /// Maximum number of candidate columns to consider before failing.
  final int searchNodeLimit;

  /// Produces one valid [PuzzleSolution] using [rng].
  ///
  /// The method performs randomized backtracking over column permutations.
  /// Since the row index is fixed by recursion, row and column uniqueness are
  /// guaranteed by construction; the only placement rule checked during search
  /// is the adjacent-row no-touch constraint.
  PuzzleSolution generate(GeneratorRng rng) {
    final List<int> columnsByRow = List<int>.filled(kGeneratorGridSize, -1);
    final Set<int> usedColumns = <int>{};
    var searchNodes = 0;

    bool search(int row) {
      if (row == kGeneratorGridSize) {
        return true;
      }

      final List<int> candidates = <int>[
        for (int col = 0; col < kGeneratorGridSize; col++)
          if (!usedColumns.contains(col)) col,
      ];
      rng.shuffle(candidates);

      for (final int col in candidates) {
        searchNodes += 1;
        if (searchNodes > searchNodeLimit) {
          throw PlacementGenerationException(
            'Stage 1 exceeded $searchNodeLimit placement search nodes.',
          );
        }
        if (!_canPlaceAfterPreviousRow(columnsByRow, row, col)) {
          continue;
        }

        columnsByRow[row] = col;
        usedColumns.add(col);
        if (search(row + 1)) {
          return true;
        }
        usedColumns.remove(col);
        columnsByRow[row] = -1;
      }

      return false;
    }

    if (!search(0)) {
      throw const PlacementGenerationException(
        'Stage 1 could not find a valid placement.',
      );
    }

    final PuzzleSolution solution = PuzzleSolution(<Cell>[
      for (int row = 0; row < kGeneratorGridSize; row++)
        Cell(row, columnsByRow[row]),
    ]);
    assert(isValidPlacement(solution), 'Stage 1 produced an invalid solution');
    return solution;
  }

  /// Validates [solution] against the Stage 1 placement contract.
  ///
  /// This method is intentionally narrower than full puzzle validation: it
  /// checks the token permutation and adjacent no-touch rule before regions
  /// exist. Long diagonals are accepted, which keeps the generator aligned with
  /// the project-wide non-N-Queens rule.
  bool isValidPlacement(PuzzleSolution solution) {
    if (solution.size != kGeneratorGridSize) {
      return false;
    }

    final Set<int> seenColumns = <int>{};
    for (int row = 0; row < kGeneratorGridSize; row++) {
      final Cell token = solution.tokenForRow(row);
      if (token.row != row ||
          token.col < 0 ||
          token.col >= kGeneratorGridSize ||
          !seenColumns.add(token.col)) {
        return false;
      }
      if (row > 0 &&
          (token.col - solution.tokenForRow(row - 1).col).abs() < 2) {
        return false;
      }
    }

    return true;
  }

  static bool _canPlaceAfterPreviousRow(
    List<int> columnsByRow,
    int row,
    int col,
  ) {
    return row == 0 || (col - columnsByRow[row - 1]).abs() >= 2;
  }
}

/// Indicates Stage 1 could not produce a valid placement within its budget.
///
/// The generator treats this as a rejected candidate attempt rather than a CLI
/// usage error. A caller may retry with the same RNG stream, a larger search
/// budget, or a new batch seed depending on which pipeline stage owns the
/// retry boundary.
final class PlacementGenerationException implements Exception {
  /// Creates an exception with a human-readable [message].
  const PlacementGenerationException(this.message);

  /// Explanation suitable for logs and test assertions.
  final String message;

  @override
  String toString() => message;
}
