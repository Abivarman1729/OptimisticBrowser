# Optimistic Browser V9 — Stage 2 completion

## Implemented
1. Android Chromium-backed runtime remains the Android System WebView.
2. AndroidX WebKit MULTI_PROFILE is now the native profile backend.
3. Normal/private profiles use distinct WebView Profile names.
4. Profile-specific CookieManager is used.
5. Profile-specific WebStorage is used.
6. Profile-specific cache is cleared through the profile WebView.
7. Private profiles are deleted after their WebView is destroyed.
8. Native request interception is implemented through shouldInterceptRequest.
9. Host/subdomain blocking is configurable per profile.
10. Runtime capability reporting checks MULTI_PROFILE support.
11. Flutter native bridge exposes blocked-host configuration.
12. Stage-2 Dart privacy contract tests were added.
13. iOS continues to use WKWebsiteDataStore.nonPersistent() for private profiles.

## Important accuracy boundary

This is a Chromium-backed Android WebView engine, not a separately bundled Chromium/CEF binary. Android's official AndroidX WebKit multi-profile API provides real profile data separation when the installed WebView supports MULTI_PROFILE.

The source cannot truthfully mark a device as fully production-ready until the user's Flutter/Android toolchain runs the project and tests.

## Required Android dependency

    implementation("androidx.webkit:webkit:1.15.0")
