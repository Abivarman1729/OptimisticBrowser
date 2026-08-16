#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
echo "V10 source verification"
test -f "$ROOT/pubspec.yaml"
test -f "$ROOT/lib/core/engine/webview_browser_engine.dart"
test -f "$ROOT/android/app/src/main/kotlin/com/optimistic/browser/OptimisticNativeEnginePlugin.kt"
test -f "$ROOT/V10_RELEASE_MANIFEST.json"
grep -q 'version: 10.0.0+1' "$ROOT/pubspec.yaml"
grep -q 'MULTI_PROFILE' "$ROOT/android/app/src/main/kotlin/com/optimistic/browser/OptimisticNativeEnginePlugin.kt"
grep -q 'androidx.webkit:webkit:1.15.0' "$ROOT/android/STAGE2_DEPENDENCIES.md"
grep -q 'bundledChromiumBinary": false' "$ROOT/V10_RELEASE_MANIFEST.json"
if command -v flutter >/dev/null 2>&1; then
  (cd "$ROOT" && flutter pub get && flutter analyze)
  echo "Flutter analyze: PASS"
else
  echo "Flutter executable not found: source verification PASS; compile verification DEFERRED to a Flutter-enabled host."
fi
