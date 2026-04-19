import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  final PuzzleDefinition puzzle = buildQuadrantPuzzle();
  const SolutionValidator validator = SolutionValidator.standard();

  group('SolutionValidator', () {
    test('returns true for every stored solution cell', () {
      for (final Cell token in puzzle.solution.tokens) {
        expect(
          validator.isSolutionCell(puzzle, token),
          isTrue,
          reason: 'Expected $token to be a solution cell',
        );
      }
    });

    test('returns false for cells in the wrong column of a solution row', () {
      // Row 0's solution is (0, 1); any other column is wrong.
      expect(validator.isSolutionCell(puzzle, const Cell(0, 0)), isFalse);
      expect(validator.isSolutionCell(puzzle, const Cell(0, 2)), isFalse);
      expect(validator.isSolutionCell(puzzle, const Cell(0, 3)), isFalse);
    });

    test('returns false for cells outside the grid', () {
      expect(validator.isSolutionCell(puzzle, const Cell(99, 99)), isFalse);
      expect(validator.isSolutionCell(puzzle, const Cell(4, 0)), isFalse);
    });
  });
}
