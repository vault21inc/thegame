import 'package:meta/meta.dart';

import '../models/cell.dart';

/// A rule-level violation detected by [PlacementValidator].
///
/// Sealed so exhaustive switch expressions on [PlacementViolation] surface
/// missing cases at compile time.
@immutable
sealed class PlacementViolation {
  const PlacementViolation();
}

final class DuplicateRow extends PlacementViolation {
  const DuplicateRow(this.row);
  final int row;

  @override
  bool operator ==(Object other) =>
      other is DuplicateRow && other.row == row;

  @override
  int get hashCode => Object.hash('DuplicateRow', row);

  @override
  String toString() => 'DuplicateRow(row: $row)';
}

final class DuplicateColumn extends PlacementViolation {
  const DuplicateColumn(this.col);
  final int col;

  @override
  bool operator ==(Object other) =>
      other is DuplicateColumn && other.col == col;

  @override
  int get hashCode => Object.hash('DuplicateColumn', col);

  @override
  String toString() => 'DuplicateColumn(col: $col)';
}

final class DuplicateRegion extends PlacementViolation {
  const DuplicateRegion(this.regionId);
  final int regionId;

  @override
  bool operator ==(Object other) =>
      other is DuplicateRegion && other.regionId == regionId;

  @override
  int get hashCode => Object.hash('DuplicateRegion', regionId);

  @override
  String toString() => 'DuplicateRegion(regionId: $regionId)';
}

final class AdjacentTokens extends PlacementViolation {
  AdjacentTokens(Cell a, Cell b)
      : a = _orderedFirst(a, b),
        b = _orderedSecond(a, b);

  final Cell a;
  final Cell b;

  static Cell _orderedFirst(Cell a, Cell b) => _compare(a, b) <= 0 ? a : b;
  static Cell _orderedSecond(Cell a, Cell b) => _compare(a, b) <= 0 ? b : a;

  static int _compare(Cell x, Cell y) {
    final int rowCompare = x.row.compareTo(y.row);
    return rowCompare != 0 ? rowCompare : x.col.compareTo(y.col);
  }

  @override
  bool operator ==(Object other) =>
      other is AdjacentTokens && other.a == a && other.b == b;

  @override
  int get hashCode => Object.hash('AdjacentTokens', a, b);

  @override
  String toString() => 'AdjacentTokens($a, $b)';
}

/// A cell referenced as a token that is outside the puzzle grid.
final class OutOfBoundsToken extends PlacementViolation {
  const OutOfBoundsToken(this.cell);
  final Cell cell;

  @override
  bool operator ==(Object other) =>
      other is OutOfBoundsToken && other.cell == cell;

  @override
  int get hashCode => Object.hash('OutOfBoundsToken', cell);

  @override
  String toString() => 'OutOfBoundsToken($cell)';
}
