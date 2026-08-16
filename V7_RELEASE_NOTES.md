# V7 Release Notes

## Hardened in V7
- Removed unsafe global WebView cache/local-storage cleanup from private-tab lifecycle.
- Kept private history/bookmark/session persistence excluded.
- Made the true-incognito native-profile limitation explicit.
- Corrected history title persistence to use the resolved page title.
- Updated capability wording so registry claims remain honest.
- Added the complete engineering audit and production release gate.

## Already present and retained
- Tab strip + tab overview
- Tab groups
- Recently closed
- Session restore
- Search categories
- Brave search gateway
- AI visible-page text extraction
- SQLite library/notebook persistence
- HTTPS upgrade and navigation policy
- Structured application errors
- Android cleartext hardening

## Important
V7 is source-audited but not Flutter-build-verified in this sandbox because Flutter is not installed here. Run `flutter pub get`, `flutter analyze`, `flutter test`, and a release build on the target development machine.
