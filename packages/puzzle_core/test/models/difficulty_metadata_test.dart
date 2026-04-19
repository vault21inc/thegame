import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

DifficultyMetadata _build({
  Difficulty band = Difficulty.easy,
  int steps = 5,
  int maxChainDepth = 2,
  Set<DeductionFamily>? families,
  int firstPlacementDepth = 1,
  double minCandidateDensity = 0.5,
}) {
  return DifficultyMetadata(
    band: band,
    steps: steps,
    maxChainDepth: maxChainDepth,
    families: families ?? <DeductionFamily>{DeductionFamily.giveawayCell},
    firstPlacementDepth: firstPlacementDepth,
    minCandidateDensity: minCandidateDensity,
  );
}

void main() {
  group('Difficulty enum', () {
    test('round-trips via name', () {
      for (final Difficulty d in Difficulty.values) {
        expect(difficultyFromJson(d.name), d);
      }
    });

    test('rejects unknown values', () {
      expect(() => difficultyFromJson('legendary'), throwsFormatException);
      expect(() => difficultyFromJson(42), throwsFormatException);
    });
  });

  group('DeductionFamily enum', () {
    test('round-trips via name', () {
      for (final DeductionFamily f in DeductionFamily.values) {
        expect(deductionFamilyFromJson(f.name), f);
      }
    });

    test('rejects unknown values', () {
      expect(() => deductionFamilyFromJson('nope'), throwsFormatException);
    });
  });

  group('DifficultyMetadata', () {
    test('equality matches field-by-field', () {
      expect(_build(), equals(_build()));
      expect(_build().hashCode, _build().hashCode);
      expect(_build(steps: 1), isNot(equals(_build(steps: 2))));
    });

    test('rejects negative numeric fields', () {
      expect(() => _build(steps: -1), throwsA(isA<AssertionError>()));
      expect(
        () => _build(maxChainDepth: -1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => _build(firstPlacementDepth: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects candidate density outside [0, 1]', () {
      expect(
        () => _build(minCandidateDensity: -0.1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => _build(minCandidateDensity: 1.1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('stored families collection is unmodifiable', () {
      final DifficultyMetadata m = _build();
      expect(
        () => m.families.add(DeductionFamily.higherOrderConfinement),
        throwsUnsupportedError,
      );
    });

    test('round-trips through JSON', () {
      final DifficultyMetadata original = _build(
        families: <DeductionFamily>{
          DeductionFamily.giveawayCell,
          DeductionFamily.confinement,
          DeductionFamily.touchAllElimination,
        },
      );
      expect(DifficultyMetadata.fromJson(original.toJson()), original);
    });
  });
}
