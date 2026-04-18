# Star Battle Reference

Star Battle is the direct rules inspiration for `Project Logic Grid`.

The intended game is a 1-star Star Battle variant with a swappable visual theme. If the theme uses queens, the pieces are still governed by Star Battle no-touch rules, not full chess-queen diagonal attacks.

## Core Star Battle Rules

Star Battle puzzles use an N x N grid divided into N irregular regions.

For a K-star puzzle:

- Place exactly K stars in every row.
- Place exactly K stars in every column.
- Place exactly K stars in every region.
- No two stars may touch horizontally, vertically, or diagonally.

For this project, K = 1.

## Project Mapping

`Project Logic Grid` maps the Star Battle terms as follows:

| Star Battle Term | Project Term |
|---|---|
| Star | Piece / token, currently themed as a queen |
| Region / shape | Colored region |
| 1 star per row | 1 piece per row |
| 1 star per column | 1 piece per column |
| 1 star per region | 1 piece per colored region |
| Stars cannot touch | Pieces cannot touch in all 8 directions |

The no-touch rule is local only. It forbids immediate neighbors, including diagonal neighbors. It does not forbid two pieces from sharing a longer diagonal.

## Development Implication

The puzzle validator should implement 1-star Star Battle constraints:

- Row count equals 1.
- Column count equals 1.
- Region count equals 1.
- Chebyshev distance between any two pieces is at least 2.

Do not implement full N-Queens diagonal attack rules for this project.
