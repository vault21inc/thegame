import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

void main() {
  group('DifficultyGrader', () {
    test('grades pure giveaway traces as easy', () {
      final DifficultyMetadata metadata = const DifficultyGrader().grade(
        SolveResult(
          solved: true,
          trace: <TraceEntry>[
            TraceEntry(
              family: DeductionFamily.giveawayCell,
              eliminated: const <Cell>[],
              placed: const Cell(0, 0),
              candidatesBefore: 16,
              candidatesAfter: 10,
              chainDepthSinceLastPlacement: 0,
            ),
          ],
          placedTokens: const <Cell>[Cell(0, 0)],
        ),
        cellCount: 16,
      );

      expect(metadata.band, Difficulty.easy);
      expect(metadata.steps, 1);
      expect(
        metadata.families,
        <DeductionFamily>{DeductionFamily.giveawayCell},
      );
    });

    test('grades confinement or touch-all traces as medium', () {
      final DifficultyMetadata metadata = const DifficultyGrader().grade(
        SolveResult(
          solved: true,
          trace: <TraceEntry>[
            TraceEntry(
              family: DeductionFamily.confinement,
              eliminated: const <Cell>[Cell(0, 0), Cell(0, 1)],
              placed: null,
              candidatesBefore: 16,
              candidatesAfter: 14,
              chainDepthSinceLastPlacement: 1,
            ),
          ],
          placedTokens: const <Cell>[],
        ),
        cellCount: 16,
      );

      expect(metadata.band, Difficulty.medium);
      expect(metadata.steps, 2);
    });

    test('grades contradiction traces as hard', () {
      final DifficultyMetadata metadata = const DifficultyGrader().grade(
        SolveResult(
          solved: true,
          trace: <TraceEntry>[
            TraceEntry(
              family: DeductionFamily.contradictionElimination,
              eliminated: const <Cell>[Cell(1, 0)],
              placed: null,
              candidatesBefore: 16,
              candidatesAfter: 15,
              chainDepthSinceLastPlacement: 1,
            ),
          ],
          placedTokens: const <Cell>[],
        ),
        cellCount: 16,
      );

      expect(metadata.band, Difficulty.hard);
    });

    test('grades higher-order confinement traces as master', () {
      final DifficultyMetadata metadata = const DifficultyGrader().grade(
        SolveResult(
          solved: true,
          trace: <TraceEntry>[
            TraceEntry(
              family: DeductionFamily.higherOrderConfinement,
              eliminated: const <Cell>[Cell(3, 4)],
              placed: null,
              candidatesBefore: 16,
              candidatesAfter: 15,
              chainDepthSinceLastPlacement: 1,
            ),
          ],
          placedTokens: const <Cell>[],
        ),
        cellCount: 16,
      );

      expect(metadata.band, Difficulty.master);
    });

    test('keeps max chain depth 6 in medium but promotes 7 to hard', () {
      final DifficultyMetadata medium = const DifficultyGrader().grade(
        _resultWithTrace(<TraceEntry>[
          _elimination(
            family: DeductionFamily.confinement,
            chainDepth: 6,
          ),
        ]),
        cellCount: 16,
      );
      final DifficultyMetadata hard = const DifficultyGrader().grade(
        _resultWithTrace(<TraceEntry>[
          _elimination(
            family: DeductionFamily.confinement,
            chainDepth: 7,
          ),
        ]),
        cellCount: 16,
      );

      expect(medium.band, Difficulty.medium);
      expect(hard.band, Difficulty.hard);
    });

    test('promotes repeated touch-all eliminations to hard', () {
      final DifficultyMetadata oneTouchAll = const DifficultyGrader().grade(
        _resultWithTrace(<TraceEntry>[
          _elimination(
            family: DeductionFamily.touchAllElimination,
            chainDepth: 1,
          ),
        ]),
        cellCount: 16,
      );
      final DifficultyMetadata twoTouchAll = const DifficultyGrader().grade(
        _resultWithTrace(<TraceEntry>[
          _elimination(
            family: DeductionFamily.touchAllElimination,
            cell: const Cell(1, 1),
            chainDepth: 1,
          ),
          _elimination(
            family: DeductionFamily.touchAllElimination,
            cell: const Cell(2, 2),
            chainDepth: 2,
          ),
        ]),
        cellCount: 16,
      );

      expect(oneTouchAll.band, Difficulty.medium);
      expect(twoTouchAll.band, Difficulty.hard);
    });
  });
}

SolveResult _resultWithTrace(List<TraceEntry> trace) {
  return SolveResult(
    solved: true,
    trace: trace,
    placedTokens: const <Cell>[],
  );
}

TraceEntry _elimination({
  required DeductionFamily family,
  required int chainDepth,
  Cell cell = const Cell(0, 0),
}) {
  return TraceEntry(
    family: family,
    eliminated: <Cell>[cell],
    placed: null,
    candidatesBefore: 16,
    candidatesAfter: 15,
    chainDepthSinceLastPlacement: chainDepth,
  );
}
