import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'cell.dart';
import 'difficulty_metadata.dart';
import 'puzzle_solution.dart';
import 'region.dart';

/// Current puzzle JSON schema version. Bumped when the on-disk format changes.
const int kPuzzleSchemaVersion = 1;

/// The minimum supported grid size. Below 4 the rules degenerate.
const int kMinPuzzleSize = 4;

/// A fully specified puzzle: grid size, regions, solution, and difficulty metadata.
///
/// Invariants enforced at construction (all via `assert`, so they fire in dev
/// and test and are stripped in release — construction is trusted in release):
///
/// * [size] >= [kMinPuzzleSize].
/// * [regions] length equals [size].
/// * [regions] ids are distinct.
/// * Every region cell lies within `[0, size) x [0, size)`.
/// * Regions are pairwise disjoint.
/// * Union of regions equals the full `size x size` grid.
/// * [solution] has exactly [size] tokens.
/// * Each token lies in a distinct region — one token per region.
/// * No two tokens touch (Chebyshev distance >= 2 between all pairs).
@immutable
final class PuzzleDefinition {
  PuzzleDefinition({
    required this.id,
    required this.schemaVersion,
    required this.size,
    required List<Region> regions,
    required this.solution,
    required this.difficulty,
  })  : assert(id.isNotEmpty, 'PuzzleDefinition.id must be non-empty'),
        assert(
          schemaVersion >= 1,
          'PuzzleDefinition.schemaVersion must be >= 1',
        ),
        assert(
          size >= kMinPuzzleSize,
          'PuzzleDefinition.size must be >= $kMinPuzzleSize',
        ),
        regions = List<Region>.unmodifiable(regions),
        _cellToRegionId = _buildCellToRegionId(regions, size) {
    assert(
      this.regions.length == size,
      'PuzzleDefinition.regions.length (${this.regions.length}) '
      'must equal size ($size)',
    );
    assert(
      _idsAreUnique(this.regions),
      'PuzzleDefinition.regions must have distinct ids',
    );
    assert(
      _cellToRegionId.length == size * size,
      'Regions must partition the full $size x $size grid; '
      'covered ${_cellToRegionId.length} / ${size * size} cells',
    );
    assert(
      solution.size == size,
      'PuzzleDefinition.solution.size (${solution.size}) must equal size ($size)',
    );
    assert(
      _solutionTokensLieInDistinctRegions(solution, _cellToRegionId),
      'PuzzleDefinition.solution must place exactly one token in each region',
    );
    assert(
      _solutionSatisfiesNoTouch(solution),
      'PuzzleDefinition.solution must have all token pairs at Chebyshev >= 2',
    );
  }

  final String id;
  final int schemaVersion;
  final int size;
  final List<Region> regions;
  final PuzzleSolution solution;
  final DifficultyMetadata difficulty;

  final Map<Cell, int> _cellToRegionId;

  /// Returns the [Region] that contains [cell].
  ///
  /// Throws [ArgumentError] if [cell] is not in the grid.
  Region regionContaining(Cell cell) {
    final int? regionId = _cellToRegionId[cell];
    if (regionId == null) {
      throw ArgumentError.value(
        cell,
        'cell',
        'Cell is not part of any region in puzzle $id',
      );
    }
    return regions.firstWhere((Region r) => r.id == regionId);
  }

  bool cellIsInGrid(Cell cell) {
    return cell.row >= 0 &&
        cell.row < size &&
        cell.col >= 0 &&
        cell.col < size;
  }

  @override
  bool operator ==(Object other) {
    return other is PuzzleDefinition &&
        other.id == id &&
        other.schemaVersion == schemaVersion &&
        other.size == size &&
        other.solution == solution &&
        other.difficulty == difficulty &&
        const ListEquality<Region>().equals(regions, other.regions);
  }

  @override
  int get hashCode => Object.hash(
        id,
        schemaVersion,
        size,
        solution,
        difficulty,
        const ListEquality<Region>().hash(regions),
      );

  @override
  String toString() =>
      'PuzzleDefinition(id: $id, size: $size, band: ${difficulty.band.name})';

  /// JSON encoding matching the schema in docs/level-generation.md.
  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'version': schemaVersion,
        'size': size,
        'regions': regions.map((Region r) => r.toJson()).toList(),
        'solution': solution.toJson(),
        'difficulty': difficulty.toJson(),
      };

  factory PuzzleDefinition.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw FormatException(
        'PuzzleDefinition JSON must be a map, got $json',
      );
    }
    final Object? idValue = json['id'];
    final Object? versionValue = json['version'];
    final Object? sizeValue = json['size'];
    final Object? regionsValue = json['regions'];

    if (idValue is! String) {
      throw FormatException('PuzzleDefinition.id must be a string');
    }
    if (versionValue is! int) {
      throw FormatException('PuzzleDefinition.version must be an int');
    }
    if (sizeValue is! int) {
      throw FormatException('PuzzleDefinition.size must be an int');
    }
    if (regionsValue is! List<Object?>) {
      throw FormatException('PuzzleDefinition.regions must be a list');
    }

    final List<Region> parsedRegions = regionsValue
        .map(Region.fromJson)
        .toList(growable: false);

    return PuzzleDefinition(
      id: idValue,
      schemaVersion: versionValue,
      size: sizeValue,
      regions: parsedRegions,
      solution: PuzzleSolution.fromJson(json['solution']),
      difficulty: DifficultyMetadata.fromJson(json['difficulty']),
    );
  }

  static Map<Cell, int> _buildCellToRegionId(
    List<Region> regions,
    int size,
  ) {
    final Map<Cell, int> map = <Cell, int>{};
    for (final Region region in regions) {
      for (final Cell cell in region.cells) {
        assert(
          cell.row >= 0 && cell.row < size && cell.col >= 0 && cell.col < size,
          'Region ${region.id} contains out-of-bounds cell $cell '
          'for size $size',
        );
        final int? existing = map[cell];
        assert(
          existing == null,
          'Cell $cell appears in multiple regions (${existing ?? 'n/a'} and ${region.id})',
        );
        map[cell] = region.id;
      }
    }
    return map;
  }

  static bool _idsAreUnique(List<Region> regions) {
    final Set<int> seen = <int>{};
    for (final Region r in regions) {
      if (!seen.add(r.id)) {
        return false;
      }
    }
    return true;
  }

  static bool _solutionTokensLieInDistinctRegions(
    PuzzleSolution solution,
    Map<Cell, int> cellToRegionId,
  ) {
    final Set<int> covered = <int>{};
    for (final Cell token in solution.tokens) {
      final int? regionId = cellToRegionId[token];
      if (regionId == null) {
        return false;
      }
      if (!covered.add(regionId)) {
        return false;
      }
    }
    return covered.length == solution.size;
  }

  static bool _solutionSatisfiesNoTouch(PuzzleSolution solution) {
    final List<Cell> tokens = solution.tokens;
    for (int i = 0; i < tokens.length; i++) {
      for (int j = i + 1; j < tokens.length; j++) {
        if (tokens[i].chebyshevDistanceTo(tokens[j]) < 2) {
          return false;
        }
      }
    }
    return true;
  }
}
