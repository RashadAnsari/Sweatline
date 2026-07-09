# Sweatline agent rules

Flutter app (iOS/Android), offline-only, no backend. Read README.md for the
architecture overview.

## Conventions

- **All user-facing strings go through l10n**: add keys to
  `lib/l10n/app_en.arb`, then run `flutter gen-l10n`. Never hardcode UI
  text in widgets.
- **Seed data is the exception**: exercise names, how-to steps, and trainer
  tips live in `lib/exercise_library.dart` as data, not in ARB files.
- **Stable keys, localized labels**: day keys (`push`, `lowerA`), muscle
  keys (`quads`), equipment keys, and enum names are stored in
  persistence; display labels come from `lib/labels.dart`. Never persist a
  display label, never display a raw key.
- **Weights are stored in kilograms**, always. Convert to the user's
  display unit only at the UI boundary via `kgToUnit` / `unitToKg` in
  `lib/labels.dart`.
- **Persistence is SQLite** (`lib/database.dart`, `AppDatabase`). Session
  history is normalized across the `sessions` / `exercise_logs` / `set_logs`
  tables; plan, draft, and settings are rows in the `meta` key-value table.
  When the schema changes, bump the version in `AppDatabase` and add an
  `onUpgrade` branch. `AppStore` loads everything into an in-memory cache at
  `open` and writes incrementally, keeping its reads synchronous for the UI.
- **Theme discipline**: colors come from the `ColorScheme` in
  `lib/theme.dart` (volt/charcoal identity, Bebas Neue display font).
  Never hardcode colors in widgets.
- Required form field labels end with ` *`; validation errors are inline
  and explain what to enter.
- No em dashes or en dashes anywhere: prose, comments, or UI copy.

## Verification (run before finishing any change)

```sh
dart format lib test
flutter analyze
flutter test --exclude-tags golden
```

## Releases

- Bump `version:` in pubspec.yaml.
- App icon: `flutter test --update-goldens --tags golden
  test/tools/app_icon_test.dart` then `dart run flutter_launcher_icons`.
