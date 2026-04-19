import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

void main() {
  group('Cell', () {
    test('equality uses (row, col)', () {
      expect(const Cell(1, 2), equals(const Cell(1, 2)));
      expect(const Cell(1, 2).hashCode, const Cell(1, 2).hashCode);
      expect(const Cell(1, 2), isNot(equals(const Cell(2, 1))));
    });

    test('rejects negative coordinates', () {
      expect(() => Cell(-1, 0), throwsA(isA<AssertionError>()));
      expect(() => Cell(0, -1), throwsA(isA<AssertionError>()));
    });

    test('chebyshevDistanceTo returns max of axis differences', () {
      expect(const Cell(0, 0).chebyshevDistanceTo(const Cell(3, 4)), 4);
      expect(const Cell(0, 0).chebyshevDistanceTo(const Cell(2, 2)), 2);
      expect(const Cell(5, 5).chebyshevDistanceTo(const Cell(5, 5)), 0);
    });

    test('touches is true iff cells are adjacent and not identical', () {
      const Cell origin = Cell(3, 3);
      expect(origin.touches(origin), isFalse);

      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) {
            continue;
          }
          expect(
            origin.touches(Cell(origin.row + dr, origin.col + dc)),
            isTrue,
            reason: 'Expected (3+$dr, 3+$dc) to touch (3, 3)',
          );
        }
      }
      expect(origin.touches(const Cell(3, 5)), isFalse);
      expect(origin.touches(const Cell(5, 5)), isFalse);
    });

    test('round-trips through JSON', () {
      const Cell original = Cell(3, 7);
      expect(Cell.fromJson(original.toJson()), original);
    });

    test('fromJson rejects malformed input', () {
      expect(() => Cell.fromJson('oops'), throwsFormatException);
      expect(() => Cell.fromJson(<int>[1]), throwsFormatException);
      expect(() => Cell.fromJson(<Object>[1, 'two']), throwsFormatException);
    });
  });
}
