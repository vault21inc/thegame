import 'package:puzzle_core/puzzle_core.dart';

/// Reusable region layouts for deduction scenarios.
///
/// Each layout produces a valid partition of a square grid. They are small
/// (3x3–5x5) so the setup of each scenario is auditable by hand.

/// 3x3 row-strip layout: region `i` is row `i` (3 cells each).
List<Region> rowStrips3x3() {
  return <Region>[
    for (int row = 0; row < 3; row++)
      Region(
        id: row,
        cells: <Cell>{for (int col = 0; col < 3; col++) Cell(row, col)},
      ),
  ];
}

/// 4x4 quadrant layout: each region is one 2x2 corner (4 cells each).
List<Region> quadrants4x4() {
  return <Region>[
    Region(
      id: 0,
      cells: <Cell>{
        const Cell(0, 0),
        const Cell(0, 1),
        const Cell(1, 0),
        const Cell(1, 1),
      },
    ),
    Region(
      id: 1,
      cells: <Cell>{
        const Cell(0, 2),
        const Cell(0, 3),
        const Cell(1, 2),
        const Cell(1, 3),
      },
    ),
    Region(
      id: 2,
      cells: <Cell>{
        const Cell(2, 0),
        const Cell(2, 1),
        const Cell(3, 0),
        const Cell(3, 1),
      },
    ),
    Region(
      id: 3,
      cells: <Cell>{
        const Cell(2, 2),
        const Cell(2, 3),
        const Cell(3, 2),
        const Cell(3, 3),
      },
    ),
  ];
}

/// 4x4 row-strip layout: region `i` is row `i` (4 cells each).
List<Region> rowStrips4x4() {
  return <Region>[
    for (int row = 0; row < 4; row++)
      Region(
        id: row,
        cells: <Cell>{for (int col = 0; col < 4; col++) Cell(row, col)},
      ),
  ];
}

/// 5x5 mixed layout used by confinement scenarios. Regions cross rows and
/// columns so that confinement tests can distinguish the two directions.
///
/// ```
/// 0 0 1 1 1
/// 0 0 2 1 1
/// 0 2 2 2 4
/// 3 3 2 4 4
/// 3 3 3 4 4
/// ```
List<Region> mixed5x5() {
  return <Region>[
    Region(
      id: 0,
      cells: <Cell>{
        const Cell(0, 0),
        const Cell(0, 1),
        const Cell(1, 0),
        const Cell(1, 1),
        const Cell(2, 0),
      },
    ),
    Region(
      id: 1,
      cells: <Cell>{
        const Cell(0, 2),
        const Cell(0, 3),
        const Cell(0, 4),
        const Cell(1, 3),
        const Cell(1, 4),
      },
    ),
    Region(
      id: 2,
      cells: <Cell>{
        const Cell(1, 2),
        const Cell(2, 1),
        const Cell(2, 2),
        const Cell(2, 3),
        const Cell(3, 2),
      },
    ),
    Region(
      id: 3,
      cells: <Cell>{
        const Cell(3, 0),
        const Cell(3, 1),
        const Cell(4, 0),
        const Cell(4, 1),
        const Cell(4, 2),
      },
    ),
    Region(
      id: 4,
      cells: <Cell>{
        const Cell(2, 4),
        const Cell(3, 3),
        const Cell(3, 4),
        const Cell(4, 3),
        const Cell(4, 4),
      },
    ),
  ];
}
