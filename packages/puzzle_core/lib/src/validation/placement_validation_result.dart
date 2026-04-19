import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'placement_violation.dart';

/// Outcome of [PlacementValidator.validate].
///
/// `isValid` is true iff [violations] is empty.
@immutable
final class PlacementValidationResult {
  PlacementValidationResult(List<PlacementViolation> violations)
      : violations = List<PlacementViolation>.unmodifiable(violations);

  const PlacementValidationResult.valid()
      : violations = const <PlacementViolation>[];

  final List<PlacementViolation> violations;

  bool get isValid => violations.isEmpty;

  @override
  bool operator ==(Object other) {
    return other is PlacementValidationResult &&
        const ListEquality<PlacementViolation>()
            .equals(violations, other.violations);
  }

  @override
  int get hashCode =>
      const ListEquality<PlacementViolation>().hash(violations);

  @override
  String toString() => isValid
      ? 'PlacementValidationResult.valid()'
      : 'PlacementValidationResult($violations)';
}
