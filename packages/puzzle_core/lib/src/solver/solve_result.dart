import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../models/cell.dart';
import 'trace_entry.dart';

/// Result of a [LogicSolver] run against a puzzle.
@immutable
final class SolveResult {
  SolveResult({
    required this.solved,
    required List<TraceEntry> trace,
    required List<Cell> placedTokens,
  })  : trace = List<TraceEntry>.unmodifiable(trace),
        placedTokens = List<Cell>.unmodifiable(placedTokens);

  final bool solved;
  final List<TraceEntry> trace;
  final List<Cell> placedTokens;

  @override
  bool operator ==(Object other) {
    return other is SolveResult &&
        other.solved == solved &&
        const ListEquality<TraceEntry>().equals(trace, other.trace) &&
        const ListEquality<Cell>().equals(placedTokens, other.placedTokens);
  }

  @override
  int get hashCode => Object.hash(
        solved,
        const ListEquality<TraceEntry>().hash(trace),
        const ListEquality<Cell>().hash(placedTokens),
      );

  @override
  String toString() =>
      'SolveResult(solved: $solved, traceSteps: ${trace.length}, '
      'placed: ${placedTokens.length})';
}
