import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

import '../deduction_scenarios/scenario_types.dart';
import '../deduction_scenarios/scenarios.dart';
import 'solver_test_puzzles.dart';

void main() {
  group('StandardLogicSolver', () {
    test('solves a cascading giveaway puzzle with housekeeping', () {
      final PuzzleDefinition puzzle = buildCascadingGiveawayPuzzle();

      final SolveResult result = const StandardLogicSolver().solve(puzzle);

      expect(result.solved, isTrue);
      expect(result.placedTokens, puzzle.solution.tokens);
      expect(result.trace, hasLength(4));
      expect(
        result.trace.map((TraceEntry entry) => entry.family).toSet(),
        <DeductionFamily>{DeductionFamily.giveawayCell},
      );
      expect(
        result.trace.map((TraceEntry entry) => entry.placed).toList(),
        puzzle.solution.tokens,
      );
      expect(
        result.trace.map(
          (TraceEntry entry) => entry.chainDepthSinceLastPlacement,
        ),
        everyElement(0),
      );
    });

    test('returns unsolved when no deduction can advance the puzzle', () {
      final PuzzleDefinition puzzle = buildTwoSolutionRowStripPuzzle();

      final SolveResult result = const StandardLogicSolver().solve(puzzle);

      expect(result.solved, isFalse);
      expect(result.trace, isEmpty);
      expect(result.placedTokens, isEmpty);
    });

    for (final DeductionScenario scenario in <DeductionScenario>[
      s2ConfinementRegionToRow,
      s3TouchAll,
      s4Contradiction,
      s5HigherOrderK2,
    ]) {
      test('${scenario.id} runs through the solver loop', () {
        final SolveResult result = const StandardLogicSolver().solveState(
          size: scenario.gridSize,
          regions: scenario.regions,
          initialEliminations: scenario.initialEliminations,
          initialPlacements: scenario.initialPlacements,
        );

        expect(result.trace, isNotEmpty);
        _expectFirstTraceEntry(result.trace.first, scenario.expected);
      });
    }

    test('elimination trace entries increment chain depth', () {
      final SolveResult result = const StandardLogicSolver().solveState(
        size: s2ConfinementRegionToRow.gridSize,
        regions: s2ConfinementRegionToRow.regions,
        initialEliminations: s2ConfinementRegionToRow.initialEliminations,
        initialPlacements: s2ConfinementRegionToRow.initialPlacements,
      );

      expect(result.trace.first.isPlacement, isFalse);
      expect(result.trace.first.chainDepthSinceLastPlacement, 1);
    });
  });
}

void _expectFirstTraceEntry(TraceEntry entry, ExpectedOutcome expected) {
  switch (expected) {
    case ExpectedPlacement(:final cell, :final family):
      expect(entry.family, family);
      expect(entry.placed, cell);
      expect(entry.eliminated, isEmpty);
      expect(entry.chainDepthSinceLastPlacement, 0);
    case ExpectedElimination(:final cells, :final family):
      expect(entry.family, family);
      expect(entry.placed, isNull);
      expect(entry.eliminated.toSet(), cells);
      expect(entry.chainDepthSinceLastPlacement, 1);
    case ExpectedNoProgress():
      fail('Expected first trace entry for no-progress scenario');
  }
}
