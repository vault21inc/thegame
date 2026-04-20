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
  group('RegionGrowthGenerator', () {
    const SolutionPlacementGenerator placementGenerator =
        SolutionPlacementGenerator();
    const RegionGrowthGenerator regionGenerator = RegionGrowthGenerator();

    test('grows deterministic regions for a placement and seed', () {
      final PuzzleSolution solution = placementGenerator.generate(
        GeneratorRng(42),
      );

      final List<Region> first = regionGenerator.generate(
        solution,
        GeneratorRng(99),
      );
      final List<Region> second = regionGenerator.generate(
        solution,
        GeneratorRng(99),
      );

      expect(first, second);
    });

    test('partitions the full 8 x 8 board without overlaps', () {
      final PuzzleSolution solution = placementGenerator.generate(
        GeneratorRng(42),
      );
      final List<Region> regions = regionGenerator.generate(
        solution,
        GeneratorRng(99),
      );

      final Set<Cell> covered = <Cell>{};
      for (final Region region in regions) {
        for (final Cell cell in region.cells) {
          expect(covered.add(cell), isTrue, reason: 'Duplicate cell $cell');
          expect(cell.row, inInclusiveRange(0, kGeneratorGridSize - 1));
          expect(cell.col, inInclusiveRange(0, kGeneratorGridSize - 1));
        }
      }

      expect(covered, hasLength(kGeneratorGridSize * kGeneratorGridSize));
      expect(
        covered,
        containsAll(<Cell>[
          for (int row = 0; row < kGeneratorGridSize; row++)
            for (int col = 0; col < kGeneratorGridSize; col++) Cell(row, col),
        ]),
      );
    });

    test('returns connected size-bounded regions with one token each', () {
      final PuzzleSolution solution = placementGenerator.generate(
        GeneratorRng(42),
      );
      final List<Region> regions = regionGenerator.generate(
        solution,
        GeneratorRng(99),
      );

      expect(regions, hasLength(kGeneratorGridSize));
      for (final Region region in regions) {
        expect(region.id, inInclusiveRange(0, kGeneratorGridSize - 1));
        expect(region.isContiguous, isTrue);
        expect(
          region.cells.length,
          inInclusiveRange(kMinGeneratedRegionSize, kMaxGeneratedRegionSize),
        );
        expect(
          solution.tokens.where(region.containsCell),
          hasLength(1),
          reason: 'Region ${region.id} should own exactly one solution token.',
        );
      }
    });

    test('builds a PuzzleDefinition from generated regions', () {
      final PuzzleSolution solution = placementGenerator.generate(
        GeneratorRng(42),
      );
      final List<Region> regions = regionGenerator.generate(
        solution,
        GeneratorRng(99),
      );

      final PuzzleDefinition puzzle = PuzzleDefinition(
        id: 'generated_stage_2_smoke',
        schemaVersion: kPuzzleSchemaVersion,
        size: kGeneratorGridSize,
        regions: regions,
        solution: solution,
        difficulty: DifficultyMetadata(
          band: Difficulty.easy,
          steps: 0,
          maxChainDepth: 0,
          families: <DeductionFamily>{DeductionFamily.giveawayCell},
          firstPlacementDepth: 0,
          minCandidateDensity: 1.0,
        ),
      );

      expect(puzzle.regions, regions);
      expect(puzzle.solution, solution);
    });

    test('accepts the documented non-N-Queens golden placement', () {
      final PuzzleSolution solution = PuzzleSolution(_goldenDiagonalPlacement);
      final List<Region> regions = regionGenerator.generate(
        solution,
        GeneratorRng(123),
      );

      expect(regions, hasLength(kGeneratorGridSize));
      for (final Region region in regions) {
        expect(solution.tokens.where(region.containsCell), hasLength(1));
      }
    });

    test('rejects invalid Stage 1 placements', () {
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
        () => regionGenerator.generate(adjacent, GeneratorRng(99)),
        throwsA(isA<RegionGenerationException>()),
      );
    });

    test('throws when size-quality bounds cannot be satisfied', () {
      final PuzzleSolution solution = placementGenerator.generate(
        GeneratorRng(42),
      );
      const RegionGrowthGenerator impossibleBounds = RegionGrowthGenerator(
        maxAttempts: 3,
        minRegionSize: 9,
        maxRegionSize: 9,
      );

      expect(
        () => impossibleBounds.generate(solution, GeneratorRng(99)),
        throwsA(isA<RegionGenerationException>()),
      );
    });
  });
}
