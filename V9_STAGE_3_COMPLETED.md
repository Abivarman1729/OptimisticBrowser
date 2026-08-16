# Stage 3 — COMPLETED

Stage 3 consolidates Stage 1 + Stage 2 and adds production hardening.

## Incognito tab contract

`BrowserTabMode.private` is now explicitly ephemeral. Private tabs do not receive a persisted `profileId`, are excluded from tab-session persistence, and are intended to be backed by the native private profile created by `V8BrowserCoordinator.openPrivateProfile()`.

Android uses AndroidX WebKit MULTI_PROFILE when the installed WebView supports it. Profile-level cookies, WebStorage, HTTP cache and service-worker data are separated by profile. Private profiles are deleted on disposal.

iOS uses `WKWebsiteDataStore.nonPersistent()` and reports only capabilities actually available through the public WebKit API.

## Stage 3 features

1. Durable/resumable downloads with HTTP Range and persistence.
2. Proper HTTP client cleanup.
3. AI provider modes, cancellation, retry/backoff and usage metadata.
4. Private-tab session persistence exclusion.
5. Crash recovery last-tab/URL metadata.
6. iOS MethodChannel bridge registration.
7. Service-worker request blocking on Android profile backends.
8. Final release manifest and device verification checklist.

## Verification truth

The current build environment does not include Flutter/Dart/Cargo/Gradle, so compilation cannot be truthfully marked as passed here. Run `tool/verify_v10_final.sh` on the user's configured Flutter machine.
