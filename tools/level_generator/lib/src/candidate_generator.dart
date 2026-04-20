import 'package:puzzle_core/puzzle_core.dart';

import 'placement_generator.dart';
import 'region_generator.dart';

/// Prefix for internal generated-candidate ids.
///
/// These ids are stable for tests and logs, but they are not final player-facing
/// level ids. Stage 8 ordering/export will assign the shipped `level_0001`
/// style ids after verified puzzles are curated.
const String kGeneratedCandidateIdPrefix = 'candidate_';

/// Builds structurally valid puzzle candidates from Stage 1 and Stage 2.
///
/// A candidate is not yet a shippable level: it has a valid solution placement
/// and connected regions, but it may have zero solutions, multiple solutions,
/// or require guessing. Later pipeline stages apply uniqueness, logic-solving,
/// grading, deduplication, quota, and ordering.
final class PuzzleCandidateBuilder {
  /// Creates a candidate builder from pluggable Stage 1 and Stage 2 generators.
  ///
  /// The defaults are the production generator stages. Tests can still provide
  /// stricter Stage 2 bounds to exercise rejection paths without changing core
  /// puzzle rules.
  const PuzzleCandidateBuilder({
    this.placementGenerator = const SolutionPlacementGenerator(),
    this.regionGenerator = const RegionGrowthGenerator(),
  });

  /// Stage 1 solution-placement generator.
  final SolutionPlacementGenerator placementGenerator;

  /// Stage 2 connected-region generator.
  final RegionGrowthGenerator regionGenerator;

  /// Builds a candidate with generated placement and regions.
  ///
  /// [index] is used only for deterministic internal ids. [rng] supplies the
  /// shared deterministic randomness consumed first by Stage 1, then by Stage 2,
  /// so replaying a seed and index reproduces the same candidate.
  PuzzleDefinition buildCandidate({
    required int index,
    required GeneratorRng rng,
  }) {
    RangeError.checkNotNegative(index, 'index');
    final PuzzleSolution solution = placementGenerator.generate(rng);
    return buildCandidateFromSolution(
      index: index,
      solution: solution,
      rng: rng,
    );
  }

  /// Builds a candidate using a supplied Stage 1 [solution].
  ///
  /// This is useful for guardrail tests and future fixture mining where a
  /// placement is already known. Region growth still validates the placement
  /// against the Stage 1 contract before constructing the candidate.
  PuzzleDefinition buildCandidateFromSolution({
    required int index,
    required PuzzleSolution solution,
    required GeneratorRng rng,
  }) {
    RangeError.checkNotNegative(index, 'index');
    return PuzzleDefinition(
      id: _candidateId(index),
      schemaVersion: kPuzzleSchemaVersion,
      size: kGeneratorGridSize,
      regions: regionGenerator.generate(solution, rng),
      solution: solution,
      difficulty: _placeholderDifficulty(),
    );
  }
}

/// Stage 3 uniqueness filter for generated puzzle candidates.
///
/// This wrapper keeps generator code explicit about the Stage 3 accept/reject
/// contract while delegating the actual search to `puzzle_core`. A candidate is
/// accepted only when the solver reports exactly one solution.
final class PuzzleUniquenessFilter {
  /// Creates a uniqueness filter backed by [solver].
  ///
  /// The default is [StandardUniquenessSolver], which returns `2` as the
  /// early-exit value for "at least two solutions".
  const PuzzleUniquenessFilter({
    this.solver = const StandardUniquenessSolver(),
  });

  /// Solver used to count candidate solutions.
  final UniquenessSolver solver;

  /// Evaluates [puzzle] and returns the Stage 3 result.
  ///
  /// The result preserves the solver count so generator logs and tests can
  /// distinguish unsolvable candidates from multi-solution candidates.
  PuzzleUniquenessResult evaluate(PuzzleDefinition puzzle) {
    return PuzzleUniquenessResult(
      solutionCount: solver.countSolutions(puzzle),
    );
  }

  /// Returns `true` when [puzzle] has exactly one valid solution.
  ///
  /// This convenience method is the predicate the future pipeline will use to
  /// decide whether a generated candidate advances to logic-solvability checks.
  bool accepts(PuzzleDefinition puzzle) => evaluate(puzzle).isUnique;
}

/// Result of Stage 3 uniqueness evaluation.
///
/// [solutionCount] is `0`, `1`, or `2`, where `2` means "at least two" because
/// the solver exits as soon as a second solution is discovered.
final class PuzzleUniquenessResult {
  /// Creates a result from a bounded [solutionCount].
  const PuzzleUniquenessResult({required this.solutionCount})
      : assert(
          solutionCount >= 0 && solutionCount <= 2,
          'solutionCount must be 0, 1, or 2',
        );

  /// Number of solutions reported by the solver, capped at 2.
  final int solutionCount;

  /// Whether Stage 3 accepts the candidate.
  bool get isUnique => solutionCount == 1;
}

String _candidateId(int index) {
  return '$kGeneratedCandidateIdPrefix${index.toString().padLeft(6, '0')}';
}

DifficultyMetadata _placeholderDifficulty() {
  return DifficultyMetadata(
    band: Difficulty.easy,
    steps: 0,
    maxChainDepth: 0,
    families: <DeductionFamily>{},
    firstPlacementDepth: 0,
    minCandidateDensity: 1.0,
  );
}
