import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

import '../deduction_scenarios/scenario_types.dart';
import '../deduction_scenarios/scenarios.dart';

void main() {
  group('deduction scenario runner', () {
    for (final DeductionScenario scenario in allScenarios()) {
      test('${scenario.id} produces expected first step', () {
        final StandardCandidateGrid grid = StandardCandidateGrid(
          size: scenario.gridSize,
          regions: scenario.regions,
          initialEliminations: scenario.initialEliminations,
          initialPlacements: scenario.initialPlacements,
        );

        final DeductionStep? step = findNextDeduction(
          size: scenario.gridSize,
          regions: scenario.regions,
          grid: grid,
        );

        switch (scenario.expected) {
          case ExpectedPlacement(:final cell, :final family):
            expect(step, isNotNull);
            expect(step!.family, family);
            expect(step.placed, cell);
            expect(step.eliminated, isEmpty);
          case ExpectedElimination(:final cells, :final family):
            expect(step, isNotNull);
            expect(step!.family, family);
            expect(step.placed, isNull);
            expect(step.eliminated.toSet(), cells);
          case ExpectedNoProgress():
            expect(step, isNull);
        }

        if (step != null) {
          expect(scenario.mustNotFireFirst, isNot(contains(step.family)));
        }
      });
    }
  });
}
