import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

void main() {
  group('PuzzleSolution', () {
    test('accepts a valid per-row column permutation', () {
      final PuzzleSolution solution = PuzzleSolution(
        const <Cell>[Cell(0, 1), Cell(1, 3), Cell(2, 0), Cell(3, 2)],
      );
      expect(solution.size, 4);
      expect(solution.tokenForRow(2), const Cell(2, 0));
    });

    test('rejects empty tokens', () {
      expect(
        () => PuzzleSolution(const <Cell>[]),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects out-of-order rows', () {
      expect(
        () => PuzzleSolution(
          const <Cell>[
            Cell(0, 0),
            Cell(0, 2), // row index does not match position
            Cell(2, 1),
            Cell(3, 3),
          ],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects duplicate columns', () {
      expect(
        () => PuzzleSolution(
          const <Cell>[Cell(0, 1), Cell(1, 1), Cell(2, 0), Cell(3, 2)],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects columns outside [0, size)', () {
      expect(
        () => PuzzleSolution(
          const <Cell>[
            Cell(0, 4), // size is 2, col must be in [0, 2)
            Cell(1, 0),
          ],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('equality compares by tokens sequence', () {
      final PuzzleSolution a = PuzzleSolution(
        const <Cell>[Cell(0, 1), Cell(1, 3), Cell(2, 0), Cell(3, 2)],
      );
      final PuzzleSolution b = PuzzleSolution(
        const <Cell>[Cell(0, 1), Cell(1, 3), Cell(2, 0), Cell(3, 2)],
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('round-trips through JSON', () {
      final PuzzleSolution original = PuzzleSolution(
        const <Cell>[Cell(0, 1), Cell(1, 3), Cell(2, 0), Cell(3, 2)],
      );
      expect(PuzzleSolution.fromJson(original.toJson()), original);
    });

    test('tokens collection is unmodifiable', () {
      final PuzzleSolution s =
          PuzzleSolution(const <Cell>[Cell(0, 0), Cell(1, 1)]);
      expect(() => s.tokens.add(const Cell(2, 2)), throwsUnsupportedError);
    });
  });
}
