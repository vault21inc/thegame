import 'dart:math' as math;

import 'package:meta/meta.dart';

/// Immutable (row, col) grid coordinate.
///
/// [row] and [col] are non-negative. Upper bounds are enforced by the
/// containing [PuzzleDefinition], not by [Cell] itself.
@immutable
final class Cell {
  const Cell(this.row, this.col)
      : assert(row >= 0, 'Cell.row must be non-negative'),
        assert(col >= 0, 'Cell.col must be non-negative');

  final int row;
  final int col;

  /// Chebyshev (chessboard) distance to [other].
  int chebyshevDistanceTo(Cell other) {
    return math.max((row - other.row).abs(), (col - other.col).abs());
  }

  /// True if [other] is in this cell's 3x3 no-touch neighborhood, excluding
  /// the center cell itself.
  bool touches(Cell other) {
    if (identical(this, other) || this == other) {
      return false;
    }
    return chebyshevDistanceTo(other) == 1;
  }

  @override
  bool operator ==(Object other) {
    return other is Cell && other.row == row && other.col == col;
  }

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => 'Cell($row, $col)';

  /// JSON encoding as `[row, col]`. Paired with [Cell.fromJson].
  List<int> toJson() => <int>[row, col];

  factory Cell.fromJson(Object? json) {
    if (json is! List<Object?> || json.length != 2) {
      throw FormatException('Cell JSON must be a 2-element list, got $json');
    }
    final Object? row = json[0];
    final Object? col = json[1];
    if (row is! int || col is! int) {
      throw FormatException(
        'Cell JSON elements must be ints, got [$row, $col]',
      );
    }
    return Cell(row, col);
  }
}
