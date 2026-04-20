import 'package:level_generator/level_generator.dart';
import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

const List<Cell> _goldenDiagonalPlacement = <Cell>[
  Cell(0, 0),
  Cell(1, 2),
  Cell(2, 4),
  Cell(3, 6),
  Cell(4, 1),
  Cell(5, 3),
  Cell(6, 5),
  Cell(7, 7),
];

void main() {
  group('PuzzleCandidateBuilder', () {
    const PuzzleCandidateBuilder builder = PuzzleCandidateBuilder();

    test('builds a structurally valid 8 x 8 candidate', () {
      final PuzzleDefinition candidate = builder.buildCandidate(
        index: 7,
        rng: GeneratorRng(42),
      );

      expect(candidate.id, 'candidate_000007');
      expect(candidate.size, kGeneratorGridSize);
      expect(candidate.solution.size, kGeneratorGridSize);
      expect(candidate.regions, hasLength(kGeneratorGridSize));
      expect(candidate.difficulty.families, isEmpty);
      for (final Region region in candidate.regions) {
        expect(region.isContiguous, isTrue);
        expect(
          candidate.solution.tokens.where(region.containsCell),
          hasLength(1),
        );
      }
    });

    test('replays identical candidates for the same seed and index', () {
      final PuzzleDefinition first = builder.buildCandidate(
        index: 1,
        rng: GeneratorRng(1234),
      );
      final PuzzleDefinition second = builder.buildCandidate(
        index: 1,
        rng: GeneratorRng(1234),
      );

      expect(first, second);
    });

    test('builds from the documented non-N-Queens golden placement', () {
      final PuzzleSolution solution = PuzzleSolution(_goldenDiagonalPlacement);

      final PuzzleDefinition candidate = builder.buildCandidateFromSolution(
        index: 99,
        solution: solution,
        rng: GeneratorRng(5678),
      );

      expect(candidate.solution, solution);
      expect(candidate.solution.tokenForRow(0), const Cell(0, 0));
      expect(candidate.solution.tokenForRow(7), const Cell(7, 7));
      for (final Region region in candidate.regions) {
        expect(
          candidate.solution.tokens.where(region.containsCell),
          hasLength(1),
        );
      }
    });

    test('rejects supplied placements that violate Stage 1 no-touch', () {
      final PuzzleSolution adjacent = PuzzleSolution(
        const <Cell>[
          Cell(0, 0),
          Cell(1, 1),
          Cell(2, 3),
          Cell(3, 5),
          Cell(4, 7),
          Cell(5, 2),
          Cell(6, 4),
          Cell(7, 6),
        ],
      );

      expect(
        () => builder.buildCandidateFromSolution(
          index: 1,
          solution: adjacent,
          rng: GeneratorRng(42),
        ),
        throwsA(isA<RegionGenerationException>()),
      );
    });
  });

  group('PuzzleUniquenessFilter', () {
    const PuzzleUniquenessFilter filter = PuzzleUniquenessFilter();

    test('accepts a puzzle with exactly one solution', () {
      final PuzzleUniquenessResult result = filter.evaluate(
        _buildCascadingGiveawayPuzzle(),
      );

      expect(result.solutionCount, 1);
      expect(result.isUnique, isTrue);
      expect(filter.accepts(_buildCascadingGiveawayPuzzle()), isTrue);
    });

    test('rejects a puzzle with multiple solutions', () {
      final PuzzleUniquenessResult result = filter.evaluate(
        _buildTwoSolutionRowStripPuzzle(),
      );

      expect(result.solutionCount, 2);
      expect(result.isUnique, isFalse);
      expect(filter.accepts(_buildTwoSolutionRowStripPuzzle()), isFalse);
    });
  });
}

PuzzleDefinition _buildCascadingGiveawayPuzzle() {
  return PuzzleDefinition(
    id: 'test_cascading_giveaway',
    schemaVersion: kPuzzleSchemaVersion,
    size: 4,
    regions: <Region>[
      Region(id: 0, cells: <Cell>{const Cell(0, 1)}),
      Region(
        id: 1,
        cells: <Cell>{
          const Cell(0, 2),
          const Cell(0, 3),
          const Cell(1, 2),
          const Cell(1, 3),
          const Cell(2, 3),
        },
      ),
      Region(
        id: 2,
        cells: <Cell>{
          const Cell(0, 0),
          const Cell(1, 0),
          const Cell(2, 0),
          const Cell(3, 0),
          const Cell(3, 1),
        },
      ),
      Region(
        id: 3,
        cells: <Cell>{
          const Cell(1, 1),
          const Cell(2, 1),
          const Cell(2, 2),
          const Cell(3, 2),
          const Cell(3, 3),
        },
      ),
    ],
    solution: PuzzleSolution(
      const <Cell>[Cell(0, 1), Cell(1, 3), Cell(2, 0), Cell(3, 2)],
    ),
    difficulty: _placeholderDifficulty(size: 4),
  );
}

PuzzleDefinition _buildTwoSolutionRowStripPuzzle() {
  return PuzzleDefinition(
    id: 'test_two_solution_row_strip',
    schemaVersion: kPuzzleSchemaVersion,
    size: 4,
    regions: <Region>[
      for (int row = 0; row < 4; row++)
        Region(
          id: row,
          cells: <Cell>{for (int col = 0; col < 4; col++) Cell(row, col)},
        ),
    ],
    solution: PuzzleSolution(
      const <Cell>[Cell(0, 1), Cell(1, 3), Cell(2, 0), Cell(3, 2)],
    ),
    difficulty: _placeholderDifficulty(size: 4),
  );
}

DifficultyMetadata _placeholderDifficulty({required int size}) {
  return DifficultyMetadata(
    band: Difficulty.easy,
    steps: 0,
    maxChainDepth: 0,
    families: <DeductionFamily>{},
    firstPlacementDepth: 0,
    minCandidateDensity: 1 / size,
  );
}
