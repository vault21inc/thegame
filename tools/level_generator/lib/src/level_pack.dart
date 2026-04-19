import 'package:puzzle_core/puzzle_core.dart';

import 'generator_config.dart';

/// Top-level JSON schema version for exported level packs.
///
/// This version is independent from individual puzzle schema versions because
/// pack metadata can evolve even when puzzle JSON stays stable.
const int kLevelPackSchemaVersion = 1;

/// Metadata that makes a generated pack reproducible and auditable.
///
/// The app primarily consumes [LevelPack.puzzles], but the generator and test
/// tooling need to know which seed, generator version, and parameters produced
/// a pack. This class keeps those fields deterministic and timestamp-free.
final class LevelPackMetadata {
  /// Creates metadata for one generator run.
  ///
  /// [seed], [generatorVersion], and [parameters] are sufficient to reproduce
  /// the run; [acceptedByBand] summarizes the generated content.
  LevelPackMetadata({
    required this.seed,
    required this.generatorVersion,
    required Map<String, Object?> parameters,
    required this.acceptedByBand,
  }) : parameters = Map<String, Object?>.unmodifiable(parameters);

  /// RNG seed used by the generator.
  final int seed;

  /// Generator semantic version.
  final String generatorVersion;

  /// Stable pipeline parameters such as requested count and retry limits.
  final Map<String, Object?> parameters;

  /// Accepted puzzle count per difficulty band.
  final BandQuota acceptedByBand;

  /// Encodes metadata using deterministic key order.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': kLevelPackSchemaVersion,
      'seed': seed,
      'generatorVersion': generatorVersion,
      'parameters': parameters,
      'acceptedByBand': acceptedByBand.toJson(),
    };
  }
}

/// Exportable level pack produced by the generator pipeline.
///
/// A pack combines reproducibility metadata with verified [PuzzleDefinition]
/// values. Milestone 4 part A can emit an empty pack shell; later pipeline
/// stages fill [puzzles] after uniqueness and logic-solvability checks pass.
final class LevelPack {
  /// Creates a pack from [metadata] and verified [puzzles].
  ///
  /// The puzzle list is defensively copied so later generator mutations cannot
  /// change what is written to disk.
  LevelPack({
    required this.metadata,
    required List<PuzzleDefinition> puzzles,
  }) : puzzles = List<PuzzleDefinition>.unmodifiable(puzzles);

  /// Reproducibility and parameter metadata.
  final LevelPackMetadata metadata;

  /// Verified puzzles in player-facing order.
  final List<PuzzleDefinition> puzzles;

  /// Encodes the full pack using deterministic key order.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'metadata': metadata.toJson(),
      'puzzles':
          puzzles.map((PuzzleDefinition puzzle) => puzzle.toJson()).toList(),
    };
  }
}
