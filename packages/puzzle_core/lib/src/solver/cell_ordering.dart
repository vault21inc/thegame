import '../models/cell.dart';

/// Compares two cells in deterministic row-major order.
///
/// Solver traces and candidate snapshots use this order so output is stable
/// across platforms and independent of set iteration details.
int compareCellsRowMajor(Cell a, Cell b) {
  final int rowCompare = a.row.compareTo(b.row);
  return rowCompare != 0 ? rowCompare : a.col.compareTo(b.col);
}

/// Returns [cells] sorted by row, then by column.
///
/// The input collection is never mutated; callers receive a new sorted list
/// that can be wrapped or further transformed as needed.
List<Cell> sortCellsRowMajor(Iterable<Cell> cells) {
  return cells.toList(growable: false)..sort(compareCellsRowMajor);
}
