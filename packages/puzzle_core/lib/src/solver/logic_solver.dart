import '../models/puzzle_definition.dart';
import 'solve_result.dart';

/// Runs the deduction loop described in docs/level-generation.md §Stage 4
/// against a puzzle and produces a [SolveResult] with a full trace.
///
/// Concrete implementation lands in milestone 3.
abstract class LogicSolver {
  SolveResult solve(PuzzleDefinition puzzle);
}
