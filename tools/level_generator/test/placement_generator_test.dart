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
  group('GeneratorRng', () {
    test('replays the same bounded sequence for a seed', () {
      final GeneratorRng first = GeneratorRng(20260419);
      final GeneratorRng second = GeneratorRng(20260419);

      expect(
        <int>[for (int i = 0; i < 12; i++) first.nextInt(1000)],
        <int>[for (int i = 0; i < 12; i++) second.nextInt(1000)],
      );
    });

    test('normalizes negative seeds into deterministic sequences', () {
      final GeneratorRng negativeSeed = GeneratorRng(-1);
      final GeneratorRng normalizedSeed = GeneratorRng(0xffffffff);

      expect(
        <int>[for (int i = 0; i < 8; i++) negativeSeed.nextInt(100)],
        <int>[for (int i = 0; i < 8; i++) normalizedSeed.nextInt(100)],
      );
    });
  });

  group('SolutionPlacementGenerator', () {
    const SolutionPlacementGenerator generator = SolutionPlacementGenerator();

    test('generates deterministic placements for a seed', () {
      final PuzzleSolution first = generator.generate(GeneratorRng(42));
      final PuzzleSolution second = generator.generate(GeneratorRng(42));

      expect(first, second);
      expect(generator.isValidPlacement(first), isTrue);
    });

    test('generates valid placements across representative seeds', () {
      for (final int seed in <int>[0, 1, 2, 7, 42, 99, 20260419]) {
        final PuzzleSolution solution = generator.generate(GeneratorRng(seed));

        expect(
          generator.isValidPlacement(solution),
          isTrue,
          reason: 'Seed $seed produced $solution',
        );
        expect(
          solution.tokens.map((Cell cell) => cell.row),
          orderedEquals(
            <int>[0, 1, 2, 3, 4, 5, 6, 7],
          ),
        );
        expect(
          solution.tokens.map((Cell cell) => cell.col).toSet(),
          hasLength(8),
        );
      }
    });

    test('accepts the documented non-N-Queens golden placement', () {
      final PuzzleSolution golden = PuzzleSolution(_goldenDiagonalPlacement);

      expect(golden.tokenForRow(0), const Cell(0, 0));
      expect(golden.tokenForRow(7), const Cell(7, 7));
      expect(
        golden.tokenForRow(0).row - golden.tokenForRow(0).col,
        golden.tokenForRow(7).row - golden.tokenForRow(7).col,
        reason: 'The guardrail must exercise a long shared diagonal.',
      );
      expect(generator.isValidPlacement(golden), isTrue);
    });

    test('rejects adjacent placements without rejecting long diagonals', () {
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

      expect(generator.isValidPlacement(adjacent), isFalse);
    });

    test('throws when the search-node budget is exhausted', () {
      const SolutionPlacementGenerator tinyBudget =
          SolutionPlacementGenerator(searchNodeLimit: 1);

      expect(
        () => tinyBudget.generate(GeneratorRng(42)),
        throwsA(isA<PlacementGenerationException>()),
      );
    });
  });
}
