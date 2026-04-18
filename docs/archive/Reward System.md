# Reward System - V1 and Later Phases

The game is pay-once. Do not design around post-purchase monetization or randomized real-money reward mechanics.

## V1 Reward Scope

V1 should use a simple local progression system:

- Stars: primary performance/progression metric.
- Coins: local earnable currency for non-paid convenience features, such as hints or cosmetic unlocks if those are included.
- No accounts.
- No global leaderboards.
- No server-side configuration.
- No randomized reward system required for launch.

## Star Awards

The exact values can be tuned, but the rules should be internally consistent with 3 lives per puzzle:

| Result | Stars | Notes |
|---|---:|---|
| Perfect clear, 0 lives lost | 3 | Best standard outcome |
| Clear with 1 life lost | 2 | Successful but imperfect |
| Clear with 2 lives lost | 1 | Lowest successful clear |
| 0 lives remaining | 0 | Puzzle failed; restart required |

There is no "clear with 3 lives lost" tier unless the life model changes.

## Coin Awards

Coins can be awarded locally for completed levels. Suggested first-pass ranges:

| Result | Coins |
|---|---:|
| Perfect clear | 100 |
| Clear with 1 life lost | 60 |
| Clear with 2 lives lost | 30 |

Coin sinks should stay minimal in v1. If hints cost coins, the cost must not make the puzzle feel paywalled, since the product is pay-once and every puzzle is intended to be solvable by logic.

## Hints and Boosters

Hints are part of v1 because they teach the official deduction system. Before scoring is implemented, decide whether hints:

- Have no star penalty.
- Reduce score only.
- Reduce maximum stars for that level.

Boosters are not v1 scope. If added later, they should be optional convenience tools and should not be required for any puzzle.

## Later-Phase Reward Ideas

Later phases can add:

- Cosmetic themes.
- Pets or companions.
- Daily missions and streaks.
- Local achievements.
- Optional treasure chest presentation for level rewards.
- Larger content packs.
- Global leaderboards after accounts exist.

Randomized rewards can exist only as non-paid local progression unless a future compliance review explicitly approves another model.

## Local Configuration

For v1, reward values can live in local data files so they are easy to tune during development. Remote config, live operations, A/B testing, and server-segmented rewards are out of scope for the first build.
