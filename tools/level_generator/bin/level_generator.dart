import 'dart:io' as io;

import 'package:level_generator/level_generator.dart';

/// Runs the offline level generator command-line interface.
///
/// The CLI is intentionally a thin shell over [runLevelGenerator] so tests can
/// exercise argument parsing and pack writing without spawning a process. A
/// non-zero return value is copied into [io.exitCode] for normal shell usage.
Future<void> main(List<String> arguments) async {
  final int code = await runLevelGenerator(
    arguments,
    out: io.stdout,
    err: io.stderr,
  );
  if (code != 0) {
    io.exitCode = code;
  }
}
