# N-Queens Reference

The classic N-Queens puzzle is useful as theme and historical context, but it is not the canonical rule set for `Project Logic Grid`.

## Classic N-Queens Rules

In the classic N-Queens puzzle, the player places N queens on an N x N chessboard so that no two queens attack each other.

That means:

- Exactly one queen per row.
- Exactly one queen per column.
- No two queens share any diagonal of any length.

The full diagonal rule is stricter than the local no-touch rule used by this project.

## Difference From This Project

`Project Logic Grid` uses 1-star Star Battle rules:

- Exactly one piece per row.
- Exactly one piece per column.
- Exactly one piece per colored region.
- No two pieces may be adjacent in any of the 8 directions.
- Pieces may share a longer diagonal if they are not adjacent.

The current queen theme borrows the feel of N-Queens, but the validator must not reject longer shared diagonals. The canonical constraint is Star Battle adjacency, not chess attack lines.

## Implementation Note

Use this reference only to explain why the game feels queen-like. For solver, generator, hint, and validation code, defer to the Star Battle reference and the canonical rules in `TheGame.md`.
