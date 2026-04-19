/// Deduction families used by the logic solver and difficulty grader.
///
/// Families 1–4 are the player-facing vocabulary. Family 5 (higher-order
/// confinement) is grader-only — see the root README's Official Deduction Set
/// and [docs/level-generation.md §Deduction set].
enum DeductionFamily {
  /// Family 1 — player-facing.
  giveawayCell,

  /// Family 2 — player-facing. Bidirectional (region↔row/column).
  confinement,

  /// Family 3 — player-facing.
  touchAllElimination,

  /// Family 4 — player-facing.
  contradictionElimination,

  /// Family 5 — grader-only.
  higherOrderConfinement,
}

/// Decodes a [DeductionFamily] from its [Enum.name] string. Throws
/// [FormatException] on unknown input.
DeductionFamily deductionFamilyFromJson(Object? json) {
  if (json is! String) {
    throw FormatException('DeductionFamily must be a string, got $json');
  }
  for (final DeductionFamily f in DeductionFamily.values) {
    if (f.name == json) {
      return f;
    }
  }
  throw FormatException('Unknown DeductionFamily: $json');
}
