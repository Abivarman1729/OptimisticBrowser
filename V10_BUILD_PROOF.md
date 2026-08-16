# V10 Build / Verification Status

## What was verified in this package
- V9 source archive was unpacked and upgraded to version `10.0.0+1`.
- Flutter/native engine boundary was hardened.
- Android native backend reports the installed Chromium-backed System WebView version.
- AndroidX WebKit `MULTI_PROFILE` is checked at runtime; V10 never fakes it.
- Premium HTML/CSS/JS browser UI was upgraded.
- Python remains the AI backend.
- A deterministic `tool/verify_v10.sh` source/compile verifier is included.

## Host limitation
This packaging environment does not have the Flutter SDK executable, so a real `flutter analyze` / `flutter build apk` result cannot honestly be reported as passed here.

Run:

```bash
./tool/verify_v10.sh
flutter build apk --release
```

on the Android/Flutter development machine.

## Chromium/CEF clarification
A real Android CEF binary is not included. CEF is a desktop embedding framework, not a supported Android runtime. Shipping a placeholder or relabeling Android System WebView as CEF would make the build claim false. V10 therefore keeps the native engine boundary explicit and uses Android System WebView as the real Android Chromium runtime.
