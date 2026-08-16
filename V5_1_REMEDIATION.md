# Optimistic Browser V5.1 — Processed Remediation

This package is a processed/hardened revision of the supplied V5 bundle.

## Changes applied

### 1. Private-session correctness
- Private tabs are excluded from persisted session state.
- Private cleanup no longer calls the global WebView cookie clear API.
- This avoids a critical bug where closing a private tab could log normal browsing sessions out.
- Full cookie/storage profile isolation remains **platform-required** and is explicitly not claimed as complete.

### 2. Backend hardening
- `ALLOWED_ORIGINS` supports an explicit comma-separated CORS allowlist.
- Unknown browser origins are rejected when an origin header is present.
- Security response headers were added: `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, `Permissions-Policy`, and `Cross-Origin-Resource-Policy`.
- Provider request timeout is configurable through `REQUEST_TIMEOUT_MS`.
- The in-memory rate limiter cleans expired entries to avoid unbounded growth during long-running development.
- Existing retry behavior is retained and bounded to two attempts.
- No wildcard CORS is emitted for configured/known browser origins.

### 3. Versioning
- Flutter package version is now `5.1.0+2`.
- The internal source root should be renamed to `OptimisticBrowser_V5_1_Processed` when packaging/deploying; the ZIP root has already been normalized to that name.

## Deliberately NOT falsely implemented
The following still require native browser-engine work and are therefore not marked complete:
- true per-profile incognito cookie/storage partitioning
- network-level tracker/ad blocking
- DoH/DoT enforcement
- WebRTC leak prevention
- Canvas/WebGL anti-fingerprinting
- robust download manager
- complete site permission lifecycle
- phishing/safe-browsing database
- APK/Flutter runtime verification

## Required machine-side verification
Run these on a machine with Flutter/Android SDK:

1. `flutter pub get`
2. `flutter analyze`
3. `flutter test`
4. `flutter build apk --release`
5. Install the APK on emulator and physical Android device.
6. Test normal/private tabs, cookies, history, session restore, navigation blocking, search, AI fallback, notes, bookmarks and backend connectivity.

A successful static package preparation is **not** equivalent to a successful Flutter build.
