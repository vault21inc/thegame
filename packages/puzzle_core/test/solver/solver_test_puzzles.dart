import 'package:puzzle_core/puzzle_core.dart';

/// Builds a 4x4 puzzle solved entirely by cascading Family 1 placements.
///
/// The singleton first region forces `(0,1)`. Placement housekeeping then
/// leaves one candidate in each following row, producing the solution
/// `[1, 3, 0, 2]` without needing any non-giveaway family.
PuzzleDefinition buildCascadingGiveawayPuzzle() {
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
    difficulty: DifficultyMetadata(
      band: Difficulty.easy,
      steps: 4,
      maxChainDepth: 0,
      families: <DeductionFamily>{DeductionFamily.giveawayCell},
      firstPlacementDepth: 0,
      minCandidateDensity: 0.0,
    ),
  );
}

/// Builds a 4x4 row-strip puzzle with the two classic non-touch permutations.
///
/// The solver returns `2` for this fixture to mean "at least two", proving the
/// uniqueness counter exits early once a second solution is known.
PuzzleDefinition buildTwoSolutionRowStripPuzzle() {
  final List<Region> regions = <Region>[
    for (int row = 0; row < 4; row++)
      Region(
        id: row,
        cells: <Cell>{for (int col = 0; col < 4; col++) Cell(row, col)},
      ),
  ];

  return PuzzleDefinition(
    id: 'test_two_solution_row_strip',
    schemaVersion: kPuzzleSchemaVersion,
    size: 4,
    regions: regions,
    solution: PuzzleSolution(
      const <Cell>[Cell(0, 1), Cell(1, 3), Cell(2, 0), Cell(3, 2)],
    ),
    difficulty: DifficultyMetadata(
      band: Difficulty.easy,
      steps: 0,
      maxChainDepth: 0,
      families: <DeductionFamily>{DeductionFamily.giveawayCell},
      firstPlacementDepth: 0,
      minCandidateDensity: 1.0,
    ),
  );
}
