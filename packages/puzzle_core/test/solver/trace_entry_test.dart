import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

void main() {
  group('TraceEntry', () {
    test('accepts a placement step', () {
      final TraceEntry entry = TraceEntry(
        family: DeductionFamily.giveawayCell,
        eliminated: const <Cell>[],
        placed: const Cell(1, 3),
        candidatesBefore: 16,
        candidatesAfter: 10,
        chainDepthSinceLastPlacement: 0,
      );
      expect(entry.isPlacement, isTrue);
      expect(entry.placed, const Cell(1, 3));
      expect(entry.eliminated, isEmpty);
    });

    test('accepts an elimination step', () {
      final TraceEntry entry = TraceEntry(
        family: DeductionFamily.confinement,
        eliminated: const <Cell>[Cell(0, 0), Cell(0, 1)],
        placed: null,
        candidatesBefore: 16,
        candidatesAfter: 14,
        chainDepthSinceLastPlacement: 2,
      );
      expect(entry.isPlacement, isFalse);
      expect(entry.eliminated, hasLength(2));
    });

    test('rejects a step that both places and eliminates', () {
      expect(
        () => TraceEntry(
          family: DeductionFamily.giveawayCell,
          eliminated: const <Cell>[Cell(1, 1)],
          placed: const Cell(1, 3),
          candidatesBefore: 10,
          candidatesAfter: 8,
          chainDepthSinceLastPlacement: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects a step that does neither', () {
      expect(
        () => TraceEntry(
          family: DeductionFamily.giveawayCell,
          eliminated: const <Cell>[],
          placed: null,
          candidatesBefore: 10,
          candidatesAfter: 10,
          chainDepthSinceLastPlacement: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects candidatesAfter > candidatesBefore', () {
      expect(
        () => TraceEntry(
          family: DeductionFamily.giveawayCell,
          eliminated: const <Cell>[],
          placed: const Cell(0, 0),
          candidatesBefore: 5,
          candidatesAfter: 6,
          chainDepthSinceLastPlacement: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects negative numeric fields', () {
      expect(
        () => TraceEntry(
          family: DeductionFamily.giveawayCell,
          eliminated: const <Cell>[],
          placed: const Cell(0, 0),
          candidatesBefore: -1,
          candidatesAfter: 0,
          chainDepthSinceLastPlacement: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => TraceEntry(
          family: DeductionFamily.giveawayCell,
          eliminated: const <Cell>[],
          placed: const Cell(0, 0),
          candidatesBefore: 5,
          candidatesAfter: 4,
          chainDepthSinceLastPlacement: -1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('equality and hashCode match for equivalent entries', () {
      final TraceEntry a = TraceEntry(
        family: DeductionFamily.confinement,
        eliminated: const <Cell>[Cell(0, 0)],
        placed: null,
        candidatesBefore: 8,
        candidatesAfter: 7,
        chainDepthSinceLastPlacement: 1,
      );
      final TraceEntry b = TraceEntry(
        family: DeductionFamily.confinement,
        eliminated: const <Cell>[Cell(0, 0)],
        placed: null,
        candidatesBefore: 8,
        candidatesAfter: 7,
        chainDepthSinceLastPlacement: 1,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('round-trips through JSON (placement)', () {
      final TraceEntry original = TraceEntry(
        family: DeductionFamily.giveawayCell,
        eliminated: const <Cell>[],
        placed: const Cell(2, 5),
        candidatesBefore: 50,
        candidatesAfter: 40,
        chainDepthSinceLastPlacement: 0,
      );
      expect(TraceEntry.fromJson(original.toJson()), original);
    });

    test('round-trips through JSON (elimination)', () {
      final TraceEntry original = TraceEntry(
        family: DeductionFamily.touchAllElimination,
        eliminated: const <Cell>[Cell(4, 4), Cell(4, 5)],
        placed: null,
        candidatesBefore: 20,
        candidatesAfter: 18,
        chainDepthSinceLastPlacement: 3,
      );
      expect(TraceEntry.fromJson(original.toJson()), original);
    });
  });
}
