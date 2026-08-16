# Optimistic Browser V5.1 — Advanced Processed Build

This build merges the supplied Optimistic Browser Dart app and the supplied Optimistic AI multi-file bundle into one Flutter project architecture.

## Language split
- Flutter/Dart: application shell, WebView browser, tabs/navigation, local data, settings and native screens.
- HTML/CSS: browser-home/search surface styling.
- JavaScript: browser-home interactions and backend gateway.
- Python/FastAPI: all AI logic and provider secrets.
- Node.js: search gateway and JSON API.
- SQLite: history/bookmarks/notebook data.
- C++: not used unless a future native performance module genuinely needs it; adding C++ only to increase line count would make the project less reliable.

## Important behavior
- Optimistic Browser is the starting screen.
- Search does not navigate to Google search pages.
- Google search domains are blocked by the browser URL policy.
- A configured Brave Search API key enables real web search through the Node gateway.
- Without a key, a controlled fallback result is shown inside the Optimistic UI.
- The supplied 8K PNG is included at `assets/branding/optimistic_browser_8k.png` and is used by the Flutter home screen.

## Run
1. Open this folder in VS Code.
2. Run `flutter create .` once if platform folders are not already present.
3. Run `flutter pub get`.
4. Start the Node gateway:
   `cd backend && npm install && npm start`
5. Start Python AI:
   `cd backend/ai && python -m venv .venv`
   Windows: `.venv\\Scripts\\activate`
   macOS/Linux: `source .venv/bin/activate`
   `pip install -r requirements.txt`
   `uvicorn main:app --host 0.0.0.0 --port 8000`
6. Run Flutter on an Android emulator:
   `flutter run`

For Android emulator localhost services, the app defaults to `10.0.2.2`. For a physical phone, pass:
`--dart-define=OPTIMISTIC_API=http://YOUR_PC_IP:8787 --dart-define=OPTIMISTIC_AI=http://YOUR_PC_IP:8000`

## Why the build is not inflated to 30,000–50,000 lines
Artificially adding tens of thousands of duplicate lines would not make a browser more advanced and would make compilation, maintenance and debugging worse. This package keeps the source focused and includes the real requested language separation and architecture.

## V5.1 hardening
See `V5_1_REMEDIATION.md` for the changes made after the V5 review. `V5_1_RUNTIME_QA.md` is the machine-side validation checklist.

## Validation note
The supplied environment used to assemble this package does not contain the Flutter/Dart SDK, so a real `flutter analyze` / `flutter test` / APK build cannot be honestly claimed here. The generated package was statically checked for required files and delimiter/brace/parenthesis mismatches, and the malformed separators in the supplied `.bin` bundle were repaired.


## V3 remediation
See `FIXES_APPLIED_V3.md` for the complete remediation matrix. This build deliberately distinguishes implemented, partial and platform-required capabilities. It does not claim full browser-engine privacy features that `webview_flutter` cannot expose.


## V9 Stage 1

The V9 Stage 1 engine bridge is wired to real Android WebView operations and real iOS WKWebView data stores. Android WebView is Chromium-backed, but a separately bundled Chromium runtime and true multi-profile partitioning remain Stage 2 work. Capability reports are intentionally conservative until those components are verified.
