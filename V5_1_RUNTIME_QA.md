# V5.1 Runtime QA Checklist

## Flutter
- [ ] `flutter pub get`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] `flutter build apk --release`

## Browser
- [ ] Open/close multiple tabs
- [ ] Back/forward/reload
- [ ] Recently closed tab
- [ ] Normal session restore
- [ ] Private tab is not persisted
- [ ] Private cleanup does not log normal tabs out
- [ ] HTTP is upgraded to HTTPS where policy allows
- [ ] `javascript:`, `data:` and `file:` navigation is blocked

## Search
- [ ] Offline fallback works
- [ ] Web results
- [ ] Image results
- [ ] News results
- [ ] Video results
- [ ] Shopping is clearly labelled as web fallback

## AI
- [ ] Offline fallback
- [ ] Remote provider with valid server-side key
- [ ] Invalid provider response
- [ ] Timeout handling

## Library / Notebook
- [ ] Bookmark
- [ ] History
- [ ] Reading list
- [ ] Notes
- [ ] Autosave
- [ ] Version history
- [ ] Markdown export

## Privacy/security
- [ ] Verify normal cookies survive private-tab cleanup
- [ ] Verify private history never reaches SQLite
- [ ] Verify private tabs never reach SharedPreferences session data
- [ ] Verify backend rejects unapproved Origin headers
- [ ] Verify rate limiting
- [ ] Verify request timeout

## Native-engine items still pending
- [ ] Per-profile private cookie jar
- [ ] Network tracker blocker
- [ ] Secure DNS
- [ ] WebRTC protection
- [ ] Anti-fingerprinting
- [ ] Download manager
- [ ] Site permission manager
- [ ] Safe Browsing/phishing service
