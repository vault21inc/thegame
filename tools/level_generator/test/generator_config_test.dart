import 'dart:io' as io;

import 'package:level_generator/level_generator.dart';
import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

void main() {
  group('BandQuota', () {
    test('matches the documented V1 quota for 500 puzzles', () {
      expect(
        BandQuota.defaultForCount(500),
        const BandQuota(easy: 200, medium: 175, hard: 100, master: 25),
      );
    });

    test('scales smaller smoke-run quotas deterministically', () {
      final BandQuota quota = BandQuota.defaultForCount(10);

      expect(quota.countFor(Difficulty.easy), 4);
      expect(quota.countFor(Difficulty.medium), 4);
      expect(quota.countFor(Difficulty.hard), 2);
      expect(quota.countFor(Difficulty.master), 0);
      expect(quota.total, 10);
    });

    test('parses explicit quota strings', () {
      final BandQuota quota = BandQuota.parse(
        'easy=2,medium=1,hard=1,master=0',
      );

      expect(quota, const BandQuota(easy: 2, medium: 1, hard: 1, master: 0));
    });
  });

  group('parseGeneratorConfig', () {
    test('parses required flags and validates output parent', () {
      final io.Directory tempDir = io.Directory.systemTemp.createTempSync(
        'level_generator_config_',
      );
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final GeneratorConfig config = parseGeneratorConfig(<String>[
        '--seed',
        '7',
        '--count',
        '4',
        '--quota',
        'easy=2,medium=1,hard=1,master=0',
        '--output',
        '${tempDir.path}/pack.json',
        '--max-candidates',
        '50',
      ]);

      expect(config.seed, 7);
      expect(config.count, 4);
      expect(config.quota.total, 4);
      expect(config.outputPath, '${tempDir.path}/pack.json');
      expect(config.overFill, isFalse);
      expect(config.maxCandidates, 50);
    });

    test('allows quota mismatch when over-fill disables quota enforcement', () {
      final io.Directory tempDir = io.Directory.systemTemp.createTempSync(
        'level_generator_config_',
      );
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final GeneratorConfig config = parseGeneratorConfig(<String>[
        '--seed',
        '7',
        '--count',
        '2',
        '--quota',
        'easy=2,medium=1,hard=1,master=0',
        '--over-fill',
        '--output',
        '${tempDir.path}/pack.json',
        '--max-candidates',
        '2',
      ]);

      expect(config.overFill, isTrue);
      expect(config.quota.total, 4);
    });

    test('rejects quota totals that do not match count', () {
      final io.Directory tempDir = io.Directory.systemTemp.createTempSync(
        'level_generator_config_',
      );
      addTearDown(() => tempDir.deleteSync(recursive: true));

      expect(
        () => parseGeneratorConfig(<String>[
          '--seed',
          '7',
          '--count',
          '2',
          '--quota',
          'easy=2,medium=1,hard=1,master=0',
          '--output',
          '${tempDir.path}/pack.json',
          '--max-candidates',
          '2',
        ]),
        throwsA(isA<GeneratorUsageException>()),
      );
    });

    test('rejects output paths whose parent directory is missing', () {
      expect(
        () => parseGeneratorConfig(<String>[
          '--seed',
          '7',
          '--count',
          '0',
          '--output',
          '/tmp/thegame_missing_parent_for_test/pack.json',
          '--max-candidates',
          '0',
        ]),
        throwsA(isA<GeneratorUsageException>()),
      );
    });
  });
}
