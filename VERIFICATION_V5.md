# Optimistic Browser V5 verification

V5 adds concrete application-layer implementations for advanced search, AI workspace, notebook, and library capabilities, plus a native-engine adapter contract for controls that Flutter WebView cannot itself enforce.

## Important limitation

This environment does not contain the Flutter SDK. Therefore `flutter analyze`, `flutter test`, and `flutter build apk` could not be executed here. The included `tool/verify_v5.py` performs structural verification only.

The following controls remain **native-engine/platform dependent**, not falsely marked as guaranteed by WebView:

- true per-profile Incognito storage isolation
- third-party cookie partitioning
- low-level tracker/ad interception
- WebRTC leak prevention
- DoH/DoT enforcement
- certificate interception/security interstitials
- Canvas/WebGL anti-fingerprinting

A production build must provide and test a native browser-engine adapter for these capabilities before claiming full enforcement.
