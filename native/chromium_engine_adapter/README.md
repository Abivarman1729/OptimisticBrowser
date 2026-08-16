# V10 Native Chromium Engine Boundary

V10 deliberately does **not** ship a fake or mislabeled Android CEF binary.

- Android primary: Android System WebView, Chromium-backed.
- Android profile isolation: AndroidX WebKit `MULTI_PROFILE` when the installed WebView exposes it.
- CEF: desktop embedding technology; it is not an Android CEF runtime. A real CEF backend must be a separate desktop target.
- The adapter boundary exists so a future supported native engine can be plugged in without changing the Flutter UI.

`bundledChromiumBinary` is therefore `false` in V10 capability reporting. This is intentional and is part of the compile/runtime contract.
