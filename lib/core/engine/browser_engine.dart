import 'engine_capabilities.dart';

/// Contract between the Flutter browser shell and the underlying web engine.
///
/// The current implementation is backed by platform WebView. The interface
/// deliberately keeps engine-specific capabilities out of UI code so a
/// production engine such as a native Chromium/Gecko profile backend can be
/// introduced without rewriting tabs, history, AI, library, or notebook code.
abstract interface class BrowserEngine {
  EngineCapabilities get capabilities;

  Future<void> initialize();

  /// Returns whether a navigation can be admitted by the engine layer.
  bool canNavigate(Uri uri);

  /// Clears only data that the current engine can safely scope.
  Future<void> clearPrivateSession();

  Future<void> dispose();
}
