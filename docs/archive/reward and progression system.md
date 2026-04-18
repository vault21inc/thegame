# Progression System

This document describes the active progression direction for `Project Logic Grid`. It supersedes earlier reward notes that assumed post-purchase monetization, live events, remote configuration, or account-based leaderboards.

## Product Model

The game is pay-once.

Do not design around:

- Paid continues.
- Paid loot boxes.
- Paid randomized reward boosts.

## V1 Progression Loop

The first build should be local/offline and focused on puzzle completion:

1. Player selects a level.
2. Player solves the puzzle using logic, marks, and optional hints.
3. The level awards stars based primarily on lives remaining.
4. The level awards coins as a simple local progression currency.
5. Progress unlocks more levels or level packs.

## Stars

Stars are the primary progression metric.

Recommended v1 behavior:

- 3 stars: clear with 0 lives lost.
- 2 stars: clear with 1 life lost.
- 1 star: clear with 2 lives lost.
- 0 stars: fail after reaching 0 lives.

Timed levels, streak badges, daily missions, events, and global leaderboards are later-phase systems. Do not make v1 scoring depend on them.

## Coins

Coins are an earnable local currency. Their v1 purpose should remain narrow.

Possible uses:

- Unlock optional cosmetic themes.
- Pay for extra hints if the design wants a lightweight economy.
- Track long-term progress without requiring accounts.

Coins must not be connected to paid purchases in the current design.

## Hints

Hints should reveal one of the four official deduction types:

- Giveaway Cell.
- Confinement / Row-Column Forcing.
- Touch-All Elimination.
- Contradiction / Blocking Elimination.

Hints should explain why the deduction applies. They preserve the no-guessing promise because they teach the intended logic path.

Open scoring decision: determine whether hint usage affects stars, score, coins, or only solve time.

## Deferred Systems

The following are long-term ideas, not v1 requirements:

- Global leaderboards.
- Accounts and cloud sync.
- Daily missions.
- Streak badges.
- Events and tournaments.
- Pets with passive benefits.
- Cosmetic shards/fragments.
- Treasure chest reward presentation.
- Remote level delivery.
- Remote economy tuning.

These systems should be designed only after the core puzzle loop, generator, validator, and local progression are stable.
