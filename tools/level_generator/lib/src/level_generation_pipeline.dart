import 'dart:convert';
import 'dart:io' as io;

import 'package:puzzle_core/puzzle_core.dart';

import 'generator_config.dart';
import 'level_pack.dart';

/// Deterministic pipeline shell for milestone 4 level generation.
///
/// The class owns the progression from parsed CLI configuration to exported
/// pack JSON. In this scaffold slice, it can write an empty pack for smoke and
/// reproducibility tests; non-empty puzzle generation is intentionally rejected
/// until the candidate-generation stages are implemented.
final class LevelGenerationPipeline {
  /// Creates the default pipeline using the current generator version.
  const LevelGenerationPipeline();

  /// Runs the pipeline and returns an in-memory [LevelPack].
  ///
  /// For milestone 4 part A, [GeneratorConfig.count] must be zero. This keeps
  /// the CLI runnable and deterministic without falsely claiming that the full
  /// generate-and-test pipeline is complete.
  Future<LevelPack> generate(GeneratorConfig config) async {
    if (config.count != 0) {
      throw const PipelineIncompleteException(
        'Non-empty puzzle generation starts in the next milestone 4 slice.',
      );
    }

    return LevelPack(
      metadata: LevelPackMetadata(
        seed: config.seed,
        generatorVersion: kGeneratorVersion,
        parameters: config.parametersJson(),
        acceptedByBand: const BandQuota(
          easy: 0,
          medium: 0,
          hard: 0,
          master: 0,
        ),
      ),
      puzzles: const <PuzzleDefinition>[],
    );
  }

  /// Writes [pack] to [outputPath] as pretty, deterministic JSON.
  ///
  /// A trailing newline is included so repeated runs compare cleanly in shell
  /// tooling and future CI reproducibility checks.
  Future<void> writePack(LevelPack pack, String outputPath) async {
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    final String json = '${encoder.convert(pack.toJson())}\n';
    await io.File(outputPath).writeAsString(json);
  }
}

/// Signals that the CLI request is valid but the current scaffold cannot run it.
///
/// This is distinct from usage errors: the arguments parse correctly, but the
/// full candidate-generation stages are not implemented yet.
final class PipelineIncompleteException implements Exception {
  /// Creates an exception with a user-facing [message].
  const PipelineIncompleteException(this.message);

  /// Explanation printed by the CLI.
  final String message;

  @override
  String toString() => message;
}
