import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'cell.dart';

/// Immutable region — an id plus a non-empty, 4-connected set of cells.
///
/// Containment and contiguity are enforced at construction. Disjointness
/// with other regions and within-grid bounds are enforced by the owning
/// [PuzzleDefinition].
@immutable
final class Region {
  /// Creates a region, asserting [cells] is non-empty and 4-connected.
  ///
  /// The stored [cells] is an unmodifiable view of a copied set, so callers
  /// cannot mutate the region through the original collection.
  Region({required this.id, required Set<Cell> cells})
      : assert(id >= 0, 'Region.id must be non-negative'),
        assert(cells.isNotEmpty, 'Region.cells must be non-empty'),
        cells = UnmodifiableSetView<Cell>(Set<Cell>.of(cells)) {
    assert(
      _isContiguous(this.cells),
      'Region.cells must be 4-connected (orthogonally contiguous)',
    );
  }

  final int id;
  final Set<Cell> cells;

  bool containsCell(Cell cell) => cells.contains(cell);

  /// True if the underlying cells form a 4-connected region.
  bool get isContiguous => _isContiguous(cells);

  static bool _isContiguous(Set<Cell> cells) {
    if (cells.isEmpty) {
      return false;
    }
    final Cell start = cells.first;
    final Set<Cell> visited = <Cell>{start};
    final Queue<Cell> queue = Queue<Cell>()..add(start);
    while (queue.isNotEmpty) {
      final Cell current = queue.removeFirst();
      for (final Cell neighbor in _orthogonalNeighbors(current)) {
        if (cells.contains(neighbor) && visited.add(neighbor)) {
          queue.add(neighbor);
        }
      }
    }
    return visited.length == cells.length;
  }

  static Iterable<Cell> _orthogonalNeighbors(Cell cell) sync* {
    if (cell.row > 0) {
      yield Cell(cell.row - 1, cell.col);
    }
    yield Cell(cell.row + 1, cell.col);
    if (cell.col > 0) {
      yield Cell(cell.row, cell.col - 1);
    }
    yield Cell(cell.row, cell.col + 1);
  }

  @override
  bool operator ==(Object other) {
    return other is Region &&
        other.id == id &&
        const SetEquality<Cell>().equals(cells, other.cells);
  }

  @override
  int get hashCode =>
      Object.hash(id, const SetEquality<Cell>().hash(cells));

  @override
  String toString() => 'Region(id: $id, cells: ${cells.length})';

  /// JSON encoding: `{"id": <int>, "cells": [[r, c], ...]}`.
  Map<String, Object?> toJson() {
    final List<Cell> sorted = cells.toList()
      ..sort((Cell a, Cell b) {
        final int rowCompare = a.row.compareTo(b.row);
        return rowCompare != 0 ? rowCompare : a.col.compareTo(b.col);
      });
    return <String, Object?>{
      'id': id,
      'cells': sorted.map((Cell c) => c.toJson()).toList(),
    };
  }

  factory Region.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw FormatException('Region JSON must be a map, got $json');
    }
    final Object? idValue = json['id'];
    final Object? cellsValue = json['cells'];
    if (idValue is! int) {
      throw FormatException('Region JSON "id" must be an int, got $idValue');
    }
    if (cellsValue is! List<Object?>) {
      throw FormatException(
        'Region JSON "cells" must be a list, got $cellsValue',
      );
    }
    final Set<Cell> cellSet = <Cell>{};
    for (final Object? raw in cellsValue) {
      final Cell cell = Cell.fromJson(raw);
      if (!cellSet.add(cell)) {
        throw FormatException(
          'Region JSON contains duplicate cell $cell in region $idValue',
        );
      }
    }
    return Region(id: idValue, cells: cellSet);
  }
}
