$ErrorActionPreference = "Stop"

Write-Host "== Optimistic Browser: Flutter verification ==" -ForegroundColor Cyan

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw "ERROR: Flutter SDK not found in PATH."
}

flutter --version
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --release

Write-Host "VERIFICATION PASSED: analyze + tests + release APK build." -ForegroundColor Green
