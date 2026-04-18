
 
# Is the rule set exactly “1-star Star Battle”: one per row, column, region, and no adjacent cells including diagonals?

Exact Rule Breakdown (Identical to 1-Star Star Battle)

On an **N × N grid** divided into **exactly N irregular colored regions**:

- Place **exactly one queen** in **each row**.
- Place **exactly one queen** in **each column**.
- Place **exactly one queen** in **each colored region**.
- **No two queens may touch** — not even diagonally. → This is the strict “no-touch” / adjacency ban: queens must be separated by at least one cell in all **8 directions** (Chebyshev distance ≥ 2). → Placing a queen instantly forbids its entire 3×3 neighborhood (except the center cell itself).

That is **precisely** the definition of a **1-star Star Battle** (also called “Queens” in some puzzle communities). Standard Star Battle rules state: “For 1☆ puzzles, you have to place 1 star on each row, column and shape. 2 stars cannot be adjacent horizontally, vertically or diagonally.” Replace “star” with “queen” and “shape” with “colored region,” and you have _Queens Master_.

# Must every puzzle have a unique solution?

**Yes — every puzzle _ has exactly one unique solution.**

Each level should have a **single logical solution** that can be completed **without guessing**.
we should aim for  over 5,000 unique puzzles in the game with a **single logical solution**

### What “Unique Solution” Means in This Game

Because the game combines:

- One queen per row
- One queen per column
- One queen per colored region
- Strict no-touch rule (no two queens adjacent in any of the 8 directions)

…there is **exactly one** valid arrangement of queens on the board that satisfies **all** these constraints simultaneously.

No other placement of queens will work. There are no “multiple valid ways to finish the level.” If you reach a point where two different placements both seem possible, you simply haven’t applied enough logical deductions yet (or you need a hint to reveal the next forced move).

### Why This Matters for Gameplay

- **No guessing required**: The lives system (losing a life on a wrong double-tap) exists to punish careless placement, **not** because the puzzle is ambiguous. Every correct placement is forced by logic.
- **Pure deduction**: Advanced players can solve even the hardest levels using only X-marks, region/row/column eliminations, and the no-touch blocking — exactly like well-designed Star Battle or Sudoku puzzles.
- **Generator design**: The game’s puzzle generator (like the one discussed in similar “Queens” puzzle development threads) is tuned to produce only boards that have exactly one solution. This is standard practice for modern logic-puzzle apps to avoid player frustration.


# Does double-tap validate against a hidden solution immediately, or only against visible rule violations?

**Double-tap validates immediately against the hidden/predefined unique solution.**

The game does **not** only check for visible/current rule violations (e.g., “does this row/column/region already have a queen?” or “is it adjacent to an existing queen?”). Instead, it performs an instant server-side or client-side lookup against the puzzle’s single correct answer grid.

### What This Means in Practice

- When you double-tap a cell:
    - The game instantly compares that exact cell to the one pre-determined queen location for that puzzle.
    - If it matches the solution → queen is placed (and all the usual auto-marking of row/column/region/no-touch cells happens).
    - If it does **not** match the solution → immediate life loss, even if:
        - The cell is still logically possible based on what you’ve marked so far.
        - No visible rule has been broken yet (no duplicate in row/column/region, not adjacent to any placed queen).
- You cannot place a “temporarily valid but ultimately wrong” queen. The lives system exists precisely to punish incorrect guesses against the hidden answer.
### Why the Game Is Designed This Way

- It preserves the “pure logic, no guessing required” promise while adding mobile-friendly risk/reward tension.
- Because every puzzle is generated with **exactly one unique solution**, the hidden-key check is mathematically equivalent to a perfect forward-looking validator.
- It prevents any possibility of “phantom” boards where you could place something that doesn’t immediately conflict but leads to a dead end later.
- 
In short: **yes, double-tap checks the hidden solution immediately**. It is a true guess against the answer key, not a soft “does this break any rules I can see right now?” check. That’s what makes the three-life limit feel meaningful even on fully logical puzzles. 👑

If you ever lose a life on a placement that “looked possible,” that’s exactly why — the cell simply wasn’t the one the puzzle’s designer hid there.

# What counts as “logic-solvable,” and which solving techniques are allowed for difficulty grading?

**“logic-solvable” in _The Game_ has a precise, developer-defined meaning.**

**every puzzle (all 5,000+ levels, daily challenges, and events) is solvable with pure logical deduction alone**. No guessing, no trial-and-error, and no backtracking are required. Every valid move or elimination follows deterministically from the core rules (one queen per row, column, colored region + strict no-touch in all 8 directions). 

### The 4 Key Logical Deductions 

there are exactly **four core logical deductions**. These are the techniques the hint system reveals and the ones used to grade difficulty. They are applied repeatedly in chains until the board unlocks.

