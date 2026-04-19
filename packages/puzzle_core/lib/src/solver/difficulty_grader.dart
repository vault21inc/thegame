import '../models/deduction_family.dart';
import '../models/difficulty.dart';
import '../models/difficulty_metadata.dart';
import 'solve_result.dart';
import 'trace_entry.dart';

/// Classifies a solved trace into a difficulty band and summary metrics.
///
/// The thresholds are intentionally heuristic, matching the calibration notes
/// in the level-generation spec. The grader gives Family 5 absolute priority
/// for Master, treats Family 4 or long chains as Hard, treats Family 2/3 as
/// Medium, and leaves pure Giveaway traces in Easy.
final class DifficultyGrader {
  /// Creates a grader using the V1 heuristic band thresholds.
  const DifficultyGrader();

  /// Builds [DifficultyMetadata] for [result].
  ///
  /// [cellCount] is the total number of board cells that were open at the
  /// start of the solve, normally `puzzle.size * puzzle.size`. It is used to
  /// normalize candidate density into the required `[0, 1]` range.
  DifficultyMetadata grade(SolveResult result, {required int cellCount}) {
    if (cellCount <= 0) {
      throw ArgumentError.value(cellCount, 'cellCount', 'Must be positive');
    }

    final Set<DeductionFamily> families = <DeductionFamily>{
      for (final TraceEntry entry in result.trace) entry.family,
    };
    final int steps = _individualStepCount(result.trace);
    final int maxChainDepth = _maxChainDepth(result.trace);
    final int firstPlacementDepth = _firstPlacementDepth(result.trace);
    final double minCandidateDensity = _minCandidateDensity(
      result.trace,
      cellCount,
    );

    return DifficultyMetadata(
      band: _classify(
        families: families,
        maxChainDepth: maxChainDepth,
        firstPlacementDepth: firstPlacementDepth,
        trace: result.trace,
      ),
      steps: steps,
      maxChainDepth: maxChainDepth,
      families: families,
      firstPlacementDepth: firstPlacementDepth,
      minCandidateDensity: minCandidateDensity,
    );
  }

  int _individualStepCount(List<TraceEntry> trace) {
    var count = 0;
    for (final TraceEntry entry in trace) {
      count += entry.isPlacement ? 1 : entry.eliminated.length;
    }
    return count;
  }

  int _maxChainDepth(List<TraceEntry> trace) {
    var maxDepth = 0;
    for (final TraceEntry entry in trace) {
      if (entry.chainDepthSinceLastPlacement > maxDepth) {
        maxDepth = entry.chainDepthSinceLastPlacement;
      }
    }
    return maxDepth;
  }

  int _firstPlacementDepth(List<TraceEntry> trace) {
    var depth = 0;
    for (final TraceEntry entry in trace) {
      if (entry.isPlacement) {
        return depth;
      }
      depth += 1;
    }
    return depth;
  }

  double _minCandidateDensity(List<TraceEntry> trace, int cellCount) {
    if (trace.isEmpty) {
      return 1.0;
    }
    var minDensity = 1.0;
    for (final TraceEntry entry in trace) {
      final double density = entry.candidatesAfter / cellCount;
      if (density < minDensity) {
        minDensity = density;
      }
    }
    return minDensity.clamp(0.0, 1.0);
  }

  Difficulty _classify({
    required Set<DeductionFamily> families,
    required int maxChainDepth,
    required int firstPlacementDepth,
    required List<TraceEntry> trace,
  }) {
    if (families.contains(DeductionFamily.higherOrderConfinement)) {
      return Difficulty.master;
    }
    if (families.contains(DeductionFamily.contradictionElimination) ||
        maxChainDepth >= 7 ||
        _familyCount(trace, DeductionFamily.touchAllElimination) >= 2) {
      return Difficulty.hard;
    }
    if (families.contains(DeductionFamily.confinement) ||
        families.contains(DeductionFamily.touchAllElimination) ||
        maxChainDepth >= 3 ||
        firstPlacementDepth > 2) {
      return Difficulty.medium;
    }
    return Difficulty.easy;
  }

  int _familyCount(List<TraceEntry> trace, DeductionFamily family) {
    var count = 0;
    for (final TraceEntry entry in trace) {
      if (entry.family == family) {
        count += 1;
      }
    }
    return count;
  }
}
