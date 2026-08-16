$ErrorActionPreference="Stop"
Write-Host "=== Optimistic Browser V6 environment verification ==="
flutter --version
dart --version
java -version
adb version
flutter doctor -v
flutter pub get
flutter analyze
flutter test
flutter build apk --release
