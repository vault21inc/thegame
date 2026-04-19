import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

/// Golden-placement test for the non-N-Queens guardrail documented in
/// docs/level-generation.md §Stage 1 — Non-N-Queens guardrail.
///
/// σ = [0, 2, 4, 6, 1, 3, 5, 7] is intentionally a placement that a classic
/// N-Queens check would reject (it has tokens sharing the main diagonal),
/// but Star Battle rules accept because every token pair is at Chebyshev
/// distance >= 2. If these tests ever start failing, the most likely cause
/// is that someone has added N-Queens-style diagonal logic where it does
/// not belong.
void main() {
  group('Non-N-Queens golden placement (σ = [0, 2, 4, 6, 1, 3, 5, 7])', () {
    test('adjacent-row column deltas are all >= 2', () {
      for (int i = 0; i < kGoldenPlacement.length - 1; i++) {
        final int delta =
            (kGoldenPlacement[i].col - kGoldenPlacement[i + 1].col).abs();
        expect(
          delta,
          greaterThanOrEqualTo(2),
          reason:
              'Adjacent row pair $i / ${i + 1} has column delta $delta; '
              'Star Battle requires >= 2',
        );
      }
    });

    test('(0,0) and (7,7) share the main diagonal (row - col == 0)', () {
      expect(kGoldenPlacement.first, const Cell(0, 0));
      expect(kGoldenPlacement.last, const Cell(7, 7));
      expect(
        kGoldenPlacement.first.row - kGoldenPlacement.first.col,
        kGoldenPlacement.last.row - kGoldenPlacement.last.col,
        reason:
            'Guardrail precondition: this placement must include two tokens '
            'on the same long diagonal so that an N-Queens-style check '
            'would reject it.',
      );
    });

    test('no token pair is adjacent (Chebyshev distance >= 2)', () {
      for (int i = 0; i < kGoldenPlacement.length; i++) {
        for (int j = i + 1; j < kGoldenPlacement.length; j++) {
          final int distance =
              kGoldenPlacement[i].chebyshevDistanceTo(kGoldenPlacement[j]);
          expect(
            distance,
            greaterThanOrEqualTo(2),
            reason:
                'Tokens ${kGoldenPlacement[i]} and ${kGoldenPlacement[j]} '
                'must be at Chebyshev distance >= 2 to satisfy the no-touch '
                'rule; got $distance',
          );
        }
      }
    });

    test('PuzzleSolution accepts the placement', () {
      // Construction itself asserts the per-row indexing and column-permutation
      // invariants. If this line throws, the guardrail is already broken.
      final PuzzleSolution solution = PuzzleSolution(kGoldenPlacement);
      expect(solution.size, 8);
      for (int row = 0; row < 8; row++) {
        expect(solution.tokenForRow(row), kGoldenPlacement[row]);
      }
    });

    test('PuzzleDefinition accepts the placement (no-touch rule passes)', () {
      // If someone swaps `_solutionSatisfiesNoTouch` for an N-Queens-style
      // check, this constructor call would fire an AssertionError.
      final PuzzleDefinition puzzle = buildGoldenRowStripPuzzle();
      expect(puzzle.solution.tokens, kGoldenPlacement);
    });

    test('PlacementValidator reports zero violations for the placement', () {
      final PuzzleDefinition puzzle = buildGoldenRowStripPuzzle();
      const PlacementValidator validator = PlacementValidator.standard();
      final PlacementValidationResult result =
          validator.validate(puzzle, kGoldenPlacement);
      expect(
        result.isValid,
        isTrue,
        reason:
            'The golden placement must pass all row / column / region / '
            'no-touch checks. Reported violations: ${result.violations}',
      );
      expect(result.violations, isEmpty);
    });

    test(
      'PlacementValidator does NOT flag AdjacentTokens for the '
      '(0,0) / (7,7) diagonal pair',
      () {
        final PuzzleDefinition puzzle = buildGoldenRowStripPuzzle();
        const PlacementValidator validator = PlacementValidator.standard();
        final PlacementValidationResult result =
            validator.validate(puzzle, kGoldenPlacement);
        for (final PlacementViolation v in result.violations) {
          expect(
            v,
            isNot(isA<AdjacentTokens>()),
            reason:
                'AdjacentTokens must not fire on any pair in the golden '
                'placement, including (0,0) and (7,7) which share a diagonal '
                'but are at Chebyshev distance 7.',
          );
        }
      },
    );
  });
}
