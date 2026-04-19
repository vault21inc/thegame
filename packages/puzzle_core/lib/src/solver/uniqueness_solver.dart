import '../models/puzzle_definition.dart';

/// Counts valid solutions for a puzzle, with early exit at 2.
///
/// Returns 0, 1, or 2. A return value of 2 means "at least 2" — the solver
/// is expected to short-circuit as soon as a second solution is found.
///
/// Concrete implementation lands in milestone 3.
abstract class UniquenessSolver {
  int countSolutions(PuzzleDefinition puzzle);
}
