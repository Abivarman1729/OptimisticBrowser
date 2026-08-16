# Optimistic Browser — V2 hardening and completion pass

This bundle is a source-level remediation build. It is **not** claimed to be APK/runtime verified because the packaging environment does not include Flutter/Dart SDK.

## Fixed / upgraded
- Real tab UI with new-tab, private-tab, switch, close and reopen-closed flows.
- Per-tab WebViewController instances instead of one shared WebView.
- Session persistence/restoration through SharedPreferences.
- Private tabs do not persist history/bookmarks and clear WebView cookies/cache/storage at private-session boundaries.
- Address/search bar and active-tab state.
- Page-aware AI: visible page text is extracted from the WebView and passed to the AI backend with URL/title.
- Structured Dart error model.
- Search categories (`web`, `images`, `news`, `videos`, `shopping`), with shopping explicitly treated as web-search until a dedicated shopping provider is added.
- Backend structured error responses, safer generic 500 responses, security response headers and validation.
- Android `usesCleartextTraffic=false`; only the emulator gateway `10.0.2.2` is explicitly permitted for local HTTP.
- Feature registry now distinguishes implemented capabilities from planned boundaries.

## Platform limitations that are deliberately NOT faked
`webview_flutter` does not expose a full browser-engine profile manager, network interception stack, DNS resolver, certificate UI, or resource-level tracker filter. Therefore the following require a native Android/iOS layer or a different browser engine:
- OS-level true storage partitioning / independent cookie profiles
- network-level tracker/ad blocking
- DNS-over-HTTPS/DNS-over-TLS enforcement
- WebRTC leak prevention at network level
- canvas/WebGL fingerprint randomisation
- full certificate/security interstitials
- a production download manager with background service support

The code does not label these as implemented merely because a feature name exists in the registry.

## Verification performed in this environment
- Node.js backend syntax check: PASS
- Python AI backend syntax compilation: PASS
- Flutter/Dart analyzer: NOT RUN (Flutter/Dart SDK unavailable in this environment)
- APK build: NOT RUN
- Android runtime/WebView test: NOT RUN

Before release, run:
`flutter pub get`
`dart format .`
`flutter analyze`
`flutter test`
`flutter build apk --release`

Then perform a real-device privacy/session/navigation test.
