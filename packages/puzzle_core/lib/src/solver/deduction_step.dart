import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../models/cell.dart';
import '../models/deduction_family.dart';
import 'cell_ordering.dart';

/// A pure deduction result before it is applied to a mutable grid.
///
/// Deduction families return this lightweight value so tests can inspect the
/// next logical move without mutating candidate state. [LogicSolver]
/// implementations convert applied steps into [TraceEntry] values with
/// candidate counts and chain-depth metadata.
@immutable
final class DeductionStep {
  /// Creates a placement step for one forced token.
  DeductionStep.place({required this.family, required Cell cell})
      : placed = cell,
        eliminated = const <Cell>[];

  /// Creates an elimination step for one application of a deduction family.
  ///
  /// [cells] are sorted into row-major order so traces remain deterministic
  /// regardless of the set iteration order used by the caller.
  DeductionStep.eliminate({
    required this.family,
    required Iterable<Cell> cells,
  })  : placed = null,
        eliminated = List<Cell>.unmodifiable(sortCellsRowMajor(cells)) {
    if (eliminated.isEmpty) {
      throw ArgumentError.value(
        cells,
        'cells',
        'Elimination steps must remove at least one cell',
      );
    }
  }

  /// Deduction family responsible for this step.
  final DeductionFamily family;

  /// Cells eliminated by this step, empty for placement steps.
  final List<Cell> eliminated;

  /// Cell placed by this step, null for elimination steps.
  final Cell? placed;

  /// Whether this step places a token.
  bool get isPlacement => placed != null;

  @override
  bool operator ==(Object other) {
    return other is DeductionStep &&
        other.family == family &&
        other.placed == placed &&
        const ListEquality<Cell>().equals(other.eliminated, eliminated);
  }

  @override
  int get hashCode => Object.hash(
        family,
        placed,
        const ListEquality<Cell>().hash(eliminated),
      );

  @override
  String toString() => isPlacement
      ? 'DeductionStep(${family.name}, placed: $placed)'
      : 'DeductionStep(${family.name}, eliminated: ${eliminated.length})';
}
