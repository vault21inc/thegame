import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  final PuzzleDefinition puzzle = buildQuadrantPuzzle();
  const PlacementValidator validator = PlacementValidator.standard();

  group('PlacementValidator', () {
    test('accepts the stored solution as valid', () {
      final PlacementValidationResult result =
          validator.validate(puzzle, puzzle.solution.tokens);
      expect(result.isValid, isTrue);
      expect(result.violations, isEmpty);
    });

    test('reports DuplicateRow when two tokens share a row', () {
      final PlacementValidationResult result = validator.validate(
        puzzle,
        const <Cell>[Cell(0, 1), Cell(0, 3)],
      );
      expect(result.violations, contains(const DuplicateRow(0)));
    });

    test('reports DuplicateColumn when two tokens share a column', () {
      final PlacementValidationResult result = validator.validate(
        puzzle,
        const <Cell>[Cell(0, 1), Cell(3, 1)],
      );
      expect(result.violations, contains(const DuplicateColumn(1)));
    });

    test('reports DuplicateRegion when two tokens share a region', () {
      // Both in r0; they are also adjacent, so AdjacentTokens fires too.
      final PlacementValidationResult result = validator.validate(
        puzzle,
        const <Cell>[Cell(0, 0), Cell(1, 1)],
      );
      expect(result.violations, contains(const DuplicateRegion(0)));
    });

    test('reports AdjacentTokens when two tokens touch diagonally', () {
      // (1, 2) is in r1, (2, 1) is in r2 — diagonally adjacent, different
      // rows / columns / regions.
      final PlacementValidationResult result = validator.validate(
        puzzle,
        const <Cell>[Cell(1, 2), Cell(2, 1)],
      );
      expect(
        result.violations,
        contains(AdjacentTokens(const Cell(1, 2), const Cell(2, 1))),
      );
      expect(
        result.violations,
        isNot(contains(const DuplicateRow(1))),
        reason: 'rows differ — no DuplicateRow expected',
      );
      expect(
        result.violations,
        isNot(contains(const DuplicateColumn(2))),
        reason: 'columns differ — no DuplicateColumn expected',
      );
    });

    test('reports OutOfBoundsToken for cells outside the grid', () {
      final PlacementValidationResult result = validator.validate(
        puzzle,
        const <Cell>[Cell(0, 1), Cell(99, 99)],
      );
      expect(
        result.violations,
        contains(const OutOfBoundsToken(Cell(99, 99))),
      );
    });

    test('treats duplicate input cells as a single token', () {
      // Two identical cells should not produce any duplicate violations.
      final PlacementValidationResult result = validator.validate(
        puzzle,
        const <Cell>[Cell(0, 1), Cell(0, 1)],
      );
      expect(result.violations, isEmpty);
    });

    test('violations list is unmodifiable', () {
      final PlacementValidationResult result =
          validator.validate(puzzle, <Cell>[const Cell(0, 0), const Cell(0, 1)]);
      expect(
        () => result.violations.add(const DuplicateRow(99)),
        throwsUnsupportedError,
      );
    });
  });
}
