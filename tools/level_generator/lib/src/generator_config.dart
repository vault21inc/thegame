import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:puzzle_core/puzzle_core.dart';

/// Semantic version of the generator package recorded in every pack.
///
/// This value is part of the reproducibility contract: seed, version, and
/// parameters together identify the exact generator behavior used to produce a
/// level pack.
const String kGeneratorVersion = '0.1.0';

/// Error code for invalid command-line usage.
const int kUsageErrorCode = 64;

/// Error code for a valid request that this milestone's scaffold cannot run.
const int kPipelineIncompleteCode = 70;

/// Error code for I/O failures while writing the output pack.
const int kIoErrorCode = 74;

/// User-correctable CLI argument error.
///
/// The parser throws this instead of raw [FormatException] values so the CLI
/// can print both a concise message and the generated usage text while tests
/// can assert on one stable exception type.
final class GeneratorUsageException implements Exception {
  /// Creates an exception containing a [message] and parser [usage].
  const GeneratorUsageException(this.message, this.usage);

  /// User-facing explanation of the invalid arguments.
  final String message;

  /// Full parser usage text to print after [message].
  final String usage;

  @override
  String toString() => message;
}

/// Difficulty-band quota for one generator run.
///
/// The level generator needs this value object so CLI parsing, quota
/// enforcement, metadata export, and tests all agree on the same band counts.
/// Counts are non-negative and use [Difficulty] keys to stay aligned with
/// `puzzle_core` metadata.
final class BandQuota {
  /// Creates a quota object from explicit per-band counts.
  ///
  /// Each count is the maximum number of accepted puzzles in that difficulty
  /// band when quota enforcement is enabled.
  const BandQuota({
    required this.easy,
    required this.medium,
    required this.hard,
    required this.master,
  });

  /// Easy-band target count.
  final int easy;

  /// Medium-band target count.
  final int medium;

  /// Hard-band target count.
  final int hard;

  /// Master-band target count.
  final int master;

  /// Total number of puzzles represented by this quota.
  int get total => easy + medium + hard + master;

  /// Returns the count for [difficulty].
  ///
  /// This is used by future quota enforcement and by tests that should not
  /// depend on the storage order of the fields.
  int countFor(Difficulty difficulty) {
    return switch (difficulty) {
      Difficulty.easy => easy,
      Difficulty.medium => medium,
      Difficulty.hard => hard,
      Difficulty.master => master,
    };
  }

  /// Encodes this quota as deterministic JSON metadata.
  ///
  /// Keys are emitted in the public difficulty order so a repeated generator
  /// run with the same inputs produces byte-identical output.
  Map<String, int> toJson() {
    return <String, int>{
      Difficulty.easy.name: easy,
      Difficulty.medium.name: medium,
      Difficulty.hard.name: hard,
      Difficulty.master.name: master,
    };
  }

  /// Builds the V1 default quota scaled to [count].
  ///
  /// The canonical 500-level pack uses 40/35/20/5 shares. For smaller smoke
  /// runs, this method keeps the same proportions and distributes rounding
  /// leftovers deterministically from largest fractional remainder to smallest.
  factory BandQuota.defaultForCount(int count) {
    _checkNonNegative(count, 'count');
    final List<_QuotaShare> shares = <_QuotaShare>[
      const _QuotaShare(Difficulty.easy, 0.40),
      const _QuotaShare(Difficulty.medium, 0.35),
      const _QuotaShare(Difficulty.hard, 0.20),
      const _QuotaShare(Difficulty.master, 0.05),
    ];

    final Map<Difficulty, int> counts = <Difficulty, int>{};
    var assigned = 0;
    for (final _QuotaShare share in shares) {
      final double exact = count * share.ratio;
      final int base = exact.floor();
      counts[share.difficulty] = base;
      assigned += base;
    }

    final List<_QuotaRemainder> remainders = <_QuotaRemainder>[
      for (final _QuotaShare share in shares)
        _QuotaRemainder(
          share.difficulty,
          count * share.ratio - (counts[share.difficulty] ?? 0),
        ),
    ]..sort(_compareRemainders);

    var remaining = count - assigned;
    var index = 0;
    while (remaining > 0) {
      final Difficulty difficulty = remainders[index].difficulty;
      counts[difficulty] = (counts[difficulty] ?? 0) + 1;
      remaining -= 1;
      index = (index + 1) % remainders.length;
    }

    return BandQuota(
      easy: counts[Difficulty.easy] ?? 0,
      medium: counts[Difficulty.medium] ?? 0,
      hard: counts[Difficulty.hard] ?? 0,
      master: counts[Difficulty.master] ?? 0,
    );
  }

