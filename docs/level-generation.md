# Level Generation

This document is the authoritative specification for the puzzle generator that produces the bundled level packs for **Skully Bones Treasure Adventure**. It extends the short summary in the root [README.md](../README.md).

## Goals

The level generator is an offline Dart CLI. For V1, it must produce a bundled pack of **500 verified 8 x 8 puzzles** that satisfy:

- **Unique solution.** Every puzzle has exactly one valid arrangement.
- **Logic-solvable.** Every solution is reachable through the official deduction set without guessing, trial-and-error, or player backtracking.
- **Graded.** Every puzzle is classified into Easy / Medium / Hard / Master using a stable, deterministic grader.
- **Distinct.** No two puzzles in the pack are equivalent under grid symmetry or region relabeling.
- **Quota-balanced.** The pack hits a target distribution across difficulty bands.
- **Curated order.** Puzzles are shipped in a player-facing order that ramps difficulty and introduces deduction families progressively.
- **Reproducible.** A given seed produces a byte-identical level pack.

## Pipeline Overview

The generator is a **generate-and-test pipeline with structured retry**. Early stages are cheap; rejections concentrate at uniqueness (Stage 3) and logic-solvability (Stage 4).

```text
┌─────────────────────────┐
│ 1. Generate Placement   │  Valid token arrangement (row/col/no-touch)
└───────────┬─────────────┘
            ▼
┌─────────────────────────┐
│ 2. Grow Regions         │  Partition into 8 connected regions
└───────────┬─────────────┘
            ▼
┌─────────────────────────┐
│ 3. Verify Uniqueness    │  Backtracking solver with early exit
└───────────┬─────────────┘
            ▼
┌─────────────────────────┐
│ 4. Verify Logic-Solve   │  Deterministic deduction simulator
└───────────┬─────────────┘
            ▼
┌─────────────────────────┐
│ 5. Grade Difficulty     │  Classify Easy / Medium / Hard / Master
└───────────┬─────────────┘
            ▼
┌─────────────────────────┐
│ 6. Canonicalize + Dedup │  Reject symmetric duplicates of accepted puzzles
└───────────┬─────────────┘
            ▼
┌─────────────────────────┐
│ 7. Enforce Band Quota   │  Reject puzzles in over-quota bands
└───────────┬─────────────┘
            ▼
┌─────────────────────────┐
│ 8. Export + Order       │  Curate play order, write versioned JSON
└─────────────────────────┘
```

Stages 1–5 operate per-candidate. Stages 6–7 filter against pack-level state. Stage 8 runs once at the end of the batch.

## Stage 1 — Generate Placement

Find a permutation σ of columns {0..7} assigned to rows {0..7} such that each row and column has exactly one token and no two tokens are adjacent.

Since one-per-row and one-per-column are guaranteed by the permutation, the only additional constraint is the no-touch rule between consecutive rows:

> For every pair of adjacent rows i and i+1: |σ(i) − σ(i+1)| ≥ 2

Rows 2+ apart already satisfy Chebyshev distance ≥ 2 automatically.

### Non-N-Queens guardrail

This project is **not** classic N-Queens. Generator, solver, validator, hint, and test code must not use full chess-diagonal attack rules. Longer shared diagonals are legal as long as tokens are not adjacent.

Required golden placement test:

- σ = `[0, 2, 4, 6, 1, 3, 5, 7]` must be accepted by the placement validator.
- This placement intentionally has tokens sharing a longer diagonal, including `(0,0)` and `(7,7)`.
- It must pass because every adjacent row pair differs by at least 2 columns.
- A classic N-Queens diagonal check would reject it; using that check here is a bug.

**Method.** Randomized backtracking. For each row, shuffle the available columns and try each. Backtrack if no column satisfies the distance constraint.

## Stage 2 — Grow Regions

Partition all 64 cells into 8 connected regions, each containing exactly one solution token.

**Method — Randomized competitive flood-fill:**

1. Seed each region at its solution token cell.
2. Build a frontier set for each region (unassigned cells orthogonally adjacent to the region).
3. Loop until all cells are assigned:
   - Select a region with a non-empty frontier, weighted toward the smallest current region.
   - Pick a random cell from that region's frontier.
   - Assign the cell to the region and update frontiers.

Regions are always contiguous by construction (frontier expansion from a connected seed).

