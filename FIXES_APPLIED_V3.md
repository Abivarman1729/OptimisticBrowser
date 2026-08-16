# Optimistic Browser — V3 remediation build

This package is a source-level remediation of the supplied V2 bundle. It addresses the requested gaps instead of inflating the project with fake feature counts.

## What was fixed

### 1. Private / Incognito
- Private tabs are real separate tab objects and separate WebViewController instances.
- Private tabs are excluded from persistent history and bookmarks.
- **Removed destructive global cleanup:** the public WebView API cannot isolate per-tab storage, so this build never clears global cookies/cache/local-storage when a private tab starts or ends.
- Private tabs are never persisted into the normal session-restore store.
- The UI explicitly labels private tabs.
- **Important platform boundary:** `webview_flutter` does not provide independent per-tab cookie/storage profiles. Therefore this build does not falsely claim cryptographic/profile-level incognito. Full isolation requires a native browser engine/profile architecture.

### 2. Multi-tab UI
- Visible tab strip.
- Tab overview.
- New tab.
- New private tab.
- Close tab.
- Switch tab.
- Reopen recently closed normal tab.
- Basic tab groups (Group 1/2/3).

### 3. Feature Registry
- Registry now has `implemented`, `partial`, and `planned` states.
- Partial platform boundaries are described instead of being counted as completed features.
- This prevents “100+ implemented features” from being claimed when a capability is only an architecture boundary.

### 4. Privacy
- Central privacy service with explicit capability status.
- HTTPS/HTTP navigation policy.
- Blocked-domain policy.
- Private history exclusion.
- Private WebView cleanup.
- Privacy dashboard messaging.
- Native-engine requirements are explicitly documented for:
  - network tracker/ad blocking
  - third-party cookie partitioning
  - DNS-over-HTTPS / DNS-over-TLS enforcement
  - WebRTC leak controls
  - canvas/WebGL fingerprint resistance
  - full certificate interstitial handling

### 5. Cleartext security
- Android manifest uses `usesCleartextTraffic="false"`.
- Local Android emulator HTTP is allowed only for `10.0.2.2` through the network security config.
- Production API configuration is documented as HTTPS-only.

### 6. Search
- Web / Images / Videos / News / Shopping category UI.
- Category-aware backend requests.
- Provider abstraction remains in place.
- Query validation and result URL validation remain enabled.
- Backend has bounded timeout/retry behavior.
- Configurable CORS origin.
- No external search-engine redirect is used.

Still intentionally planned: autocomplete, typo correction, ranking, trending, full region/language controls, and a dedicated shopping provider.

### 7. Page-aware AI
- Current page visible text is extracted from the WebView.
- Context is cleaned and bounded before transmission.
- URL + title + page text + user prompt are sent to the AI service.
- AI model selector (`auto`, `fast`, `balanced`, `reasoning`) is wired through the app/backend.
- Conversation is persisted locally.
- Estimated conversation token usage is displayed.

Still intentionally partial/planned: provider-native streaming, exact provider token accounting, conversation folders, and a full multi-conversation workspace.

### 8. Notebook
- Search.
- Tags.
- Markdown/text body support.
- SQLite persistence.
- Edit/delete.
- Schema migration from V1 to V2.

Still planned: backlinks, clipping/highlights, export, autosave/version history and AI note actions.

### 9. Library
- Bookmark search.
- History search.
- Bookmark deletion.
- Folder/tag schema support.
- History clearing.
- Existing bookmarks/history remain local SQLite data.

Still planned: reading list, archived pages, sync, import/export and duplicate-management UI.

### 10. Session restore
- Normal tabs, URLs, titles, group IDs and active tab are persisted.
- Private tabs are excluded.
- Restore happens during controller initialization.
- App lifecycle events trigger session persistence.
- Corrupt session data cannot prevent app startup.

### 11. Error handling
Structured `AppErrorType` is used for:
- network
- search provider
- navigation blocked
- AI provider
- database
- timeout
- permission
- certificate
- validation
- unknown

Backend errors also use structured `{ error: { type, message } }` responses.

## Source integrity fixes
The supplied V2 archive contained malformed content appended to `test/search_test.dart`, including an Android manifest fragment. That garbage was removed.

The URL policy regex was also corrected so `www.google.com` is correctly recognised as blocked.

## Verification status

Passed in the packaging environment:
- Node.js backend syntax check.
- Python AI service syntax compilation.
- JSON manifest parsing.
- Android XML parsing.
- Source-level file/integrity checks.
- Added unit tests for URL policy, tab manager and feature-registry status.

Not available in the packaging environment:
- `flutter analyze`
- `flutter test`
- Android/iOS runtime WebView tests
- release APK build

The Flutter/Dart SDK is not installed in the current packaging environment, so claiming a successful Flutter build would be inaccurate.

## Required final verification on the development machine

```text
flutter pub get
dart format .
flutter analyze
flutter test
flutter build apk --release
```

Then test on a real Android device/emulator:
1. normal tab -> private tab -> normal tab cookie/session behavior
2. private tab history/bookmark exclusion
3. app close -> reopen session restore
4. multiple tabs and tab groups
5. search category switching
6. AI “Ask this page”
7. library and notebook persistence
8. HTTPS and blocked navigation
9. production build with HTTPS API endpoints
