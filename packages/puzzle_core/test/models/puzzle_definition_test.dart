import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

DifficultyMetadata _easyMetadata() {
  return DifficultyMetadata(
    band: Difficulty.easy,
    steps: 0,
    maxChainDepth: 0,
    families: <DeductionFamily>{DeductionFamily.giveawayCell},
    firstPlacementDepth: 0,
    minCandidateDensity: 1.0,
  );
}

void main() {
  group('PuzzleDefinition', () {
    test('buildQuadrantPuzzle constructs without assertion failure', () {
      final PuzzleDefinition puzzle = buildQuadrantPuzzle();
      expect(puzzle.size, 4);
      expect(puzzle.regions, hasLength(4));
      expect(puzzle.id, 'test_quadrant_0001');
    });

    test('regionContaining returns the right region for each solution cell',
        () {
      final PuzzleDefinition puzzle = buildQuadrantPuzzle();
      expect(puzzle.regionContaining(const Cell(0, 1)).id, 0);
      expect(puzzle.regionContaining(const Cell(1, 3)).id, 1);
      expect(puzzle.regionContaining(const Cell(2, 0)).id, 2);
      expect(puzzle.regionContaining(const Cell(3, 2)).id, 3);
    });

    test('regionContaining throws for out-of-grid cells', () {
      final PuzzleDefinition puzzle = buildQuadrantPuzzle();
      expect(
        () => puzzle.regionContaining(const Cell(99, 99)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('cellIsInGrid returns true for in-bound and false for out-of-bound',
        () {
      final PuzzleDefinition puzzle = buildQuadrantPuzzle();
      expect(puzzle.cellIsInGrid(const Cell(0, 0)), isTrue);
      expect(puzzle.cellIsInGrid(const Cell(3, 3)), isTrue);
      expect(puzzle.cellIsInGrid(const Cell(4, 0)), isFalse);
      expect(puzzle.cellIsInGrid(const Cell(0, 4)), isFalse);
    });

    test('rejects size below minimum', () {
      final Region r = Region(id: 0, cells: const <Cell>{Cell(0, 0)});
      expect(
        () => PuzzleDefinition(
          id: 'bad',
          schemaVersion: kPuzzleSchemaVersion,
          size: 1,
          regions: <Region>[r],
          solution: PuzzleSolution(const <Cell>[Cell(0, 0)]),
          difficulty: _easyMetadata(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects region count not equal to size', () {
      final Region r = Region(
        id: 0,
        cells: const <Cell>{Cell(0, 0), Cell(0, 1)},
      );
      expect(
        () => PuzzleDefinition(
          id: 'bad',
          schemaVersion: kPuzzleSchemaVersion,
          size: 4,
          regions: <Region>[r],
          solution: PuzzleSolution(
            const <Cell>[Cell(0, 0), Cell(1, 2), Cell(2, 0), Cell(3, 2)],
          ),
          difficulty: _easyMetadata(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects regions that do not partition the grid', () {
      // Leave (3, 3) uncovered by omitting it from r3.
      final Region r0 = Region(
        id: 0,
        cells: const <Cell>{Cell(0, 0), Cell(0, 1), Cell(1, 0), Cell(1, 1)},
      );
      final Region r1 = Region(
        id: 1,
        cells: const <Cell>{Cell(0, 2), Cell(0, 3), Cell(1, 2), Cell(1, 3)},
      );
      final Region r2 = Region(
        id: 2,
        cells: const <Cell>{Cell(2, 0), Cell(2, 1), Cell(3, 0), Cell(3, 1)},
      );
      final Region r3 = Region(
        id: 3,
        cells: const <Cell>{Cell(2, 2), Cell(2, 3), Cell(3, 2)},
      );
      expect(
        () => PuzzleDefinition(
          id: 'bad',
          schemaVersion: kPuzzleSchemaVersion,
          size: 4,
          regions: <Region>[r0, r1, r2, r3],
          solution: PuzzleSolution(
            const <Cell>[Cell(0, 1), Cell(1, 3), Cell(2, 0), Cell(3, 2)],
          ),
          difficulty: _easyMetadata(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects a solution that places two tokens in the same region', () {
      // R0 covers the entire top half (rows 0-1) — big enough to hold two
      // solution tokens. R3 has no solution token, violating "one token per
      // region".
      final Region r0 = Region(
        id: 0,
        cells: const <Cell>{
          Cell(0, 0),
          Cell(0, 1),
          Cell(0, 2),
          Cell(0, 3),
          Cell(1, 0),
          Cell(1, 1),
          Cell(1, 2),
          Cell(1, 3),
        },
      );
      final Region r1 = Region(
        id: 1,
        cells: const <Cell>{Cell(2, 0), Cell(2, 1), Cell(3, 0), Cell(3, 1)},
      );
      final Region r2 = Region(
        id: 2,
        cells: const <Cell>{Cell(2, 2), Cell(3, 2)},
      );
      final Region r3 = Region(
        id: 3,
        cells: const <Cell>{Cell(2, 3), Cell(3, 3)},
      );
      expect(
        () => PuzzleDefinition(
          id: 'bad',
          schemaVersion: kPuzzleSchemaVersion,
          size: 4,
          regions: <Region>[r0, r1, r2, r3],
          // (0,1) and (1,3) both land in r0; r3 is empty.
          solution: PuzzleSolution(
            const <Cell>[Cell(0, 1), Cell(1, 3), Cell(2, 0), Cell(3, 2)],
          ),
          difficulty: _easyMetadata(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects a solution whose tokens touch', () {
      final Region r0 = Region(
        id: 0,
        cells: const <Cell>{Cell(0, 0), Cell(0, 1), Cell(1, 0), Cell(1, 1)},
      );
      final Region r1 = Region(
        id: 1,
        cells: const <Cell>{Cell(0, 2), Cell(0, 3), Cell(1, 2), Cell(1, 3)},
      );
      final Region r2 = Region(
        id: 2,
        cells: const <Cell>{Cell(2, 0), Cell(2, 1), Cell(3, 0), Cell(3, 1)},
      );
      final Region r3 = Region(
        id: 3,
        cells: const <Cell>{Cell(2, 2), Cell(2, 3), Cell(3, 2), Cell(3, 3)},
      );
      expect(
        () => PuzzleDefinition(
          id: 'bad',
          schemaVersion: kPuzzleSchemaVersion,
          size: 4,
          regions: <Region>[r0, r1, r2, r3],
          // (0,1) and (1,2) are diagonally adjacent — touch violation.
          solution: PuzzleSolution(
            const <Cell>[Cell(0, 1), Cell(1, 2), Cell(2, 0), Cell(3, 3)],
          ),
          difficulty: _easyMetadata(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('equality is field-wise', () {
      expect(buildQuadrantPuzzle(), equals(buildQuadrantPuzzle()));
      expect(buildQuadrantPuzzle().hashCode, buildQuadrantPuzzle().hashCode);
    });

    test('regions list is unmodifiable', () {
      final PuzzleDefinition puzzle = buildQuadrantPuzzle();
      expect(
        () => puzzle.regions.add(
          Region(id: 99, cells: const <Cell>{Cell(0, 0)}),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