|#|Deduction Name|What It Is|When It Applies|Example Use Case|
|---|---|---|---|---|
|1|**Giveaway Cell** (Naked Single / Forced Placement)|A color/region has only **one** unmarked cell left → place queen there.|After basic eliminations reduce a region to 1 spot.|Most common early-game move; often available right at the start.|
|2|**Confinement / Row-Column Forcing**|All remaining possibles in a color lie in the **same row** (or column) → X out the rest of that row/column outside the color.|A color is fully contained within 1–2 rows/columns.|“Two colors are locked into the same two rows → eliminate those rows elsewhere.”|
|3|**Touch-All Elimination** (Minesweeper-style adjacency)|Any outside cell that **touches every remaining possible cell** in a color (including diagonally) can be safely X’ed.|L-shapes, pairs, or clusters where one external cell blocks all options.|Classic: an adjacent pair in a color lets you X the six surrounding cells that touch both.|
|4|**Contradiction / Blocking Elimination**|If placing a queen here would **eliminate all remaining possibles** in _another_ color, then X this cell.|A candidate creates an immediate dead-end for a different region.|The “negative” version of forcing; often appears after steps 1–3 thin the board.|

**Basic housekeeping rules** 

- X everything in the same color as a placed queen.
- X the entire 3×3 no-touch zone around a placed queen.
- X the rest of the row and column of a placed queen.

Once you apply the 4 key deductions (plus housekeeping) in any order, repeating until nothing new appears, you will always reach the next giveaway cell. The loop continues until the puzzle is solved.

### How Difficulty Is Graded

difficulty is balanced internally by:

- **Number and depth of deduction chains** required.
- **How hidden/obscure** the applications of the 4 keys are (e.g., subtle touch-all cases across multiple colors, long chains spanning the whole board).
- **Region complexity** (irregular shapes that create tricky confinements or near-misses).
- **Early-game vs. late-game forcing** (easy levels give several giveaway cells immediately; hard levels require 10–20+ layered eliminations before the first safe placement).
- **Easy** (e.g., Daily Mini “EASY”): Mostly #1 (giveaways) + basic eliminations.
- **Medium**: Heavy use of #2 and #3; short chains.
- **Hard / Master**: Full chaining of all 4, especially repeated #3 and #4; very tight boards where one missed touch-all stalls progress.

The hint system should explicitly tells the player _which_ of the 4 deductions to apply next, making it a teaching tool rather than a crutch.


In short: “logic-solvable” = solvable with repeated, deterministic applications of the four official deductions (plus basic housekeeping). Difficulty scales purely by how deeply and cleverly you must combine them. The hint button is your built-in tutor for the exact technique you’re missing.

# Is the first build offline/local, or does it require accounts, server config, A/B tests, events, and remote rewards?

first build will be local. accounts should be a later phase implementation

# What is the v1 reward scope: simple stars/coins, or full Treasure chests, pets, shards, events, and live ops?

lets start with stars/coins first with the later rewards coming in later phases

# Are randomized rewards affected by ads or IAP? If yes, compliance needs to be part of the design from day one.

remove any adds or IAP from the documentation. this will be a pay once and done game

# How should hints, boosters, lives, and pets affect score, stars, leaderboards, and the “no guessing” promise?

**Hints, boosters, lives, and pets** all interact with the game’s performance metrics (**stars** and **score**), **leaderboards**, and the official “no guessing / pure logic” 

Stars are the primary currency for progression, leaderboards, and Treasure rewards.

### Stars & Score Overview

- You earn **stars per completed puzzle** (typically 1–3 per level).
- Total accumulated stars determine your position on the **global leaderboard**.
- Extra stars come from:
    - **Perfect clears** (no lives lost).
    - **Timed levels** (race the clock for bonus stars).
    - **Daily missions / streaks** (streak badges displayed on leaderboard).
- Leaderboards also factor in **streak badges** and event rankings (Royal Tournament, etc.). Higher stars = higher rank.

### How Each Feature Affects Stars, Leaderboards, and the “No Guessing” Promise

|Feature|Effect on Stars / Score|Effect on Leaderboards|Effect on “No Guessing” Promise|
|---|---|---|---|
|**Lives** (3 per puzzle)|Losing any life **reduces stars** earned for that level. 0 lives lost = maximum stars (likely 3). 0 lives left = level fail (no stars until restart).|Directly hurts ranking. Perfect runs maximize total stars and streaks.|**Preserved** — wrong double-taps are punished precisely because the puzzle has one hidden logical solution. Lives enforce careful logic, not guessing.|
|**Hints** (improved system)|No confirmed penalty. Hints reveal one of the 4 official logical deductions (giveaway, confinement, touch-all, contradiction). hints are explicitly a teaching tool for pure logic.
- The game **never forces** hints, boosters, or pets. Everything is optional. The “no guessing” promise remains 100% intact because **every puzzle is designed with one unique logical solution** solvable via the four official deductions alone.
- Using aids is **not** considered “cheating” — it’s encouraged for accessibility and fun. However, for maximum leaderboard clout and Treasure payouts, pure-logic perfect runs are the meta.
- Daily missions and events often reward extra stars/coins regardless of aids used, keeping the loop rewarding.

In short: **Lives** are the biggest star killer (and the main risk/reward mechanic). **Hints** are the “purest” aid and don’t hurt your score much (if at all). **Boosters** trade convenience for lower stars. **Pets** give you a gentle boost to both fun and rewards.

### all of that said, global leaderboard is a late stage development goal. 

# Are 5,000+ levels an actual launch requirement, or just a long-term content ambition?

long term ambition. a first phase minimum set should be at least 500. Ideally, we'd determine an intelligent algorithm to create levels. 