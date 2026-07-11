# Sweatline

Personal training app for iPhone and Android, built with Flutter. Answer three
questions and it builds you a weekly gym plan the way a coach would, then walks
you through every session set by set and tracks how strong you are getting.

Everything runs offline. There is no account, no backend, and no analytics. The
release build ships without the `INTERNET` permission, so the app cannot send
your data anywhere even if it wanted to.

## Screenshots

<table>
  <tr>
    <td><img src="docs/today-workout.png" alt="Today workout screen" width="180"></td>
    <td><img src="docs/plan-overview.png" alt="Plan overview screen" width="180"></td>
    <td><img src="docs/exercise-library.png" alt="Exercise library screen" width="180"></td>
    <td><img src="docs/progress-dashboard.png" alt="Progress dashboard screen" width="180"></td>
    <td><img src="docs/exercise-detail-overview.png" alt="Exercise detail overview screen" width="180"></td>
  </tr>
  <tr>
    <td align="center">Today</td>
    <td align="center">Plan</td>
    <td align="center">Library</td>
    <td align="center">Progress</td>
    <td align="center">Exercise detail</td>
  </tr>
  <tr>
    <td><img src="docs/exercise-detail-instructions.png" alt="Exercise instructions screen" width="180"></td>
    <td><img src="docs/workout-warmup.png" alt="Workout warmup screen" width="180"></td>
    <td><img src="docs/workout-set-logging.png" alt="Workout set logging screen" width="180"></td>
    <td><img src="docs/workout-rest-timer.png" alt="Workout rest timer screen" width="180"></td>
    <td><img src="docs/workout-summary.png" alt="Workout summary screen" width="180"></td>
  </tr>
  <tr>
    <td align="center">Instructions</td>
    <td align="center">Warmup</td>
    <td align="center">Set logging</td>
    <td align="center">Rest timer</td>
    <td align="center">Summary</td>
  </tr>
</table>

## Features

- **Built-in trainer**: a three-question quiz (goal, experience, frequency)
  generates a plan from proven splits: full body, push/pull/legs,
  upper/lower, or PPL twice for 6 days a week.
- **Real programming**: compound lifts first with warm-up sets, heavier
  loads, and longer rests; isolation work with higher reps; rep ranges and
  rest periods tuned per goal; double-progression weight suggestions.
- **Guided workouts**: one exercise at a time, target weight from your last
  session, set logging, and a wall-clock rest timer with a haptic buzz.
  The screen stays awake, and an in-progress workout survives an app kill
  (auto-saved draft with resume).
- **Swap exercises**: replace any move with a similar one that trains the
  same muscles and fills the same role (a compound for a compound, an
  isolation for an isolation). Swap just for today mid-workout, or save the
  change to your plan.
- **Exercise encyclopedia**: 63 exercises with equipment, animated
  movement pictograms (a figure tweening between start and end position,
  drawn in code from pose data in `lib/exercise_poses.dart`), muscle maps
  (front/back diagrams with primary and secondary muscles highlighted),
  step-by-step instructions, and trainer form cues.
- **Progress tracking**: weekly and total stats, per-exercise strength
  trends, and full session history.
- **Settings**: kg/lb display units (storage is always kg), light/dark/system
  theme, clipboard backup and restore.

## Development

```sh
flutter pub get
flutter gen-l10n     # generates lib/l10n/app_localizations*.dart
flutter run
```

Quality gates (all must pass, CI enforces them):

```sh
dart format lib test
flutter analyze
flutter test --exclude-tags golden
```

### App icon and splash screen

Both images are rendered by golden tests, then fanned out to the native
platform sizes:

```sh
flutter test --update-goldens --tags golden test/tools/app_icon_test.dart
dart run flutter_launcher_icons

flutter test --update-goldens --tags golden test/tools/splash_logo_test.dart
dart run flutter_native_splash:create
```

### Releasing

Bump `version:` in `pubspec.yaml` first. The build number after the `+` has to
increase on every upload, or the stores reject the artifact.

```sh
make android-bundle   # build/app/outputs/bundle/release/app-release.aab
make ios-bundle       # build/ios/ipa/
```

Android release builds need a local `android/key.properties`. Copy
`android/key.properties.example`, fill in the keystore values, and keep the
real file out of git. A Gradle task refuses to build a release without it,
rather than quietly producing a debug-signed artifact.

iOS targets iPhone only and is locked to portrait.
`ios/Runner/PrivacyInfo.xcprivacy` declares no tracking and no data
collection, which is what the App Store privacy label reports.

## Architecture

Single local store (`lib/store.dart`, a `ChangeNotifier` over SQLite via
`lib/database.dart`) exposed through an `InheritedNotifier`. Workout history
is normalized across `sessions` / `exercise_logs` / `set_logs` tables, so
logging a workout is a few row inserts rather than a rewrite of the whole
history; plan, in-progress draft, and settings live as rows in a small
`meta` key-value table. Domain models in `lib/models.dart` serialize to JSON
with stable string keys; all user-facing strings go through
`flutter gen-l10n` (`lib/l10n/app_en.arb`). The exercise library and plan
templates are code-defined seed data in `lib/exercise_library.dart` and
`lib/plan_generator.dart`.

The store keeps a synchronous public API by loading everything into memory
once at `AppStore.open` and writing incrementally. The schema version is
SQLite's `PRAGMA user_version`. Corrupt meta values are dropped, never crash
the app. Weights are stored in kilograms and converted at the display
boundary.

## Privacy

All data stays on the device, in a SQLite database inside app-local storage.
The app has no account system, no analytics, no crash reporting, and no server.
`INTERNET` is declared only in the debug manifest, so a release build cannot
make a network request at all. Full text: [docs/privacy-policy.md](docs/privacy-policy.md).

Keeping that true is a hard constraint. Adding a dependency that talks to the
network invalidates the privacy policy and the "no data collected" answers
filed with both stores.

## Disclaimer

Sweatline is not medical advice. Ask a doctor before you start a new training
plan, and stop right away if you feel pain.

## License

[MIT](LICENSE).
