import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../models/cell.dart';
import '../models/deduction_family.dart';

/// A single step in the logic solver's trace.
///
/// Either [placed] is non-null (a placement step) or [eliminated] is
/// non-empty (an elimination step) — both shapes are valid. A single trace
/// entry corresponds to one application of one [DeductionFamily].
@immutable
final class TraceEntry {
  TraceEntry({
    required this.family,
    required List<Cell> eliminated,
    required this.placed,
    required this.candidatesBefore,
    required this.candidatesAfter,
    required this.chainDepthSinceLastPlacement,
  })  : assert(
          placed != null || eliminated.isNotEmpty,
          'TraceEntry must either place a token or eliminate at least one candidate',
        ),
        assert(
          !(placed != null && eliminated.isNotEmpty),
          'TraceEntry cannot both place and eliminate in a single step',
        ),
        assert(
          candidatesBefore >= 0,
          'TraceEntry.candidatesBefore must be non-negative',
        ),
        assert(
          candidatesAfter >= 0,
          'TraceEntry.candidatesAfter must be non-negative',
        ),
        assert(
          candidatesAfter <= candidatesBefore,
          'TraceEntry.candidatesAfter must be <= candidatesBefore',
        ),
        assert(
          chainDepthSinceLastPlacement >= 0,
          'TraceEntry.chainDepthSinceLastPlacement must be non-negative',
        ),
        eliminated = List<Cell>.unmodifiable(eliminated);

  final DeductionFamily family;
  final List<Cell> eliminated;
  final Cell? placed;
  final int candidatesBefore;
  final int candidatesAfter;
  final int chainDepthSinceLastPlacement;

  bool get isPlacement => placed != null;

  @override
  bool operator ==(Object other) {
    return other is TraceEntry &&
        other.family == family &&
        other.placed == placed &&
        other.candidatesBefore == candidatesBefore &&
        other.candidatesAfter == candidatesAfter &&
        other.chainDepthSinceLastPlacement == chainDepthSinceLastPlacement &&
        const ListEquality<Cell>().equals(eliminated, other.eliminated);
  }

  @override
  int get hashCode => Object.hash(
        family,
        placed,
        candidatesBefore,
        candidatesAfter,
        chainDepthSinceLastPlacement,
        const ListEquality<Cell>().hash(eliminated),
      );

  @override
  String toString() =>
      'TraceEntry(${family.name}, placed: $placed, eliminated: ${eliminated.length}, '
      'before: $candidatesBefore, after: $candidatesAfter, '
      'chainDepth: $chainDepthSinceLastPlacement)';

  Map<String, Object?> toJson() => <String, Object?>{
        'family': family.name,
        'placed': placed?.toJson(),
        'eliminated': eliminated.map((Cell c) => c.toJson()).toList(),
        'candidatesBefore': candidatesBefore,
        'candidatesAfter': candidatesAfter,
        'chainDepth': chainDepthSinceLastPlacement,
      };

  factory TraceEntry.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw FormatException('TraceEntry JSON must be a map, got $json');
    }
    final Object? familyValue = json['family'];
    final Object? placedValue = json['placed'];
    final Object? eliminatedValue = json['eliminated'];
    final Object? beforeValue = json['candidatesBefore'];
    final Object? afterValue = json['candidatesAfter'];
    final Object? chainValue = json['chainDepth'];

    if (eliminatedValue is! List<Object?>) {
      throw FormatException(
        'TraceEntry.eliminated must be a list, got $eliminatedValue',
      );
    }
    if (beforeValue is! int || afterValue is! int || chainValue is! int) {
      throw FormatException(
        'TraceEntry numeric fields must be ints: $json',
      );
    }

    return TraceEntry(
      family: deductionFamilyFromJson(familyValue),
      placed: placedValue == null ? null : Cell.fromJson(placedValue),
      eliminated: eliminatedValue.map(Cell.fromJson).toList(growable: false),
      candidatesBefore: beforeValue,
      candidatesAfter: afterValue,
      chainDepthSinceLastPlacement: chainValue,
    );
  }
}
