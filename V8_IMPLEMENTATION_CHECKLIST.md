# V8 Implementation Checklist

## Engine
- [x] BrowserEngine abstraction
- [x] Native method-channel contract
- [x] Engine capability reporting
- [x] Profile lifecycle
- [x] Rust security/core primitives
- [ ] Ship and link a real Chromium/Gecko rendering binary
- [x] Bind native Android navigation operations to real WebView instances
- [ ] Bind a separately bundled Chromium renderer lifecycle to Dart

## Privacy
- [x] Normal/private profile IDs
- [x] Private session exclusion
- [x] Storage partition model
- [x] Cookie policy model
- [x] Cache partition model
- [ ] True isolated Android per-profile data stores (Stage 2 multi-process design)
- [x] Native iOS WKWebsiteDataStore lifecycle
- [ ] Native engine cookie/cache/local-storage ownership with true partitioning (Stage 2)

## Browser features
- [x] Downloads
- [x] Upload bridge
- [x] Permission manager
- [x] Ad/tracker rules
- [x] HTTPS upgrade
- [x] Certificate validation primitives
- [x] Certificate pin store
- [x] Reader mode
- [x] Translation abstraction
- [x] Picture-in-picture bridge
- [x] Advanced tab groups
- [x] Search autocomplete

## AI
- [x] Streaming response parser
- [x] Persistent conversations
- [x] Page context extraction
- [ ] Provider-specific streaming adapters
- [ ] Token accounting and cancellation
- [ ] On-device model adapter

## Reliability
- [x] Crash heartbeat
- [x] Error classification
- [x] Retry policy
- [x] Engine health metrics
- [x] Release check service
- [x] Flutter verification scripts

## Production gate
Run `tooling/verify_v8.sh` or `tooling/verify_v8.ps1` on a machine with Flutter installed.
A successful source-generation step is not a substitute for `flutter analyze`,
`flutter test`, and `flutter build apk --release`.
