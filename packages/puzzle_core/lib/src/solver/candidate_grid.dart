import '../models/cell.dart';
import 'cell_state.dart';

/// A mutable candidate grid used by [LogicSolver] and [UniquenessSolver].
///
/// Each cell is in one of three states — see [CellState]. Eliminations and
/// placements are applied through the mutation API; housekeeping after a
/// placement (clearing row, column, region, and 3x3 no-touch neighborhood)
/// is the responsibility of the consuming solver, not this interface.
///
/// Concrete implementations land in milestone 3.
abstract class CandidateGrid {
  /// Square side length of the board represented by this grid.
  int get size;

  /// Returns the current runtime state for [cell].
  CellState stateAt(Cell cell);

  /// Returns remaining candidate cells in [row], ordered left-to-right.
  Set<Cell> candidatesInRow(int row);

  /// Returns remaining candidate cells in [col], ordered top-to-bottom.
  Set<Cell> candidatesInColumn(int col);

  /// Returns remaining candidate cells in the region with [regionId].
  Set<Cell> candidatesInRegion(int regionId);

  /// Marks [cell] as eliminated.
  ///
  /// Throws [StateError] if [cell] is already placed.
  void eliminate(Cell cell);

  /// Marks [cell] as placed.
  ///
  /// Throws [StateError] if [cell] is already eliminated.
  void place(Cell cell);
}
