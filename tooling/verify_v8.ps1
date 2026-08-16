$ErrorActionPreference = "Stop"
flutter --version
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --release
Write-Host "V8 verification PASSED"
