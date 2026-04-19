/// Difficulty bands per [docs/level-generation.md §Stage 5 — Grade Difficulty].
enum Difficulty { easy, medium, hard, master }

/// Decodes a [Difficulty] from its [Enum.name] string. Throws [FormatException]
/// on unknown input.
Difficulty difficultyFromJson(Object? json) {
  if (json is! String) {
    throw FormatException('Difficulty must be a string, got $json');
  }
  for (final Difficulty d in Difficulty.values) {
    if (d.name == json) {
      return d;
    }
  }
  throw FormatException('Unknown Difficulty: $json');
}
