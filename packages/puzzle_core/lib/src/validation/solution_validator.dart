import '../models/cell.dart';
import '../models/puzzle_definition.dart';

/// Checks whether a given cell is the correct solution cell for its row in
/// the supplied puzzle.
///
/// This is the hidden-solution check used by the in-game double-tap
/// interaction — a cell can satisfy the currently visible constraints yet
/// still be wrong if it differs from the stored solution cell for that row.
/// See README §Player Interaction.
abstract class SolutionValidator {
  const SolutionValidator();

  /// Returns a concrete default implementation.
  const factory SolutionValidator.standard() = _StandardSolutionValidator;

  /// True iff [cell] equals the stored solution token for its row in [puzzle].
  ///
  /// Returns `false` for cells outside the grid.
  bool isSolutionCell(PuzzleDefinition puzzle, Cell cell);
}

class _StandardSolutionValidator extends SolutionValidator {
  const _StandardSolutionValidator();

  @override
  bool isSolutionCell(PuzzleDefinition puzzle, Cell cell) {
    if (!puzzle.cellIsInGrid(cell)) {
      return false;
    }
    return puzzle.solution.tokenForRow(cell.row) == cell;
  }
}
