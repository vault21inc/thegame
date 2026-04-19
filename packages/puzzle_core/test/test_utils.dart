import 'package:puzzle_core/puzzle_core.dart';

/// The golden non-N-Queens placement σ = [0, 2, 4, 6, 1, 3, 5, 7] per
/// [docs/level-generation.md §Stage 1 — Non-N-Queens guardrail].
///
/// Tokens are at `(i, σ[i])` for i in 0..7. Two tokens — `(0,0)` and `(7,7)` —
/// share the main diagonal (`row - col == 0`), so a classic N-Queens diagonal
/// check would reject this placement. Under Star Battle adjacency rules it is
/// valid because every adjacent-row column delta is at least 2.
const List<Cell> kGoldenPlacement = <Cell>[
  Cell(0, 0),
  Cell(1, 2),
  Cell(2, 4),
  Cell(3, 6),
  Cell(4, 1),
  Cell(5, 3),
  Cell(6, 5),
  Cell(7, 7),
];

/// Builds an 8x8 [PuzzleDefinition] whose solution is [kGoldenPlacement] and
/// whose regions are eight row-strips — region `i` is row `i`.
///
/// The row-strip layout trivially satisfies the PuzzleDefinition invariants
/// (contiguous regions, disjoint partition covering the full grid, one token
/// per region) without needing a hand-crafted irregular layout. Its purpose
/// is to exercise the non-N-Queens guardrail, not to exercise uniqueness.
PuzzleDefinition buildGoldenRowStripPuzzle() {
  final List<Region> regions = <Region>[
    for (int row = 0; row < 8; row++)
      Region(
        id: row,
        cells: <Cell>{for (int col = 0; col < 8; col++) Cell(row, col)},
      ),
  ];

  return PuzzleDefinition(
    id: 'test_golden_row_strip',
    schemaVersion: kPuzzleSchemaVersion,
    size: 8,
    regions: regions,
    solution: PuzzleSolution(kGoldenPlacement),
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

/// Builds a simple valid 4x4 [PuzzleDefinition] used across multiple tests.
///
/// Regions are the four 2x2 quadrants. Solution cells are `(0,1)`, `(1,3)`,
/// `(2,0)`, `(3,2)` — one per quadrant, adjacent-row column deltas are 2, 2,
/// 2, satisfying the no-touch rule.
///
/// The puzzle intentionally has multiple valid solutions; it is not meant
/// to exercise uniqueness. It exists to exercise the structural invariants
/// of [PuzzleDefinition] and the validators.
PuzzleDefinition buildQuadrantPuzzle() {
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

  return PuzzleDefinition(
    id: 'test_quadrant_0001',
    schemaVersion: kPuzzleSchemaVersion,
    size: 4,
    regions: <Region>[r0, r1, r2, r3],
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
