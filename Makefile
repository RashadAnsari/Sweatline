# Run formatter and linter together (use before committing)
local: format lint

# Auto-format all Dart source files in lib/
format:
	dart format lib/

# Check for analysis issues and verify formatting is clean (used in CI)
lint:
	flutter analyze
	dart format --set-exit-if-changed lib/

# Fetch the pinned exercises-dataset commit and generate lib/exercise_data.dart
# plus assets/exercises/ (Gym visual media, licensed to this app, kept out of
# git). Run once after cloning; CI runs it before testing.
EXERCISES_DATASET_COMMIT = 7455efae41b330c265e7cd4b78dfa848e7ce5ebd
exercise-media:
	rm -rf build/exercises-dataset
	git init -q build/exercises-dataset
	git -C build/exercises-dataset fetch -q --depth 1 https://github.com/hasaneyldrm/exercises-dataset $(EXERCISES_DATASET_COMMIT)
	git -C build/exercises-dataset checkout -q FETCH_HEAD
	python3 -I tools/import_exercises.py build/exercises-dataset

# Run the app on a connected device or simulator
run:
	flutter run

# Resize docs/*.png in place to the App Store screenshot size (1284x2778)
screenshots:
	python3 tools/app_store_screenshots.py

# ── Android ───────────────────────────────────────────────────────────────────

# Build a release APK signed with the release keystore (output: build/app/outputs/apk/release/app-release.apk)
android-release:
	flutter build apk --release

# Build a release App Bundle for Play Store upload (output: build/app/outputs/bundle/release/app-release.aab)
android-bundle:
	flutter build appbundle --release

# Build and install a release APK on a connected Android device
android-install:
	flutter install --release

# ── iOS ───────────────────────────────────────────────────────────────────────

# Open the iOS Simulator app
ios-simulator:
	open -a Simulator

# Build a release iOS app (requires valid provisioning profile and Apple Developer account)
ios-release:
	flutter build ios --release

# Build a release IPA for App Store / TestFlight upload (output: build/ios/ipa/)
ios-bundle:
	flutter build ipa --release

# Build and install a release app on a connected iOS device
ios-install:
	flutter run --release