### Edge cases

- **Empty frontier on selected region.** Select another region with a non-empty frontier. If no region has a non-empty frontier while unassigned cells remain, this is a generator bug and should assert — it cannot occur for a connected grid with orthogonal adjacency.
- **Shape quality rejection.** "Reject a layout where any region is <3 or >15" means: discard the regions, retain the placement from Stage 1, and re-run Stage 2. Retry budget is governed by the [Retry Topology](#retry-topology).

### Shape quality heuristics

- **Size balancing.** Weight region selection toward the smallest current region. Target range 5–11 cells per region (average 8). Hard reject any region <3 or >15.
- **Irregularity.** Prefer regions that wrap, bend, or have concavities over rectangular blobs.
- **Neighbor diversity.** Each region should border multiple other regions to create cross-region elimination opportunities.

### Relationship to canonical rules

The canonical rules in the README allow regions as small as 1 cell. The generator's ≥3 floor is a **shape-quality heuristic**, not a rule constraint. Hand-crafted puzzles (e.g., in a future level editor) could legitimately use smaller regions.

## Stage 3 — Verify Unique Solution

Run a backtracking solver that counts valid token placements for the generated regions, with early exit on the second solution.

**Algorithm:**

1. Process rows 0 through 7 sequentially.
2. For each row, try each candidate cell not eliminated by row / column / region / no-touch constraints from previously placed tokens.
3. If a valid placement is found for all 8 rows, increment the solution counter.
4. **Early exit:** if the counter reaches 2, immediately reject the puzzle.

**Pruning.** After each placement, for every region that has no token yet, compute the set of rows in which that region still has at least one candidate cell. If any unused region's row-set is empty, backtrack immediately. This cuts branches that would otherwise run to row 7 before discovering an unsolvable region constraint.

## Stage 4 — Verify Logic-Solvability

Simulate the deduction set on the puzzle to confirm it can be solved without guessing.

### Deduction set

The grader uses a richer vocabulary than the 4 player-facing families listed in the root README. The extra families are still pure logic (no guessing) and are needed to resolve Hard/Master puzzles that would otherwise be rejected as "stuck."

**Player-facing core (4 families, per README):**

1. **Giveaway Cell.** A row, column, or region has only one remaining candidate.
2. **Region → Row/Column Confinement.** All remaining candidates for a region lie in one row or column; eliminate other cells in that row or column.
3. **Touch-All Elimination.** A candidate outside a region is adjacent to every remaining candidate inside that region; eliminate the outside candidate.
4. **Contradiction / Blocking Elimination.** Placing a token at a candidate would eliminate all candidates in some other row, column, or region; eliminate that candidate.

**Grader extensions (2 additional families):**

5. **Row/Column → Region Confinement.** If all remaining candidates for a row or column lie within one region, eliminate all other candidates in that region. Symmetric to family 2.
6. **Higher-Order Confinement.** If the candidates for K regions collectively occupy only K rows (or K columns), those regions account for all tokens in those rows/columns; eliminate those rows/columns from every other region. Symmetric: if K rows' candidates lie in K regions, eliminate those regions from all other rows. Practical cases on 8x8 are K = 2 and K = 3.

### Design decision required

There are two viable product postures for the extended deductions:

- **Option A — Keep player vocabulary at 4 families.** The grader uses all 6. Easy/Medium/Hard are guaranteed solvable using only families 1–4. Master puzzles may additionally require families 5–6; these are taught implicitly through hint text or in-game tutorialization at Master levels. This preserves the README's current commitment.
- **Option B — Expand player vocabulary to 6 families.** Update the root README's Official Deduction Set. More upfront teaching; wider puzzle space at all difficulties.

**Recommendation: Option A.** It preserves the simpler player-facing vocabulary and confines the extended deductions to the grader and the Master band.

### Deduction ordering

When multiple deductions apply to the same candidate state, the solver must apply them in a stable, easiest-first order. This matters because:

- Difficulty grading reads the solve trace; the same puzzle can trace differently under different orderings and grade differently.
- Easiest-first models a human solver, producing grades that match perceived difficulty.

**Fixed application order** (all applications of family N are exhausted before any of family N+1 is attempted):

1. Housekeeping (after any new placement — eliminate same row, same column, same region, 3x3 no-touch neighborhood).
2. Family 1 — Giveaway Cell.
3. Family 2 — Region → Row/Column Confinement.
4. Family 5 — Row/Column → Region Confinement.
5. Family 3 — Touch-All Elimination.
6. Family 6 — Higher-Order Confinement (K = 2, then K = 3).
7. Family 4 — Contradiction / Blocking Elimination.

If any step makes progress (places a token or eliminates a candidate), restart from step 1.

### Termination

Each of the 64 cells can be eliminated at most once, and each of the 8 placements occurs at most once. The loop terminates in O(cells + placements) progress events. If a full pass makes no progress and the puzzle is not fully solved, the puzzle fails Stage 4.

### Solve trace

Record per step:

- Which family fired.
- Which cell(s) were eliminated or placed.
- The candidate count before and after.
- The chain depth since the last placement.

The trace is consumed by Stage 5.

## Stage 5 — Grade Difficulty

Classify the puzzle from the Stage 4 trace.

### Metrics

| Metric | Description |
|---|---|
| Total deduction steps | Number of individual eliminations and placements |
| Max chain depth | Longest sequence of eliminations between forced placements |
| Deduction families used | Which families fired at least once |
| First-placement depth | Elimination steps before the first token is placed |
| Candidate density at hardest point | Minimum ratio of remaining candidates to open cells |

### Bands

| Band | Criteria |
|---|---|
| Easy | Solved using families 1 + housekeeping only. First placement within 0–2 elimination steps. |
| Medium | Requires families 2 and/or 3. Chains of 3–6 eliminations between placements. |
| Hard | Requires all of families 1–4. Chains of 7–12 eliminations. Multiple family-3 or family-4 steps. |
| Master | Requires family 5 or family 6 at least once. Chains of 12+, tight candidate layouts, high first-placement depth. |

Thresholds are heuristic and should be **calibrated** against a small fixture set of hand-rated puzzles before the full 500-pack generation run.

### Determinism

Because the deduction order is fixed (see [Deduction Ordering](#deduction-ordering)), the trace is deterministic for a given puzzle, and grades are stable across runs and across seeds.

## Stage 6 — Canonicalization and Deduplication

Two candidates are equivalent if one can be obtained from the other by:

- One of the 8 dihedral grid symmetries (4 rotations × reflection).
- Relabeling of region IDs (region identity is arbitrary — 8! relabelings).

The generator maintains a **seen-set** of canonical hashes. A candidate is rejected if its canonical form is already present.

### Canonical form

1. For each of the 8 dihedral symmetries, apply the symmetry to the (placement, regions) pair.
2. In each transformed pair, relabel regions in order of first appearance when scanning cells in row-major order. This yields a canonical region labeling.
3. Serialize each of the 8 labeled pairs to a fixed-format string.
4. The canonical form is the lexicographically smallest of the 8 serializations.
5. The canonical hash is a SHA-256 of the canonical form.

### Near-duplicates

Strict equivalence under the dihedral group + region relabeling catches exact duplicates. Two puzzles can be distinct under this group but still feel similar (e.g., a small local shape change). Near-duplicate detection is **out of scope for V1**; the 500-pack size is small enough that final manual review can catch any survivors.

## Stage 7 — Enforce Band Quota

The generator targets a distribution rather than accepting whatever yield produces.

**Suggested V1 distribution (500 puzzles):**

| Band | Count | Share |
|---|---:|---:|
| Easy | 200 | 40% |
| Medium | 175 | 35% |
| Hard | 100 | 20% |
| Master | 25 | 5% |

Each band tracks its accepted count. Candidates graded into a band that has already met quota are rejected. This means the batch run may spend most of its time chasing the last few Master puzzles; that is expected.

Flags:

- `--quota easy=200,medium=175,hard=100,master=25` overrides the default distribution.
- `--over-fill` disables quota enforcement and accepts all valid puzzles (useful during exploration and calibration).

## Stage 8 — Export and Level Ordering

Run once at the end of the batch, after all quotas are met.

### Ordering

1. Within each band, sort by internal difficulty score (e.g., total deduction steps × max chain depth).
2. Interleave bands to produce a ramp:
   - **Levels 1–50:** Easy only.
   - **Levels 51–200:** Easy-dominant, with gradual Medium introduction.
   - **Levels 201–350:** Medium-dominant, with Hard introduced.
   - **Levels 351–475:** Hard-dominant, with early Master appearances.
   - **Levels 476–500:** Master and top-tier Hard.
3. Within each segment, alternate between **teaching** puzzles (the trace exercises one new deduction family prominently) and **integration** puzzles (the trace exercises a combination). The Stage 4 trace labels which families each puzzle uses.
4. Generate a proposed order; the final order is reviewed manually before shipping.

### Puzzle JSON structure

```json
{
  "id": "level_0001",
  "version": 1,
  "size": 8,
  "regions": [
    {"id": 0, "cells": [[0,0], [0,1], [1,0], [1,1], [2,0]]},
    {"id": 1, "cells": [[0,2], [0,3], [1,2], [1,3], [1,4]]}
  ],
  "solution": [[0,5], [1,7], [2,3], [3,1], [4,6], [5,0], [6,4], [7,2]],
  "difficulty": {
    "band": "medium",
    "steps": 14,
    "maxChainDepth": 5,
    "families": [1, 2, 3],
    "firstPlacementDepth": 3
  }
}
```

### Pack metadata

The pack file also stores:

- Top-level RNG seed.
- Generator version (semver).
- Pipeline parameter values (quota, retry budgets, band thresholds).
- Per-band accepted count.

The seed + version + parameters are sufficient to regenerate a byte-identical pack.

### Solution storage

V1 is a pay-once offline game. Aggressive solution obfuscation offers little defense against a determined data-miner and adds generator/runtime complexity. **Default: store solutions as plain arrays in bundled JSON.** Revisit only if a specific leak-and-share scenario emerges.

## Retry Topology

Rejection at any per-candidate stage triggers a retry with a budget. Budgets prevent infinite loops on degenerate seeds and keep batch runtime bounded.

| Rejection source | Retry at | Budget |
|---|---|---:|
| Stage 2 shape-quality rejection | Stage 2 with same Stage 1 placement | 5 |
| Stage 3 (not unique) | Stage 2 with same Stage 1 placement | 3 |
| Stage 4 (not logic-solvable) | Stage 2 with same Stage 1 placement | 3 |
| Any budget exhausted | Stage 1 (new placement) | — |
| Stage 6 (duplicate) | Stage 1 | — |
| Stage 7 (over-quota band) | Stage 1 | — |

Each Stage 1 placement thus produces up to a handful of region layouts. The batch continues until quotas are met or a top-level `--max-candidates` limit is reached.

## Yield and Performance

Expected per-stage yield (approximate, to be validated during implementation):

- Stage 1 (valid placement): near 100% with randomized backtracking.
- Stage 3 (unique solution): 5–20% of candidates pass. Primary rejection point.
- Stage 4 (logic-solvable): 30–70% of unique-solution puzzles pass, depending on shape quality.
- Stage 6 (dedup survival): >95% early in the run, dropping as the seen-set grows.
- Stage 7 (band quota): near 100% until a band saturates; approaches 0% for the last saturating band.
- **Overall yield:** roughly 2–14% of generated candidates become accepted puzzles early in the run; lower as quotas saturate.

**Performance target.** At N = 8, each candidate (placement + region growth + uniqueness check + logic-solve) should complete in under 50 ms on modern hardware. A 500-puzzle batch should complete in under 30 minutes including the long tail of Master quota hunting.

**Yield improvements.**

- Bias region growth toward irregular, balanced shapes.
- Retry region growth multiple times per valid placement (see [Retry Topology](#retry-topology)).
- Track which region patterns correlate with uniqueness and logic-solvability; use this to guide the growth heuristic over time.

## Reproducibility

The generator CLI accepts `--seed <int>`. A given seed + generator version + pipeline parameters produces a byte-identical level pack, including the final play order (sort ties are broken deterministically by canonical hash).

The seed, version, and parameters are written to the pack metadata so a pack can be regenerated from its metadata alone. This is important for:

- Reproducing a reported bug in a shipped pack.
- Regenerating a pack after a generator bug fix without manual re-curation.
- Auditing the content pipeline.

## Difficulty Metadata per Puzzle

Each exported puzzle carries:

- Board size.
- Band (Easy / Medium / Hard / Master).
- Total deduction steps.
- Max chain depth.
- Deduction families required.
- First-forced-placement depth.
- Candidate density at the hardest point.
