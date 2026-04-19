import '../models/cell.dart';
import '../models/puzzle_definition.dart';
import '../models/region.dart';
import 'placement_validation_result.dart';
import 'placement_violation.dart';

/// Validates a proposed set of tokens against a puzzle's row / column /
/// region / no-touch rules.
///
/// This validator does **not** compare against the puzzle's stored solution.
/// For hidden-solution double-tap validation, use [SolutionValidator].
abstract class PlacementValidator {
  const PlacementValidator();

  /// Returns a concrete default implementation.
  const factory PlacementValidator.standard() = _StandardPlacementValidator;

  /// Validates [proposedTokens] against [puzzle]'s rules.
  ///
  /// The result collects every distinct violation found. Duplicate cells in
  /// [proposedTokens] are treated as a single token for constraint checking.
  PlacementValidationResult validate(
    PuzzleDefinition puzzle,
    Iterable<Cell> proposedTokens,
  );
}

class _StandardPlacementValidator extends PlacementValidator {
  const _StandardPlacementValidator();

  @override
  PlacementValidationResult validate(
    PuzzleDefinition puzzle,
    Iterable<Cell> proposedTokens,
  ) {
    final Set<Cell> uniqueTokens = proposedTokens.toSet();
    final List<PlacementViolation> violations = <PlacementViolation>[];

    final Set<Cell> inBounds = <Cell>{};
    for (final Cell token in uniqueTokens) {
      if (!puzzle.cellIsInGrid(token)) {
        violations.add(OutOfBoundsToken(token));
      } else {
        inBounds.add(token);
      }
    }

    _collectAxisDuplicates<int>(
      inBounds,
      axis: (Cell c) => c.row,
      buildViolation: DuplicateRow.new,
      into: violations,
    );
    _collectAxisDuplicates<int>(
      inBounds,
      axis: (Cell c) => c.col,
      buildViolation: DuplicateColumn.new,
      into: violations,
    );
    _collectRegionDuplicates(puzzle, inBounds, violations);
    _collectAdjacentPairs(inBounds, violations);

    return PlacementValidationResult(violations);
  }

  static void _collectAxisDuplicates<K>(
    Set<Cell> tokens, {
    required K Function(Cell) axis,
    required PlacementViolation Function(K) buildViolation,
    required List<PlacementViolation> into,
  }) {
    final Map<K, int> counts = <K, int>{};
    for (final Cell token in tokens) {
      counts.update(axis(token), (int v) => v + 1, ifAbsent: () => 1);
    }
    for (final MapEntry<K, int> entry in counts.entries) {
      if (entry.value > 1) {
        into.add(buildViolation(entry.key));
      }
    }
  }

  static void _collectRegionDuplicates(
    PuzzleDefinition puzzle,
    Set<Cell> tokens,
    List<PlacementViolation> into,
  ) {
    final Map<int, int> counts = <int, int>{};
    for (final Cell token in tokens) {
      final Region region = puzzle.regionContaining(token);
      counts.update(region.id, (int v) => v + 1, ifAbsent: () => 1);
    }
    for (final MapEntry<int, int> entry in counts.entries) {
      if (entry.value > 1) {
        into.add(DuplicateRegion(entry.key));
      }
    }
  }

  static void _collectAdjacentPairs(
    Set<Cell> tokens,
    List<PlacementViolation> into,
  ) {
    final List<Cell> list = tokens.toList(growable: false);
    for (int i = 0; i < list.length; i++) {
      for (int j = i + 1; j < list.length; j++) {
        if (list[i].touches(list[j])) {
          into.add(AdjacentTokens(list[i], list[j]));
        }
      }
    }
  }
}
