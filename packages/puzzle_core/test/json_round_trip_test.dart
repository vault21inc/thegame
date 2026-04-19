import 'dart:convert';

import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('JSON round-trip (full puzzle)', () {
    test('PuzzleDefinition.fromJson(toJson(p)) == p for the quadrant puzzle',
        () {
      final PuzzleDefinition original = buildQuadrantPuzzle();
      final Map<String, Object?> json = original.toJson();
      final PuzzleDefinition restored = PuzzleDefinition.fromJson(json);
      expect(restored, equals(original));
    });

    test('toJson output survives a real JSON encode/decode cycle', () {
      final PuzzleDefinition original = buildQuadrantPuzzle();
      final String encoded = jsonEncode(original.toJson());
      final Object? decoded = jsonDecode(encoded);
      final PuzzleDefinition restored = PuzzleDefinition.fromJson(decoded);
      expect(restored, equals(original));
    });

    test('PuzzleDefinition.fromJson rejects malformed top-level input', () {
      expect(
        () => PuzzleDefinition.fromJson('not a map'),
        throwsFormatException,
      );
      expect(
        () => PuzzleDefinition.fromJson(const <String, Object?>{}),
        throwsFormatException,
      );
    });

    test('JSON structure matches the documented schema shape', () {
      final Map<String, Object?> json = buildQuadrantPuzzle().toJson();
      expect(
        json.keys,
        containsAll(const <String>[
          'id',
          'version',
          'size',
          'regions',
          'solution',
          'difficulty',
        ]),
      );
      expect(json['id'], isA<String>());
      expect(json['version'], isA<int>());
      expect(json['size'], isA<int>());
      expect(json['regions'], isA<List<Object?>>());
      expect(json['solution'], isA<List<Object?>>());
      expect(json['difficulty'], isA<Map<String, Object?>>());
    });
  });
}
