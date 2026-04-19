/// Pure Dart engine for Skully Bones Treasure Adventure.
///
/// See [the package README](../README.md) and [docs/data-model.md](../../docs/data-model.md)
/// for the full type reference.
library;

export 'src/models/cell.dart';
export 'src/models/deduction_family.dart';
export 'src/models/difficulty.dart';
export 'src/models/difficulty_metadata.dart';
export 'src/models/puzzle_definition.dart';
export 'src/models/puzzle_solution.dart';
export 'src/models/region.dart';
export 'src/solver/candidate_grid.dart';
export 'src/solver/cell_state.dart';
export 'src/solver/deduction_rules.dart';
export 'src/solver/deduction_step.dart';
export 'src/solver/difficulty_grader.dart';
export 'src/solver/logic_solver.dart';
export 'src/solver/solve_result.dart';
export 'src/solver/standard_candidate_grid.dart';
export 'src/solver/standard_logic_solver.dart';
export 'src/solver/standard_uniqueness_solver.dart';
export 'src/solver/trace_entry.dart';
export 'src/solver/uniqueness_solver.dart';
export 'src/validation/placement_validation_result.dart';
export 'src/validation/placement_validator.dart';
export 'src/validation/placement_violation.dart';
export 'src/validation/solution_validator.dart';
