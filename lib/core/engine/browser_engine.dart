import 'engine_capabilities.dart';

/// Contract between the Flutter browser shell and the native browser engine.
///
/// The UI and higher-level browser services must depend only on this
/// abstraction. Platform-specific implementation details belong behind the
/// engine boundary.
abstract interface class BrowserEngine {
  /// Describes the capabilities exposed by the active engine implementation.
  EngineCapabilities get capabilities;

  /// Whether the native engine has completed initialization.
  bool get initialized;

  /// Currently active engine profile identifier.
  String get profileId;

  /// Currently active profile mode.
  EngineProfileMode get mode;

  /// Initializes the native engine bridge.
  Future<void> initialize();

  /// Creates or switches to an engine profile.
  Future<void> createProfile({
    required String profileId,
    required EngineProfileMode mode,
  });

  /// Returns whether the engine accepts the supplied URI.
  bool canNavigate(Uri uri);

  /// Navigates the active engine profile to [uri].
  Future<void> navigate(Uri uri);

  /// Updates the user agent for the active profile.
  Future<void> setUserAgent(String value);

  /// Configures host-level content blocking for the active profile.
  Future<void> setBlockedHosts(Iterable<String> hosts);

  /// Clears browsing data belonging to the active profile.
  Future<void> clearBrowsingData();

  /// Clears private-session data when the active profile is private.
  Future<void> clearPrivateSession();

  /// Releases native resources associated with the active profile/engine.
  Future<void> dispose();
}

/// Browser profile isolation mode.
enum EngineProfileMode {
  normal,
  private;

  bool get isPrivate => this == EngineProfileMode.private;
}
