import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'deduction_family.dart';
import 'difficulty.dart';

/// Difficulty grade plus summary metrics from the solve trace.
@immutable
final class DifficultyMetadata {
  DifficultyMetadata({
    required this.band,
    required this.steps,
    required this.maxChainDepth,
    required Set<DeductionFamily> families,
    required this.firstPlacementDepth,
    required this.minCandidateDensity,
  })  : assert(steps >= 0, 'DifficultyMetadata.steps must be non-negative'),
        assert(
          maxChainDepth >= 0,
          'DifficultyMetadata.maxChainDepth must be non-negative',
        ),
        assert(
          firstPlacementDepth >= 0,
          'DifficultyMetadata.firstPlacementDepth must be non-negative',
        ),
        assert(
          minCandidateDensity >= 0.0 && minCandidateDensity <= 1.0,
          'DifficultyMetadata.minCandidateDensity must be in [0, 1]',
        ),
        families = UnmodifiableSetView<DeductionFamily>(
          Set<DeductionFamily>.of(families),
        );

  final Difficulty band;
  final int steps;
  final int maxChainDepth;
  final Set<DeductionFamily> families;
  final int firstPlacementDepth;
  final double minCandidateDensity;

  @override
  bool operator ==(Object other) {
    return other is DifficultyMetadata &&
        other.band == band &&
        other.steps == steps &&
        other.maxChainDepth == maxChainDepth &&
        other.firstPlacementDepth == firstPlacementDepth &&
        other.minCandidateDensity == minCandidateDensity &&
        const SetEquality<DeductionFamily>().equals(families, other.families);
  }

  @override
  int get hashCode => Object.hash(
        band,
        steps,
        maxChainDepth,
        firstPlacementDepth,
        minCandidateDensity,
        const SetEquality<DeductionFamily>().hash(families),
      );

  @override
  String toString() =>
      'DifficultyMetadata(band: ${band.name}, steps: $steps, '
      'maxChainDepth: $maxChainDepth, families: ${families.map((DeductionFamily f) => f.name).toList()}, '
      'firstPlacementDepth: $firstPlacementDepth, '
      'minCandidateDensity: $minCandidateDensity)';

  Map<String, Object?> toJson() => <String, Object?>{
        'band': band.name,
        'steps': steps,
        'maxChainDepth': maxChainDepth,
        'families': families.map((DeductionFamily f) => f.name).toList(),
        'firstPlacementDepth': firstPlacementDepth,
        'minCandidateDensity': minCandidateDensity,
      };

  factory DifficultyMetadata.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw FormatException(
        'DifficultyMetadata JSON must be a map, got $json',
      );
    }
    final Object? steps = json['steps'];
    final Object? maxChainDepth = json['maxChainDepth'];
    final Object? firstPlacementDepth = json['firstPlacementDepth'];
    final Object? minCandidateDensity = json['minCandidateDensity'];
    final Object? familiesJson = json['families'];

    if (steps is! int ||
        maxChainDepth is! int ||
        firstPlacementDepth is! int) {
      throw FormatException(
        'DifficultyMetadata numeric fields must be ints: $json',
      );
    }
    if (minCandidateDensity is! num) {
      throw FormatException(
        'DifficultyMetadata.minCandidateDensity must be a number, '
        'got $minCandidateDensity',
      );
    }
    if (familiesJson is! List<Object?>) {
      throw FormatException(
        'DifficultyMetadata.families must be a list, got $familiesJson',
      );
    }

    final Set<DeductionFamily> families = <DeductionFamily>{
      for (final Object? raw in familiesJson) deductionFamilyFromJson(raw),
    };

    return DifficultyMetadata(
      band: difficultyFromJson(json['band']),
      steps: steps,
      maxChainDepth: maxChainDepth,
      families: families,
      firstPlacementDepth: firstPlacementDepth,
      minCandidateDensity: minCandidateDensity.toDouble(),
    );
  }
}
