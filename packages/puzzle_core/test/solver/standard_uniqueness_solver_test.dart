import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

import 'solver_test_puzzles.dart';

void main() {
  group('StandardUniquenessSolver', () {
    test('counts exactly one solution for the cascading giveaway puzzle', () {
      final PuzzleDefinition puzzle = buildCascadingGiveawayPuzzle();

      expect(const StandardUniquenessSolver().countSolutions(puzzle), 1);
    });

    test('reports at least two solutions with early-exit value', () {
      final PuzzleDefinition puzzle = buildTwoSolutionRowStripPuzzle();

      expect(const StandardUniquenessSolver().countSolutions(puzzle), 2);
    });
  });
}
