#!/usr/bin/env bash
set -euo pipefail
flutter --version
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --release
echo "V8 verification PASSED"
