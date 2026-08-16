# Optimistic Browser V9 — Stage 1 Engine Readiness

## What was added

### Actual Flutter compile verification pipeline
`tool/verify_flutter.ps1` and `tool/verify_flutter.sh` run:

1. `flutter --version`
2. `flutter pub get`
3. `dart format --output=none --set-exit-if-changed lib test`
4. `flutter analyze`
5. `flutter test`
6. `flutter build apk --release`

The scripts fail fast and return a non-zero exit code on any failure.

### Browser-engine abstraction
`lib/core/engine/` introduces a stable engine contract and capability report.

The current `webview_flutter` implementation is explicitly reported as:

- JavaScript: supported
- Downloads: supported by platform WebView capabilities
- File upload: supported
- Private history/session isolation: supported by the Flutter layer
- Per-profile cookies: not supported by the public API
- Per-profile cache: not supported by the public API
- Per-profile local storage: not supported by the public API
- Network interception: not supported by this adapter
- Content blocking: not supported by this adapter

## Important production-readiness boundary

This build is **engine-ready**, but it is not honest to call the current
`webview_flutter` backend a fully production-private browser engine.

True private-profile isolation requires a native browser engine/profile backend
that owns separate storage partitions. The new interface allows that backend
to replace `WebViewBrowserEngine` without changing the browser UI, tab manager,
history, AI, library, or notebook layers.

The application intentionally does not clear global WebView cookies/cache/local
storage when a private tab closes, because doing so can destroy normal browsing
state.

## Verification status

This environment did not contain the Flutter SDK, so the release APK was not
compiled inside this packaging step. Run the supplied verification script on a
machine with Flutter installed. A successful run is required before claiming
"compile verified".


## V9 Stage 1 additions

- Android MethodChannel now invokes real Chromium-backed Android WebView operations.
- MainActivity explicitly registers the native bridge.
- iOS bridge owns real WKWebView instances and data stores.
- Certificate fingerprints use SHA-256.
- Capability reporting is conservative and no longer claims unsupported isolation/interception.
- Flutter tests cover the new cryptographic behavior.
