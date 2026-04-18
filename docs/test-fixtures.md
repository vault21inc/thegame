# Test Fixtures

This document specifies the test fixtures required before the `puzzle_core` package can be considered complete. Fixtures fall into two categories:

1. **Synthetic deduction-family scenarios.** Small hand-designed candidate-grid states that exercise each deduction family in isolation. These can be hand-verified and are authored as part of `puzzle_core`'s unit tests.
2. **Full-puzzle fixtures.** End-to-end `PuzzleDefinition` JSON files at three difficulty bands (Easy, Medium, Hard). These verify uniqueness, full logic-solve paths, and difficulty grading against real puzzles.

Because hand-authored 8x8 puzzles are difficult to hand-verify for uniqueness, the full-puzzle fixtures must be produced by the solver itself during an initial CLI run. The steps below describe exactly how that run is performed.

---

## 1. Synthetic deduction-family scenarios

Each scenario is a small (typically 3x3–5x5) candidate grid with a pre-placed context that exercises exactly one deduction family. These are authored by hand in the `puzzle_core` test suite.

A scenario fixture declares:

```
- setup:          a candidate grid (cells marked candidate / eliminated / placed) + region layout
- expected:       the family that should fire next, plus the expected eliminations or placement
- non-expected:   the families that should NOT fire (used to catch over-triggering)
```

### Required scenarios

| ID | Family under test | Scenario summary |
|---|---|---|
| S1-giveaway-row | 1 — Giveaway Cell | Row has 4 columns; 3 are eliminated. The remaining cell must be placed. |
| S1-giveaway-region | 1 — Giveaway Cell | A 5-cell region has 4 cells eliminated. The remaining cell must be placed. |
| S2-confinement-region-to-row | 2 — Confinement | All candidates of a region lie in a single row. Other cells of that row in other regions should be eliminated. |
| S2-confinement-row-to-region | 2 — Confinement | All candidates of a row lie within a single region. Other cells of that region should be eliminated. |
| S3-touch-all | 3 — Touch-All Elimination | A region has exactly 3 remaining candidates in a tight L-shape. An outside candidate touches all three. The outside candidate should be eliminated. |
| S4-contradiction | 4 — Contradiction Elimination | Placing a candidate would empty some other region's candidate set. That candidate should be eliminated. |
| S5-higher-order-K2 | 5 — Higher-Order Confinement | Two regions' candidates collectively occupy exactly 2 rows. Those rows should be eliminated from all other regions. |
| S5-higher-order-K3 | 5 — Higher-Order Confinement | Three regions' candidates collectively occupy exactly 3 columns. Those columns should be eliminated from all other regions. |

### Negative scenarios

To protect against over-triggering:

| ID | Scenario |
|---|---|
| N-giveaway-noop | Every row/column/region has at least 2 candidates. Family 1 must not fire. |
| N-confinement-noop | A region has candidates across 2 different rows AND 2 different columns. Family 2 must not fire. |
| N-touchall-noop | An outside candidate touches all but one of a region's candidates. Family 3 must not fire. |
| N-contradiction-noop | Every placement leaves every other row/column/region with at least one candidate. Family 4 must not fire. |
| N-higherorder-noop | Three regions' candidates collectively occupy 4 rows. Family 5 must not fire. |

### Ordering scenarios

