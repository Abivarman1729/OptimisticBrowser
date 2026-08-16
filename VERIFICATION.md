# Verification status

## Source checks
- Node.js backend: `node --check backend/src/server.js` — PASS
- Python backend: `python -m py_compile backend/ai/main.py` — PASS
- Flutter analyzer/test/build — NOT RUN here because Flutter/Dart SDK is unavailable.

## Required local release gate
```bash
flutter pub get
dart format .
flutter analyze
flutter test
flutter build apk --release
```

## Manual test matrix
1. Create normal tabs A/B/C; switch between them.
2. Close B; reopen B with Recently Closed.
3. Kill and relaunch; verify normal tabs restore.
4. Create private tab; verify it is not present after relaunch.
5. Browse in private tab; verify history/bookmarks are not persisted.
6. Exit/close private tab; verify cookies/cache/local storage are cleared.
7. Search Web/Images/News/Videos.
8. Open a page and ask AI about visible page text.
9. Test blocked URL schemes and blocked domains.
10. Run release build with HTTPS backend and confirm no production cleartext dependency.
