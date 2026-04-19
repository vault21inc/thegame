import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

void main() {
  group('Region', () {
    test('equality uses id and cells (set-wise)', () {
      final Region a = Region(
        id: 0,
        cells: <Cell>{const Cell(0, 0), const Cell(0, 1)},
      );
      final Region b = Region(
        id: 0,
        cells: <Cell>{const Cell(0, 1), const Cell(0, 0)},
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);

      final Region differentId = Region(
        id: 1,
        cells: <Cell>{const Cell(0, 0), const Cell(0, 1)},
      );
      expect(a, isNot(equals(differentId)));
    });

    test('rejects empty cell set', () {
      expect(
        () => Region(id: 0, cells: <Cell>{}),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects disconnected cells', () {
      expect(
        () => Region(
          id: 0,
          cells: <Cell>{const Cell(0, 0), const Cell(5, 5)},
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('accepts L-shaped (non-rectangular) connected regions', () {
      final Region l = Region(
        id: 0,
        cells: <Cell>{
          const Cell(0, 0),
          const Cell(1, 0),
          const Cell(2, 0),
          const Cell(2, 1),
        },
      );
      expect(l.isContiguous, isTrue);
    });

    test('rejects negative id', () {
      expect(
        () => Region(id: -1, cells: <Cell>{const Cell(0, 0)}),
        throwsA(isA<AssertionError>()),
      );
    });

    test('containsCell reflects membership', () {
      final Region r = Region(
        id: 0,
        cells: <Cell>{const Cell(1, 1), const Cell(1, 2)},
      );
      expect(r.containsCell(const Cell(1, 1)), isTrue);
      expect(r.containsCell(const Cell(0, 0)), isFalse);
    });

    test('cells collection is unmodifiable', () {
      final Region r = Region(id: 0, cells: <Cell>{const Cell(0, 0)});
      expect(() => r.cells.add(const Cell(0, 1)), throwsUnsupportedError);
    });

    test('round-trips through JSON', () {
      final Region original = Region(
        id: 3,
        cells: <Cell>{
          const Cell(2, 1),
          const Cell(2, 2),
          const Cell(3, 2),
        },
      );
      expect(Region.fromJson(original.toJson()), original);
    });

    test('fromJson rejects duplicate cells', () {
      const Map<String, Object> malformed = <String, Object>{
        'id': 0,
        'cells': <List<int>>[
          <int>[0, 0],
          <int>[0, 0],
        ],
      };
      expect(() => Region.fromJson(malformed), throwsFormatException);
    });
  });
}
