import 'dart:io' as io;

import 'package:level_generator/level_generator.dart';
import 'package:test/test.dart';

void main() {
  group('runLevelGenerator', () {
    test('prints usage for help', () async {
      final StringBuffer out = StringBuffer();
      final int code = await runLevelGenerator(<String>['--help'], out: out);

      expect(code, 0);
      expect(out.toString(), contains('--seed'));
      expect(out.toString(), contains('--max-candidates'));
    });

    test('writes deterministic empty pack JSON for scaffold smoke runs',
        () async {
      final io.Directory tempDir = io.Directory.systemTemp.createTempSync(
        'level_generator_cli_',
      );
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final io.File first = io.File('${tempDir.path}/pack_a.json');
      final io.File second = io.File('${tempDir.path}/pack_b.json');
      final StringBuffer out = StringBuffer();

      final int firstCode = await runLevelGenerator(
        <String>[
          '--',
          '--seed',
          '42',
          '--count',
          '0',
          '--output',
          first.path,
          '--max-candidates',
          '0',
        ],
        out: out,
      );
      final int secondCode = await runLevelGenerator(
        <String>[
          '--seed',
          '42',
          '--count',
          '0',
          '--output',
          second.path,
          '--max-candidates',
          '0',
        ],
        out: out,
      );

      expect(firstCode, 0);
      expect(secondCode, 0);
      expect(first.readAsStringSync(), second.readAsStringSync());
      expect(first.readAsStringSync(), contains('"seed": 42'));
      expect(first.readAsStringSync(), contains('"puzzles": []'));
    });

    test('rejects non-empty generation until pipeline stages are implemented',
        () async {
      final io.Directory tempDir = io.Directory.systemTemp.createTempSync(
        'level_generator_cli_',
      );
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final io.File output = io.File('${tempDir.path}/pack.json');
      final StringBuffer err = StringBuffer();

      final int code = await runLevelGenerator(
        <String>[
          '--seed',
          '42',
          '--count',
          '1',
          '--output',
          output.path,
          '--max-candidates',
          '1',
        ],
        err: err,
      );

      expect(code, kPipelineIncompleteCode);
      expect(output.existsSync(), isFalse);
      expect(err.toString(), contains('Non-empty puzzle generation'));
    });
  });
}