To protect the fixed deduction ordering defined in [docs/level-generation.md §Deduction ordering](level-generation.md#deduction-ordering):

| ID | Scenario |
|---|---|
| O-family-1-before-2 | A state where both Family 1 and Family 2 would fire. Trace must show Family 1 firing first. |
| O-family-2-before-3 | Both Family 2 and Family 3 would fire. Family 2 must fire first. |
| O-family-3-before-4 | Both Family 3 and Family 4 would fire. Family 3 must fire first. |
| O-family-4-before-5 | Both Family 4 and Family 5 would fire. Family 4 must fire first. |

### Authoring format

Scenarios are authored in Dart, not in JSON, because they are unit-test inputs and benefit from type checking. A suggested shape:

```dart
final scenarioS1GiveawayRow = DeductionScenario(
  id: 'S1-giveaway-row',
  gridSize: 5,
  regions: [ /* ... */ ],
  initialState: /* CandidateGrid snapshot */,
  expectedStep: ExpectedStep.placement(cell: Cell(1, 3), family: DeductionFamily.giveawayCell),
  forbiddenFamilies: {},
);
```

These scenarios belong in `packages/puzzle_core/test/deduction_scenarios/`.

---

## 2. Full-puzzle fixtures

Three verified 8x8 puzzles, one at each of Easy / Medium / Hard. The Master band is not fixture-tested at this stage — Master puzzles are validated end-to-end by the CLI over a sample of the generated pack.

### Why these aren't hand-authored

Hand-authoring an 8x8 Star Battle puzzle so that it has exactly one valid solution AND is solvable with a specific subset of deduction families is **significantly** harder than it looks. A naive hand design typically produces either multiple solutions or requires deductions outside the target family set. Rather than ship incorrect fixtures, the project produces these fixtures via a deterministic pipeline run once the generator and solver are in place.

### How to produce the fixtures

This is a one-time bootstrap step. Once complete, the three JSON files live under `packages/puzzle_core/test/fixtures/` and are committed to the repo.

**Prerequisites:** `puzzle_core` validator + uniqueness solver + logic solver + difficulty grader must all be implemented.

**Steps:**

1. Run the generator CLI with a fixed seed and a small candidate budget, e.g.:
   ```
   dart run tools/level_generator -- \
     --seed 1 \
     --count 50 \
     --quota easy=20,medium=20,hard=10,master=0 \
     --output /tmp/bootstrap_pack.json
   ```
2. From the produced pack, select:
   - The Easy puzzle with the **lowest** difficulty score (earliest forced placement, fewest steps).
   - The Medium puzzle with the **median** difficulty score.
   - The Hard puzzle with the **highest** difficulty score within its band.
3. For each selected puzzle:
   - Copy its JSON to `packages/puzzle_core/test/fixtures/fixture_easy.json` / `fixture_medium.json` / `fixture_hard.json`.
   - Capture the expected solve trace (the full list of `TraceEntry` produced by the logic solver) to an accompanying `.trace.json` file.
   - Commit both files.
4. Record the seed, generator version, and selection criteria in `packages/puzzle_core/test/fixtures/README.md` so the fixtures can be regenerated if the generator changes.

### What the fixtures are tested against

Each fixture supports multiple tests in the `puzzle_core` suite:

| Test | Assertion |
|---|---|
| JSON round-trip | `fromJson(toJson(p)) == p` |
| Placement validator | The fixture's stored solution passes `PlacementValidator.validate`. |
| Solution validator | `SolutionValidator.isSolutionCell` returns true for each stored solution cell and false for every other cell. |
| Uniqueness | `UniquenessSolver.countSolutions(p) == 1`. |
| Logic solvability | `LogicSolver.solve(p).solved == true`. |
| Deterministic trace | `LogicSolver.solve(p).trace == storedExpectedTrace` (exact match). |
| Difficulty grading | The grader's classification of the solve trace equals the fixture's recorded `Difficulty`. |
| Family usage | The fixture's recorded families match the set of families appearing in the expected trace. |

### Expected trace format

The trace companion file uses the same JSON encoding as an in-memory `List<TraceEntry>`:

```json
[
  {
    "family": "giveawayCell",
    "placed": [3, 1],
    "eliminated": [],
    "candidatesBefore": 42,
    "candidatesAfter": 34,
    "chainDepth": 0
  },
  {
    "family": "confinement",
    "placed": null,
    "eliminated": [[0, 4], [0, 5]],
    "candidatesBefore": 34,
    "candidatesAfter": 32,
    "chainDepth": 1
  }
]
```

Families use the `DeductionFamily` enum's `.name` strings (e.g., `"giveawayCell"`, `"confinement"`, `"touchAllElimination"`, `"contradictionElimination"`, `"higherOrderConfinement"`).

### Updating fixtures

Fixtures are regenerated only when:

- The generator algorithm meaningfully changes (not just a bug fix).
- The deduction ordering rule changes.
- The JSON schema version is bumped.

When updated, the seed and selection criteria in `fixtures/README.md` must be updated alongside the JSON files, and the change must be called out in the commit message.

---

## 3. Coverage expectations

Before `puzzle_core` is considered complete:

- All 8 synthetic scenarios in the "Required scenarios" table pass.
- All 5 negative scenarios in the "Negative scenarios" table pass.
- All 4 ordering scenarios pass.
- All 3 full-puzzle fixtures pass all 8 assertions in the "What the fixtures are tested against" table.
- `dart test` reports zero failures and zero skips in `packages/puzzle_core`.
