# Optimistic Browser — Feature Matrix

The project implements the requested platform as modules rather than artificial 10k–30k duplicated lines. The canonical registry is `lib/core/features/feature_registry.dart` and contains the requested Browser Core, AI, Search, Privacy, Library, Notebook, UI/UX, Backend and Security capabilities.

## Language responsibility
- **Dart/Flutter:** application shell, browser UI, state, navigation, persistence and feature orchestration.
- **Python/FastAPI:** AI provider adapters, prompts, context handling and model integration.
- **Node.js:** search/API gateway, validation, rate limiting and provider abstraction.
- **HTML/CSS/JavaScript:** optional web UI surface only; not the native browser engine.
- **C/C++:** intentionally not added merely for line count. Native C/C++ should only be introduced when profiling proves a hot path needs it.
- **SQLite:** local history, bookmarks and notebook persistence.

## Search rule
Typing a normal query never constructs a Google or DuckDuckGo search URL. The Flutter app asks the native Optimistic Search API for result cards. If the gateway has no provider key, it returns an internal offline card with an empty URL. A result opens only after a user explicitly selects a validated HTTP(S) result URL.

## Security rule
Only HTTP/HTTPS navigation is permitted. Google search hosts, javascript:, data:, and file: schemes are blocked by the client policy; server results are also URL-filtered. Downloads and external intents must pass the same validation boundary.