  /// Parses `easy=200,medium=175,hard=100,master=25` style CLI input.
  ///
  /// All four bands must be present exactly once. This strictness prevents a
  /// partially-overridden quota from silently using surprising defaults.
  factory BandQuota.parse(String raw) {
    final Map<Difficulty, int> counts = <Difficulty, int>{};
    final List<String> entries = raw
        .split(',')
        .map((String part) => part.trim())
        .where((String part) => part.isNotEmpty)
        .toList(growable: false);
    for (final String entry in entries) {
      final List<String> pair = entry.split('=');
      if (pair.length != 2) {
        throw FormatException(
          'Quota entry "$entry" must use name=count syntax.',
        );
      }
      final Difficulty difficulty = _difficultyByName(pair[0].trim());
      if (counts.containsKey(difficulty)) {
        throw FormatException('Quota repeats ${difficulty.name}.');
      }
      final int? count = int.tryParse(pair[1].trim());
      if (count == null || count < 0) {
        throw FormatException(
          'Quota for ${difficulty.name} must be a non-negative integer.',
        );
      }
      counts[difficulty] = count;
    }

    final Set<Difficulty> missing = Difficulty.values.toSet()
      ..removeAll(counts.keys);
    if (missing.isNotEmpty) {
      throw FormatException(
        'Quota is missing ${missing.map((Difficulty d) => d.name).join(', ')}.',
      );
    }

    return BandQuota(
      easy: counts[Difficulty.easy]!,
      medium: counts[Difficulty.medium]!,
      hard: counts[Difficulty.hard]!,
      master: counts[Difficulty.master]!,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BandQuota &&
        other.easy == easy &&
        other.medium == medium &&
        other.hard == hard &&
        other.master == master;
  }

  @override
  int get hashCode => Object.hash(easy, medium, hard, master);

  @override
  String toString() =>
      'BandQuota(easy: $easy, medium: $medium, hard: $hard, master: $master)';
}

/// Parsed and validated configuration for one generator run.
///
/// The CLI converts raw arguments into this immutable object before invoking
/// the pipeline. Keeping validation here makes reproducibility tests cheap and
/// keeps the long-running generation code free of command-line concerns.
final class GeneratorConfig {
  /// Creates a validated generator configuration.
  ///
  /// [seed] controls deterministic RNG behavior, [count] is the requested
  /// number of exported puzzles, [quota] controls band distribution when
  /// [overFill] is false, [outputPath] is the target JSON file, and
  /// [maxCandidates] bounds candidate attempts for long-running jobs.
  GeneratorConfig({
    required this.seed,
    required this.count,
    required this.quota,
    required this.outputPath,
    required this.overFill,
    required this.maxCandidates,
  }) {
    _checkNonNegative(count, 'count');
    _checkNonNegative(maxCandidates, 'maxCandidates');
    if (!overFill && quota.total != count) {
      throw ArgumentError.value(
        quota,
        'quota',
        'Quota total ${quota.total} must equal count $count.',
      );
    }
    if (maxCandidates < count) {
      throw ArgumentError.value(
        maxCandidates,
        'maxCandidates',
        'Must be >= count so the requested pack can be attempted.',
      );
    }
    _validateOutputParent(outputPath);
  }

  /// RNG seed recorded in pack metadata and used by the pipeline.
  final int seed;

  /// Requested number of puzzles to export.
  final int count;

  /// Target difficulty-band counts.
  final BandQuota quota;

  /// JSON output path.
  final String outputPath;

  /// Whether quota enforcement is disabled for exploratory runs.
  final bool overFill;

  /// Maximum candidate attempts before the batch stops.
  final int maxCandidates;

