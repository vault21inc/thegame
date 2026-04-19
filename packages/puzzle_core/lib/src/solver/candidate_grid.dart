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
  int get size;

  CellState stateAt(Cell cell);

  Set<Cell> candidatesInRow(int row);
  Set<Cell> candidatesInColumn(int col);
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
