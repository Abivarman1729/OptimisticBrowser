# Optimistic Browser V8 — Advanced Engine Architecture

## Goal

V8 is the V7 Advanced project upgraded around eighteen production features:

1. Actual Flutter compile verification
2. Native browser-engine integration
3. Private profile isolation
4. Cookie/cache/local-storage partitioning
5. Download manager
6. File upload
7. Permission manager
8. Ad/tracker blocking
9. HTTPS/certificate security
10. AI streaming
11. Persistent AI conversations
12. Search autocomplete
13. Reader mode
14. Page translation
15. Picture-in-picture
16. Advanced tab groups
17. Crash/error recovery
18. Production release checks

## Language strategy

- Dart: Flutter UI, orchestration, state, tests and cross-platform feature contracts.
- Kotlin: Android platform engine adapters, WebView profiles, downloads and PIP.
- Swift: iOS WKWebView data-store and PIP adapters.
- Rust: future high-performance browser core primitives, URL policy, filtering and
  profile/session orchestration where a native embedded engine is available.
- Python: AI/backend services already present in the V7 project.

## Important engine boundary

This release does **not** pretend that `webview_flutter` itself is Chromium.
The Dart `BrowserEngine` contract now exposes the native-engine boundary. The
`NativeEngineBridge` is the integration point for a profile-aware native runtime.

A full Chromium/Gecko rendering engine is a separate native binary integration
project and cannot honestly be created by adding Dart classes alone. V8 therefore
ships the correct architecture first, while preserving the existing WebView
fallback.

## Verification

Run:

- `flutter pub get`
- `dart format .`
- `flutter analyze`
- `flutter test`
- `flutter build apk --release`

The repository also contains shell/PowerShell verification scripts.
