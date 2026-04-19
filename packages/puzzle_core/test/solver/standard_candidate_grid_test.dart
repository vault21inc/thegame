import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

import '../deduction_scenarios/fixture_layouts.dart';

void main() {
  group('StandardCandidateGrid', () {
    test('starts every partition cell as a candidate', () {
      final StandardCandidateGrid grid = StandardCandidateGrid(
        size: 4,
        regions: quadrants4x4(),
      );

      expect(grid.candidateCount, 16);
      expect(grid.candidatesInRow(0), hasLength(4));
      expect(grid.candidatesInColumn(0), hasLength(4));
      expect(grid.candidatesInRegion(0), hasLength(4));
      expect(grid.stateAt(const Cell(0, 0)), CellState.candidate);
    });

    test('applies initial eliminations and placements', () {
      final StandardCandidateGrid grid = StandardCandidateGrid(
        size: 4,
        regions: quadrants4x4(),
        initialEliminations: <Cell>{const Cell(0, 0)},
        initialPlacements: <Cell>{const Cell(1, 1)},
      );

      expect(grid.stateAt(const Cell(0, 0)), CellState.eliminated);
      expect(grid.stateAt(const Cell(1, 1)), CellState.placed);
      expect(grid.candidateCount, 14);
      expect(grid.placedCells, <Cell>{const Cell(1, 1)});
    });

    test('rejects illegal state transitions', () {
      final StandardCandidateGrid grid = StandardCandidateGrid(
        size: 4,
        regions: quadrants4x4(),
      );

      grid.place(const Cell(0, 0));
      expect(
        () => grid.eliminate(const Cell(0, 0)),
        throwsA(isA<StateError>()),
      );

      grid.eliminate(const Cell(0, 1));
      expect(
        () => grid.place(const Cell(0, 1)),
        throwsA(isA<StateError>()),
      );
    });
  });
}
