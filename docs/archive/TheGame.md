# Project Logic Grid - Core Game Concept

`Project Logic Grid` is the current working title. The name is intentionally generic so it can be replaced later without changing the underlying mechanics. In implementation notes, use `piece` or `token` for the placed object. The current theme can present that object as a queen.

## Canonical Rule Set

The core puzzle is exactly a 1-star Star Battle variant.

On an N x N grid divided into exactly N irregular colored regions:

- Place exactly one piece in each row.
- Place exactly one piece in each column.
- Place exactly one piece in each colored region.
- No two pieces may touch, including diagonally.

The no-touch rule means pieces must be separated by at least one cell in all 8 directions. Equivalently, a placed piece forbids its entire 3x3 neighborhood except the center cell itself. The game does not use full chess-queen diagonal attacks; pieces may share a longer diagonal as long as they are not adjacent.

## Solution Requirements

Every puzzle must have exactly one valid solution.

A valid solution is the only arrangement of N pieces that satisfies all row, column, region, and no-touch constraints. Multiple valid endings are not allowed. The level generator and validation tools must reject boards with zero solutions or more than one solution.

Every puzzle must also be logic-solvable. Search/backtracking can be used by developer tooling to verify uniqueness, but the player-facing solve path must be expressible through the approved deduction set below.

## Player Interaction

- Single tap: toggle an X mark on a cell to mark it as impossible.
- Double tap: attempt to place the piece in that cell.
- Correct double tap: the piece is placed.
- Incorrect double tap: the player loses 1 life.
- The player starts each puzzle with 3 lives.
- Reaching 0 lives fails the puzzle and requires a restart.

Double-tap validation checks the hidden unique solution immediately. It is not only a visible rule check. A cell can look temporarily possible based on the player's current marks and still be wrong if it is not the solution cell for that row/region.

After a correct piece placement, the game should perform housekeeping marks:

- X all other cells in the same row.
- X all other cells in the same column.
- X all other cells in the same colored region.
- X all cells in the 3x3 no-touch neighborhood around the piece.

X marks should be individually toggleable in v1 unless a later UX decision changes this. A clear-all-X control can exist as a convenience action.

## Logic-Solvable Definition

Logic-solvable means the puzzle can be completed without guessing, trial-and-error, or player backtracking. The official solve path uses these four deduction families plus placement housekeeping.

| # | Deduction | Meaning | Typical Difficulty Use |
|---|---|---|---|
| 1 | Giveaway Cell | A row, column, or colored region has only one remaining possible cell, so the piece must go there. | Easy and early levels |
| 2 | Confinement / Row-Column Forcing | All remaining candidates for a region lie in the same row or column, so other cells in that row or column can be eliminated. | Medium levels and short chains |
| 3 | Touch-All Elimination | A candidate outside a region touches every remaining candidate inside that region, so the outside candidate can be eliminated. | Medium to hard spatial reasoning |
| 4 | Contradiction / Blocking Elimination | Placing a piece in a candidate cell would immediately eliminate all candidates in another row, column, or region, so that candidate can be eliminated. | Hard and master levels |

The hint system should identify the next useful deduction by name and show why it applies. Hints are a teaching tool for the official logic, not a replacement for it.

## Difficulty Grading

Difficulty should be based on:

- Number of required deduction steps.
- Depth of deduction chains before the next forced placement appears.
- Which deduction families are required.
- How visually obvious or hidden the deductions are.
- Region complexity and candidate density.
- Whether early progress is available immediately or only after layered eliminations.

Suggested bands:

- Easy: mostly Giveaway Cell plus housekeeping.
- Medium: frequent Confinement and Touch-All cases with short chains.
- Hard: all four deduction families, including repeated Touch-All and Contradiction chains.
- Master: long chains, subtle spatial eliminations, and tight candidate layouts.

## V1 Scope

The first build is local/offline.

Included in v1:

- Core puzzle board.
- Local level selection.
- At least 500 curated or generated-and-verified puzzles.
- Unique-solution validation tooling.
- Logic-solve validation using the official deduction set.
- Three-life puzzle attempts.
- X marks, auto-housekeeping, undo/restart, and hints.
- Simple stars and coins progression.

Deferred to later phases:

- Accounts.
- Global leaderboards.
- Daily missions, streak badges, events, and tournaments.
- Pets, cosmetics, shards/fragments, and advanced Treasure systems.
- Remote config, server-delivered levels, A/B testing, or live operations.

## Progression Direction

The game is pay-once. Do not design around post-purchase monetization.

V1 progression should stay simple:

- Completed levels award stars and coins.
- Losing lives reduces the star reward.
- A perfect clear earns the maximum star reward.
- Hints may be allowed without a penalty or with a small score/star penalty; this must be decided before scoring is implemented.
- Boosters and pets are not v1 features.

The long-term content ambition is 5,000+ unique puzzles. The first phase target is at least 500 puzzles, ideally produced by an intelligent generator and then verified for uniqueness and logic-solvability.
