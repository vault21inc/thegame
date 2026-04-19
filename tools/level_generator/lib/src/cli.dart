import 'dart:io' as io;

import 'package:args/args.dart';

import 'generator_config.dart';
import 'level_generation_pipeline.dart';

/// Runs the level generator CLI and returns a process-style exit code.
///
/// Tests call this function directly to verify parsing and deterministic file
/// output. The binary wraps it and copies the returned value to `exitCode`.
/// A leading `--` separator is tolerated because some `dart run` invocations
/// pass it through to package executables.
Future<int> runLevelGenerator(
  List<String> arguments, {
  StringSink? out,
  StringSink? err,
  LevelGenerationPipeline pipeline = const LevelGenerationPipeline(),
}) async {
  final StringSink stdout = out ?? io.stdout;
  final StringSink stderr = err ?? io.stderr;
  final ArgParser parser = buildArgParser();
  final List<String> effectiveArguments =
      arguments.isNotEmpty && arguments.first == '--'
          ? arguments.sublist(1)
          : arguments;

  if (effectiveArguments.contains('--help') ||
      effectiveArguments.contains('-h')) {
    stdout.writeln(parser.usage);
    return 0;
  }

  final GeneratorConfig config;
  try {
    config = parseGeneratorConfig(effectiveArguments, parser: parser);
  } on GeneratorUsageException catch (error) {
    stderr.writeln(error.message);
    stderr.writeln();
    stderr.writeln(error.usage);
    return kUsageErrorCode;
  }

  try {
    final pack = await pipeline.generate(config);
    await pipeline.writePack(pack, config.outputPath);
    stdout.writeln('Wrote ${config.outputPath}');
    return 0;
  } on PipelineIncompleteException catch (error) {
    stderr.writeln(error.message);
    return kPipelineIncompleteCode;
  } on io.FileSystemException catch (error) {
    stderr.writeln(error.message);
    return kIoErrorCode;
  }
}
