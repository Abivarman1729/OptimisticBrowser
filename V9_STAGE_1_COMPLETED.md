# V9 Stage 1 — Completed

Date: 2026-08-15

## Completed
1. Android native engine bridge is no longer a stub.
2. `MainActivity` explicitly registers the native bridge.
3. Android reports its real Chromium-backed WebView engine/version.
4. Native profile objects now create/configure real Android WebView instances.
5. Native navigation and user-agent calls are wired to real WebView operations.
6. Native profile cleanup performs real WebView/history/cache/cookie cleanup.
7. iOS bridge now creates real `WKWebView` instances with persistent/non-persistent stores.
8. Capability reporting no longer falsely claims per-profile storage, interception or blocking.
9. Certificate fingerprints now use SHA-256 over certificate DER bytes.
10. Added Flutter tests for SHA-256 and certificate validation.
11. Updated version to 9.0.0+1 and added the `crypto` dependency.

## Verification boundary
This packaging environment does not have Flutter, Dart or Cargo installed, so
`flutter pub get`, `flutter analyze`, `flutter test`, and `flutter build apk`
could not be executed here. The source/test changes are included, but machine-level
compile verification must be run after the archive is opened on a Flutter SDK machine.

## Stage 2 is intentionally NOT started.
