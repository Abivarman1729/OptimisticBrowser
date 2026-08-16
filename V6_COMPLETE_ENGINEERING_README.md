# Optimistic Browser V6 — Complete Engineering Build

## What this package is

This is the V5.1 codebase promoted to a V6 engineering package with:

- pinned Flutter/Dart toolchain metadata
- reproducible Windows + Unix bootstrap scripts
- Android command-line tool bootstrap
- JDK 17 bootstrap guidance
- automatic native platform generation through the pinned Flutter SDK
- analyze/test/release-APK verification commands
- explicit separation between implemented code and native-engine-dependent capabilities

## Pinned toolchain

- Flutter stable: **3.44.6**
- Dart: **3.12.2**
- Flutter release ref: **ee80f08**
- Android command-line tools build: **15859902**
- Android platform target for bootstrap: **35**
- Android build tools: **35.0.0**
- Java: **Temurin 17**

Flutter 3.44.6 is listed in the official Flutter stable archive with Dart 3.12.2 and ref ee80f08.
Android's official download page currently lists command-line tools build 15859902.
Temurin 17 remains an LTS line.

## Why the SDK binaries are not embedded

The package deliberately does **not** contain copied third-party SDK binaries. Instead, the bootstrap scripts download the exact/pinned toolchain from upstream and configure it under `.toolchain/`.

This avoids:

- huge multi-platform archives
- stale SDK copies
- licensing/distribution ambiguity
- shipping a Windows SDK inside a package intended for Linux/macOS
- mixing incompatible Android SDK/JDK installations

The result is reproducible setup rather than a fake SDK directory.

## Windows

Run PowerShell from the project root:

    Set-ExecutionPolicy -Scope Process Bypass
    .\tooling\bootstrap_windows.ps1

The script installs/configures Flutter, Android command-line tools, Android platform/build-tools, JDK 17, generates native Flutter wrappers, then runs:

- flutter pub get
- flutter analyze
- flutter test
- flutter build apk --release

## Linux/macOS

    chmod +x tooling/bootstrap_unix.sh
    ./tooling/bootstrap_unix.sh

On macOS, iOS compilation still requires Xcode. Flutter can generate the iOS project, but Xcode is an Apple-hosted prerequisite.

## Important engineering boundary

The package does not pretend that WebView APIs magically provide:

- browser-profile-level incognito isolation (native-engine requirement)
- a full tracker-blocking network engine
- anti-fingerprinting at the Chromium engine level
- system-wide DoH/DoT interception
- complete WebRTC leak prevention

Those capabilities remain behind explicit native-engine/privacy adapter boundaries and must be implemented/tested on the target platform.

## Verification

After bootstrap succeeds, `tooling/verify_environment.*` runs the actual:

- Flutter version check
- Flutter doctor
- dependency resolution
- static analysis
- unit tests
- release APK build

A successful ZIP creation is **not** treated as proof that Flutter analysis/tests/build passed. Those commands must run on the user's real development machine.

## Official references

Flutter archive: https://docs.flutter.dev/install/archive
Flutter manual install: https://docs.flutter.dev/install/manual
Android tools: https://developer.android.com/studio
Temurin: https://adoptium.net/
