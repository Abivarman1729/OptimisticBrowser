#!/usr/bin/env bash
set -euo pipefail

echo "== Optimistic Browser: Flutter verification =="

command -v flutter >/dev/null 2>&1 || {
  echo "ERROR: Flutter SDK not found in PATH."
  exit 2
}

flutter --version
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --release

echo "VERIFICATION PASSED: analyze + tests + release APK build."
