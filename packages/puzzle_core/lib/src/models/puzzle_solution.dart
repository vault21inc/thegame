import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'cell.dart';

/// The hidden solution for a puzzle — exactly one token per row, indexed by row.
///
/// The structural invariants enforced here are:
///
/// * `tokens[i].row == i` for every index `i`.
/// * Columns form a permutation of `0..tokens.length - 1`.
///
/// Rule-level invariants (no-touch, region coverage) depend on the owning
/// [PuzzleDefinition] and are enforced there rather than in this type.
@immutable
final class PuzzleSolution {
  /// Creates a solution, asserting the per-row indexing and column-permutation
  /// invariants. The provided [tokens] list is defensively copied and stored
  /// as an unmodifiable view.
  PuzzleSolution(List<Cell> tokens)
      : assert(tokens.isNotEmpty, 'PuzzleSolution must have at least one token'),
        tokens = List<Cell>.unmodifiable(tokens) {
    final int size = this.tokens.length;
    final Set<int> seenColumns = <int>{};
    for (int i = 0; i < size; i++) {
      final Cell token = this.tokens[i];
      assert(
        token.row == i,
        'PuzzleSolution.tokens[$i].row must equal $i, got ${token.row}',
      );
      assert(
        token.col >= 0 && token.col < size,
        'PuzzleSolution.tokens[$i].col must be in [0, $size), got ${token.col}',
      );
      assert(
        seenColumns.add(token.col),
        'PuzzleSolution columns must form a permutation of 0..${size - 1}; '
        'duplicate column ${token.col} at row $i',
      );
    }
  }

  final List<Cell> tokens;

  int get size => tokens.length;

  Cell tokenForRow(int row) {
    RangeError.checkValidIndex(row, tokens, 'row');
    return tokens[row];
  }

  @override
  bool operator ==(Object other) {
    return other is PuzzleSolution &&
        const ListEquality<Cell>().equals(tokens, other.tokens);
  }

  @override
  int get hashCode => const ListEquality<Cell>().hash(tokens);

  @override
  String toString() => 'PuzzleSolution($tokens)';

  /// JSON encoding as `[[r0, c0], [r1, c1], ...]`.
  List<List<int>> toJson() =>
      tokens.map((Cell c) => c.toJson()).toList(growable: false);

  factory PuzzleSolution.fromJson(Object? json) {
    if (json is! List<Object?>) {
      throw FormatException('PuzzleSolution JSON must be a list, got $json');
    }
    return PuzzleSolution(
      json.map(Cell.fromJson).toList(growable: false),
    );
  }
}
