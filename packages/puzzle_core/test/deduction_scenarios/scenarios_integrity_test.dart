import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

import 'scenario_types.dart';
import 'scenarios.dart';

/// Structural-only tests for the deduction scenarios defined in
/// [scenarios.dart]. These run immediately — they do NOT invoke the
/// deduction engine (that doesn't exist yet). They catch authoring
/// mistakes: out-of-bounds cells, duplicate region IDs, non-partitioning
/// region sets, placement/elimination overlaps, expected-outcome cells
/// that aren't in the grid, and so on.
///
/// Semantic correctness — "does Family X actually fire here?" — is the
/// job of milestone 3's scenario runner.
void main() {
  final List<DeductionScenario> scenarios = allScenarios();

  test('17 scenarios are authored (8 required + 5 negative + 4 ordering)', () {
    expect(allRequiredScenarios(), hasLength(8));
    expect(allNegativeScenarios(), hasLength(5));
    expect(allOrderingScenarios(), hasLength(4));
    expect(scenarios, hasLength(17));
  });

  test('scenario IDs are unique', () {
    final Set<String> seen = <String>{};
    for (final DeductionScenario s in scenarios) {
      expect(
        seen.add(s.id),
        isTrue,
        reason: 'Duplicate scenario id: ${s.id}',
      );
    }
  });

  test('scenario IDs match the families they describe', () {
    // Sanity: `S5-*` scenarios should target higherOrderConfinement,
    // `N-giveaway-*` should forbid giveawayCell, etc. This is a cheap
    // typo catch.
    final Map<String, DeductionFamily> idPrefixToFamily =
        <String, DeductionFamily>{
      'S1-': DeductionFamily.giveawayCell,
      'S2-': DeductionFamily.confinement,
      'S3-': DeductionFamily.touchAllElimination,
      'S4-': DeductionFamily.contradictionElimination,
      'S5-': DeductionFamily.higherOrderConfinement,
    };

    for (final DeductionScenario s in scenarios) {
      for (final MapEntry<String, DeductionFamily> entry
          in idPrefixToFamily.entries) {
        if (!s.id.startsWith(entry.key)) {
          continue;
        }
        final ExpectedOutcome expected = s.expected;
        final DeductionFamily family = switch (expected) {
          ExpectedPlacement(:final DeductionFamily family) => family,
          ExpectedElimination(:final DeductionFamily family) => family,
          ExpectedNoProgress() => throw StateError(
              '${s.id} is a required scenario but expects no progress; '
              'required scenarios must assert a concrete outcome.',
            ),
        };
        expect(
          family,
          entry.value,
          reason: '${s.id} expects family ${family.name} but its ID prefix '
              'indicates ${entry.value.name}',
        );
      }
    }
  });

  test('every scenario is structurally well-formed', () {
    final List<ScenarioDefect> defects = <ScenarioDefect>[
      for (final DeductionScenario s in scenarios) ...validateScenario(s),
    ];
    expect(
      defects,
      isEmpty,
      reason: 'Structural defects:\n${defects.join('\n')}',
    );
  });

  group('per-scenario detail', () {
    for (final DeductionScenario s in scenarios) {
      test('[${s.id}] passes validateScenario', () {
        final List<ScenarioDefect> defects = validateScenario(s);
        expect(
          defects,
          isEmpty,
          reason: 'Defects for ${s.id}:\n${defects.join('\n')}',
        );
      });
    }
  });

  test('negative scenarios forbid their target family via mustNotFireFirst',
      () {
    final Map<String, DeductionFamily> negativeTargets =
        <String, DeductionFamily>{
      'N-giveaway-noop': DeductionFamily.giveawayCell,
      'N-confinement-noop': DeductionFamily.confinement,
      'N-touchall-noop': DeductionFamily.touchAllElimination,
      'N-contradiction-noop': DeductionFamily.contradictionElimination,
      'N-higherorder-noop': DeductionFamily.higherOrderConfinement,
    };

    for (final DeductionScenario s in allNegativeScenarios()) {
      final DeductionFamily? target = negativeTargets[s.id];
      expect(
        target,
        isNotNull,
        reason: 'Negative scenario ${s.id} has no declared target family',
      );
      expect(
        s.mustNotFireFirst,
        contains(target),
        reason: '${s.id} must list ${target?.name} in mustNotFireFirst to '
            'enforce its negative-case contract.',
      );
      expect(
        s.expected,
        isA<ExpectedNoProgress>(),
        reason: '${s.id} expects no progress so that the whole deduction pass '
            'asserts the target family produced nothing.',
      );
    }
  });

  test('ordering scenarios forbid the higher-numbered family', () {
    // O-family-N-before-M: expected family is N, mustNotFireFirst must
    // include M.
    final Map<String, (DeductionFamily, DeductionFamily)> orderingTargets =
        <String, (DeductionFamily, DeductionFamily)>{
      'O-family-1-before-2': (
        DeductionFamily.giveawayCell,
        DeductionFamily.confinement,
      ),
      'O-family-2-before-3': (
        DeductionFamily.confinement,
        DeductionFamily.touchAllElimination,
      ),
      'O-family-3-before-4': (
        DeductionFamily.touchAllElimination,
        DeductionFamily.contradictionElimination,
      ),
      'O-family-4-before-5': (
        DeductionFamily.contradictionElimination,
        DeductionFamily.higherOrderConfinement,
      ),
    };

    for (final DeductionScenario s in allOrderingScenarios()) {
      final (DeductionFamily, DeductionFamily)? pair = orderingTargets[s.id];
      expect(
        pair,
        isNotNull,
        reason: 'Ordering scenario ${s.id} has no declared family pair',
      );
      final (DeductionFamily expectedFamily, DeductionFamily forbidden) = pair!;
      final ExpectedOutcome outcome = s.expected;
      final DeductionFamily actual = switch (outcome) {
        ExpectedPlacement(:final DeductionFamily family) => family,
        ExpectedElimination(:final DeductionFamily family) => family,
        ExpectedNoProgress() => throw StateError(
            '${s.id} ordering scenarios must expect concrete progress',
          ),
      };
      expect(
        actual,
        expectedFamily,
        reason: '${s.id}: expected family ${expectedFamily.name}',
      );
      expect(
        s.mustNotFireFirst,
        contains(forbidden),
        reason: '${s.id} must forbid ${forbidden.name} via mustNotFireFirst '
            'so the ordering contract is enforced.',
      );
    }
  });
}
