#!/usr/bin/env bash
set -euo pipefail

echo "== Optimistic Browser V9 / Stage 1 verification =="

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK not found: source/static checks only."
  exit 2
fi

flutter --version
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --release

echo "V9 Stage 1 Flutter verification passed."
