#!/usr/bin/env bash
set -euo pipefail
command -v flutter >/dev/null || { echo 'Flutter SDK unavailable'; exit 2; }
flutter pub get
 dart format --output=none .
flutter analyze
flutter test
flutter build apk --release