  /// Encodes stable pipeline parameters into pack metadata.
  ///
  /// This intentionally excludes volatile data such as wall-clock timestamps so
  /// repeated runs with the same config can be byte-identical.
  Map<String, Object?> parametersJson() {
    return <String, Object?>{
      'requestedCount': count,
      'quota': quota.toJson(),
      'overFill': overFill,
      'maxCandidates': maxCandidates,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is GeneratorConfig &&
        other.seed == seed &&
        other.count == count &&
        other.quota == quota &&
        other.outputPath == outputPath &&
        other.overFill == overFill &&
        other.maxCandidates == maxCandidates;
  }

  @override
  int get hashCode => Object.hash(
        seed,
        count,
        quota,
        outputPath,
        overFill,
        maxCandidates,
      );
}

/// Builds the command-line parser shared by the binary and tests.
///
/// The parser mirrors the milestone 4 required flags. Validation that depends
/// on relationships between flags is handled by [parseGeneratorConfig].
ArgParser buildArgParser() {
  return ArgParser()
    ..addOption('seed', help: 'RNG seed; required for reproducible packs.')
    ..addOption('count', help: 'Total puzzles to generate.')
    ..addOption(
      'quota',
      help: 'Band quota, e.g. easy=200,medium=175,hard=100,master=25.',
    )
    ..addOption('output', help: 'Output path for the level pack JSON.')
    ..addFlag(
      'over-fill',
      help: 'Disable quota enforcement (exploration mode).',
      defaultsTo: false,
    )
    ..addOption(
      'max-candidates',
      help: 'Upper bound on candidates to generate.',
    )
    ..addFlag('help', abbr: 'h', help: 'Print usage.', negatable: false);
}

/// Parses and validates raw CLI [arguments] into a [GeneratorConfig].
///
/// Throws [GeneratorUsageException] for user-correctable CLI errors. The optional
/// [parser] parameter lets tests assert against the same usage text that the
/// binary prints.
GeneratorConfig parseGeneratorConfig(
  List<String> arguments, {
  ArgParser? parser,
}) {
  final ArgParser effectiveParser = parser ?? buildArgParser();
  final ArgResults results;
  try {
    results = effectiveParser.parse(arguments);
  } on FormatException catch (error) {
    throw GeneratorUsageException(error.message, effectiveParser.usage);
  }

  if (results['help'] as bool) {
    throw GeneratorUsageException('help requested', effectiveParser.usage);
  }

  final int seed = _requiredInt(results, 'seed', effectiveParser.usage);
  final int count = _requiredInt(results, 'count', effectiveParser.usage);
  _checkNonNegative(count, 'count');
  final bool overFill = results['over-fill'] as bool;
  final String outputPath = _requiredString(
    results,
    'output',
    effectiveParser.usage,
  );
  final int maxCandidates = _optionalInt(
    results,
    'max-candidates',
    defaultValue: count == 0 ? 0 : count * 100,
    usage: effectiveParser.usage,
  );

  final String? rawQuota = results['quota'] as String?;
  final BandQuota quota;
  try {
    quota = rawQuota == null
        ? BandQuota.defaultForCount(count)
        : BandQuota.parse(rawQuota);
  } on FormatException catch (error) {
    throw GeneratorUsageException(error.message, effectiveParser.usage);
  }

  try {
    return GeneratorConfig(
      seed: seed,
      count: count,
      quota: quota,
      outputPath: outputPath,
      overFill: overFill,
      maxCandidates: maxCandidates,
    );
  } on ArgumentError catch (error) {
    final String message = error.message?.toString() ?? error.toString();
    throw GeneratorUsageException(message, effectiveParser.usage);
  }
}

int _compareRemainders(_QuotaRemainder a, _QuotaRemainder b) {
  final int remainderCompare = b.remainder.compareTo(a.remainder);
  if (remainderCompare != 0) {
    return remainderCompare;
  }
  return a.difficulty.index.compareTo(b.difficulty.index);
}

int _requiredInt(ArgResults results, String name, String usage) {
  final String raw = _requiredString(results, name, usage);
  final int? value = int.tryParse(raw);
  if (value == null) {
    throw GeneratorUsageException('--$name must be an integer.', usage);
  }
  return value;
}

int _optionalInt(
  ArgResults results,
  String name, {
  required int defaultValue,
  required String usage,
}) {
  final String? raw = results[name] as String?;
  if (raw == null) {
    return defaultValue;
  }
  final int? value = int.tryParse(raw);
  if (value == null) {
    throw GeneratorUsageException('--$name must be an integer.', usage);
  }
  return value;
}

String _requiredString(ArgResults results, String name, String usage) {
  final String? value = results[name] as String?;
  if (value == null || value.trim().isEmpty) {
    throw GeneratorUsageException('--$name is required.', usage);
  }
  return value;
}

Difficulty _difficultyByName(String name) {
  for (final Difficulty difficulty in Difficulty.values) {
    if (difficulty.name == name) {
      return difficulty;
    }
  }
  throw FormatException('Unknown difficulty band "$name".');
}

void _checkNonNegative(int value, String name) {
  if (value < 0) {
    throw ArgumentError.value(value, name, 'Must be non-negative.');
  }
}

void _validateOutputParent(String outputPath) {
  final String parent = io.File(outputPath).parent.path;
  if (parent.isEmpty) {
    return;
  }
  if (!io.Directory(parent).existsSync()) {
    throw ArgumentError.value(
      outputPath,
      'outputPath',
      'Output directory does not exist.',
    );
  }
}

final class _QuotaShare {
  const _QuotaShare(this.difficulty, this.ratio);

  final Difficulty difficulty;
  final double ratio;
}

final class _QuotaRemainder {
  const _QuotaRemainder(this.difficulty, this.remainder);

  final Difficulty difficulty;
  final double remainder;
}
