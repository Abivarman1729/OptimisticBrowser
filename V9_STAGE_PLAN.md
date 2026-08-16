# Optimistic Browser V10 — 3-Stage Production Plan

## Stage 1 — Engine foundation + critical correctness (COMPLETED)
- Wire the Android MethodChannel to real Android WebView/Chromium-backed operations.
- Register the native bridge from `MainActivity`.
- Add engine introspection instead of claiming an unimplemented Chromium binary.
- Make capability reporting honest.
- Replace the fake certificate fingerprint with real SHA-256.
- Add Flutter unit coverage for certificate security and engine contracts.
- Keep the current UI stable while establishing the native engine seam.

## Stage 2 — Chromium-backed privacy/network backend (COMPLETED IN SOURCE)
- Use the Android System WebView Chromium runtime through AndroidX WebKit.
- Use AndroidX WebKit MULTI_PROFILE for real per-profile cookie/cache/WebStorage isolation.
- Treat private profiles as ephemeral: destroy the WebView and delete the private profile.
- Add native request interception and host-based content blocking.
- Add truthful runtime capability reporting for MULTI_PROFILE and blocking.
- Keep iOS on WKWebView with nonPersistent data stores for private sessions.
- Document the AndroidX WebKit dependency and the limitation that this is not a separately bundled Chromium binary.


## Stage 3 — Production hardening + V10 release gate
- Durable/resumable downloads with Range and persistence.
- Provider-specific AI streaming, cancellation, retry and accounting.
- Reader/translation/PiP/tab-group lifecycle hardening.
- Crash recovery telemetry and safe restart.
- Full integration/widget tests and release verification.
- Re-score the final system and generate the consolidated V10 release bundle.

> Important: Stage 1 does not claim that the application already contains a
> separately bundled Chromium browser binary. Android WebView is Chromium-backed,
> while iOS uses WebKit. A true embedded Chromium runtime is a Stage 2 task.
