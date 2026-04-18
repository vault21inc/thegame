# Repository Scaffolding

This document specifies the initial Dart/Flutter workspace scaffolding for Skully Bones Treasure Adventure. It covers directory layout, toolchain versions, workspace configuration, per-package `pubspec.yaml` contents, lint configuration, and CI outline.

It is the authoritative reference for milestone 5 of [§Development Priorities](../README.md#development-priorities). The actual scaffold files are created from this spec as part of that milestone, not committed speculatively — toolchain versions should match the developer's local environment at the time of scaffolding.

---

## Toolchain versions

| Tool | Minimum version | Rationale |
|---|---|---|
| Dart SDK | 3.5.0 | Required for Dart workspaces (a.k.a. monorepo mode) without third-party tooling. |
| Flutter | 3.24.0 | First stable release with native workspace support. |
| Drift | 2.18+ | Matches current stable API referenced in docs. |
| Riverpod | 2.5+ | Stable API. |
| go_router | 14+ | Matches Flutter 3.24 compatibility. |

Version constraints in individual `pubspec.yaml` files should use caret ranges (`^3.5.0`) except where breaking-change risk is high, in which case pin to a minor range.

**Rejected alternative: melos.** Melos is a widely used third-party monorepo tool for Dart. Native workspaces cover this project's needs (shared dependencies, coordinated testing, single `pub get`) without the extra tooling layer, so we prefer them. Melos remains a reasonable fallback if the team later needs melos-specific features (e.g., version bumping, per-package changelog automation).

---

## Directory layout

The layout below is the authoritative structure. It expands on the sketch in [README.md §Proposed Repository Layout](../README.md#proposed-repository-layout).

```text
/
├── pubspec.yaml                  workspace root; lists workspace members
├── analysis_options.yaml         shared lints for the entire workspace
├── .gitignore                    Dart/Flutter standard ignores
├── README.md                     product spec (authoritative)
├── docs/
│   ├── level-generation.md
│   ├── data-model.md
│   ├── test-fixtures.md
│   ├── repo-scaffolding.md       (this file)
│   └── archive/                  historical brainstorming
│
├── apps/
│   └── mobile/
│       ├── pubspec.yaml
│       ├── analysis_options.yaml (inherits workspace; may override)
│       ├── lib/
│       │   ├── main.dart
│       │   └── src/              screens, routing, themes, audio, persistence
│       ├── test/
│       ├── integration_test/
│       ├── android/              Flutter create output
│       ├── ios/                  Flutter create output
│       └── assets/               app-bundled assets
│           └── levels/           bundled verified level packs (pre-generated JSON)
│
├── packages/
│   └── puzzle_core/
│       ├── pubspec.yaml
│       ├── lib/
│       │   ├── puzzle_core.dart  barrel file — public API
│       │   └── src/              implementation (private by convention)
│       │       ├── models/       Cell, Region, PuzzleDefinition, etc.
│       │       ├── validation/   PlacementValidator, SolutionValidator
│       │       ├── solver/       CandidateGrid, LogicSolver, UniquenessSolver
│       │       ├── deduction/    one file per family
│       │       ├── grading/      DifficultyGrader
│       │       └── session/      PuzzleSession, UndoEntry, SessionOutcome
│       └── test/
│           ├── deduction_scenarios/
│           ├── fixtures/
│           │   ├── README.md     seed + generator-version + selection criteria
│           │   ├── fixture_easy.json
│           │   ├── fixture_easy.trace.json
│           │   ├── fixture_medium.json
│           │   ├── fixture_medium.trace.json
│           │   ├── fixture_hard.json
│           │   └── fixture_hard.trace.json
│           └── *_test.dart       per-concern unit tests
│
├── tools/
│   └── level_generator/
│       ├── pubspec.yaml
│       ├── bin/
│       │   └── level_generator.dart  CLI entry
│       ├── lib/
│       │   └── src/                  pipeline stages, retry, canonicalization, ordering
│       └── test/
│
└── assets/                           shared non-app assets (optional)
    ├── animations/                   Rive/Lottie sources
    └── audio/
```

Notes:

- The `apps/mobile/assets/levels/` path is where the *bundled* level pack lives at app build time. The generator CLI writes into that directory (or a staging path that gets copied in). The top-level `assets/` directory is for raw/source assets that are not directly consumed by the app bundle.
- `apps/mobile/assets/levels/` should contain an empty placeholder (e.g., a `.gitkeep` or an empty pack) before milestone 9 so `flutter run` succeeds in milestone 5.
- `android/` and `ios/` directories inside `apps/mobile/` are produced by `flutter create` — do not attempt to hand-write them.

---

## Workspace configuration

### Root `pubspec.yaml`

```yaml
name: skully_bones_workspace
publish_to: none

environment:
  sdk: ^3.5.0

workspace:
  - apps/mobile
  - packages/puzzle_core
  - tools/level_generator
```

Running `dart pub get` at the root resolves all workspace members with a shared lockfile.

### Root `analysis_options.yaml`

Shared lints for every workspace member. Individual packages may extend this with per-package overrides.

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - always_declare_return_types
    - avoid_print
    - avoid_returning_null_for_future
    - directives_ordering
    - prefer_const_constructors
    - prefer_final_locals
    - require_trailing_commas
    - unawaited_futures
    - unnecessary_lambdas
    - use_decorated_box
    - use_super_parameters

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    invalid_annotation_target: ignore   # required for drift / riverpod codegen
  exclude:
    - '**/*.g.dart'
    - '**/*.freezed.dart'
    - '**/*.drift.dart'
```

### Root `.gitignore`

Standard Dart/Flutter ignores plus generator outputs:

```text
# Dart/Flutter
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
build/
pubspec.lock                     # optional — commit for apps, ignore for packages
*.g.dart.bak
coverage/

# IDE
.idea/
.vscode/
*.iml

# OS
.DS_Store

# Generator staging output (not the committed level packs under apps/mobile/assets/levels)
tools/level_generator/.staging/
```

**On `pubspec.lock`:** commit the lockfile for application packages (`apps/mobile`) to pin deploy reproducibility. Ignore it for pure-Dart libraries (`packages/puzzle_core`) to follow Dart convention. `tools/level_generator` is a Dart application, so commit its lockfile if generator reproducibility matters to the build.

---

## Per-package `pubspec.yaml`

### `packages/puzzle_core/pubspec.yaml`

Pure Dart library. No Flutter imports, no platform-specific dependencies.

```yaml
name: puzzle_core
description: Star Battle puzzle engine — models, validator, solver, deduction families, difficulty grader.
version: 0.1.0
publish_to: none
resolution: workspace

environment:
  sdk: ^3.5.0

dependencies:
  collection: ^1.18.0
  meta: ^1.15.0

dev_dependencies:
  test: ^1.25.0
  lints: ^4.0.0
```

### `apps/mobile/pubspec.yaml`

Flutter app. Depends on `puzzle_core` via workspace resolution.

```yaml
name: skully_bones
description: Skully Bones Treasure Adventure — mobile puzzle game.
version: 0.1.0+1
publish_to: none
resolution: workspace

environment:
  sdk: ^3.5.0
  flutter: ^3.24.0

dependencies:
  flutter:
    sdk: flutter
  puzzle_core:
    path: ../../packages/puzzle_core
  flutter_riverpod: ^2.5.0
  go_router: ^14.0.0
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0
  path: ^1.9.0
  shared_preferences: ^2.3.0
  rive: ^0.13.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  drift_dev: ^2.18.0
  build_runner: ^2.4.0

flutter:
  uses-material-design: true
  assets:
    - assets/levels/
```

### `tools/level_generator/pubspec.yaml`

Dart CLI application.

```yaml
name: level_generator
description: Offline level pack generator CLI for Skully Bones Treasure Adventure.
version: 0.1.0
publish_to: none
resolution: workspace

environment:
  sdk: ^3.5.0

dependencies:
  puzzle_core:
    path: ../../packages/puzzle_core
  args: ^2.5.0
  crypto: ^3.0.0

dev_dependencies:
  test: ^1.25.0
  lints: ^4.0.0

executables:
  level_generator:
```

This declaration makes `dart run tools/level_generator:level_generator` work as a global executable after `dart pub global activate`.

---

## Entry points

### `apps/mobile/lib/main.dart`

Minimum viable entry for milestone 5:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: SkullyBonesApp()));
}

class SkullyBonesApp extends StatelessWidget {
  const SkullyBonesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Skully Bones Treasure Adventure',
      home: PlaceholderHome(),
    );
  }
}

class PlaceholderHome extends StatelessWidget {
  const PlaceholderHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Skully Bones — scaffold ready.', style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }
}
```

Real routing via `go_router`, theme setup, and provider wiring come in milestone 6 and beyond; this placeholder is only enough to satisfy milestone 5's acceptance criteria.

### `tools/level_generator/bin/level_generator.dart`

Minimum viable CLI entry:

```dart
import 'package:args/args.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('seed', help: 'RNG seed; required for reproducible packs.')
    ..addOption('count', help: 'Total puzzles to generate.')
    ..addOption('quota', help: 'Band quota, e.g. easy=200,medium=175,hard=100,master=25.')
    ..addOption('output', help: 'Output path for the level pack JSON.')
    ..addFlag('over-fill', help: 'Disable quota enforcement (exploration mode).')
    ..addOption('max-candidates', help: 'Upper bound on candidates to generate.');

  final args = parser.parse(arguments);
  // TODO: pipeline implementation lands in milestone 4.
  throw UnimplementedError('level_generator: pipeline not yet implemented.');
}
```

---

## CI outline

GitHub Actions is the assumed CI, but the pipeline is portable.

### Required checks per PR

1. **Format.** `dart format --set-exit-if-changed .` at the workspace root.
2. **Static analysis.** `dart analyze --fatal-infos --fatal-warnings` for pure-Dart packages; `flutter analyze --fatal-infos --fatal-warnings` for `apps/mobile`.
3. **Unit tests.** `dart test` in `packages/puzzle_core` and `tools/level_generator`; `flutter test` in `apps/mobile`.
4. **Generator reproducibility smoke test.** Once milestone 4 lands: run `level_generator --seed 1 --count 20` twice on CI and assert the output bytes match.
5. **Integration tests.** Once milestone 5 lands: `flutter test integration_test/` on an iOS simulator and an Android emulator (matrix).

### Optional checks

- **Coverage gate.** Not strict for V1, but report coverage for `puzzle_core` — the engine should trend toward 90%+ since it's pure logic.
- **Build artifacts.** On tagged releases, produce `flutter build ipa` and `flutter build apk` artifacts for manual device testing.

### Suggested workflow file skeleton

`.github/workflows/ci.yaml`:

```yaml
name: ci

on:
  push:
    branches: [master]
  pull_request:

jobs:
  analyze-and-test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter --version
      - run: dart pub get
      - run: dart format --set-exit-if-changed .
      - run: dart analyze --fatal-infos --fatal-warnings
      - run: dart test packages/puzzle_core
      - run: dart test tools/level_generator
      - run: flutter test apps/mobile
```

This is an outline, not the final workflow. Tune matrix dimensions, caching, and Android emulator setup when the integration-test step lands.

---

## Bootstrap sequence (first-time setup)

The order of operations for a fresh clone:

1. Install Dart SDK and Flutter SDK matching the versions above.
2. From the repo root, run `dart pub get` — this resolves the entire workspace.
3. `cd apps/mobile && flutter create . --platforms=ios,android` if the `ios/` and `android/` scaffolds aren't already present. Run only once; do not re-run.
4. `dart analyze` and `flutter analyze` should both pass.
5. `flutter run` from `apps/mobile` should launch the placeholder home screen.
6. `dart test packages/puzzle_core` should run (and pass zero tests until milestone 1 lands).

If step 3 is needed, commit the resulting `ios/` and `android/` directories but review the generated files — Flutter's scaffolder is known to add example content that should be deleted (the default counter widget in `main.dart`, for example).
