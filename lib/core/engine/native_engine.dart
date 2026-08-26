import 'package:flutter/services.dart';

import 'browser_engine.dart';
import 'engine_capabilities.dart';
import 'engine_health_monitor.dart';
import 'native_engine_bridge.dart';

/// Production-oriented browser engine facade.
///
/// Flutter UI code must communicate with the browser engine through this
/// abstraction rather than directly accessing Android WebView, GeckoView, or
/// another native rendering implementation.
///
/// The native implementation can evolve independently behind
/// [NativeEngineBridge].
class NativeBrowserEngine implements BrowserEngine {
  NativeBrowserEngine({
    NativeEngineBridge? bridge,
    EngineHealthMonitor? healthMonitor,
  }) : _bridge = bridge ?? const NativeEngineBridge(),
       healthMonitor = healthMonitor ?? EngineHealthMonitor();

  final NativeEngineBridge _bridge;

  /// Engine health metrics owned by this engine facade.
  final EngineHealthMonitor healthMonitor;

  bool _initialized = false;

  String _profileId = 'default';

  EngineProfileMode _mode = EngineProfileMode.normal;

  EngineCapabilities _capabilities = const EngineCapabilities(
    engineName: 'Optimistic Native Browser Engine',
    engineVersion: '10.0',
    supportsJavaScript: true,
    supportsDownloads: true,
    supportsFileUpload: true,
    supportsPrivateHistoryIsolation: true,
    supportsPerProfileCookies: true,
    supportsPerProfileCache: true,
    supportsPerProfileLocalStorage: true,
    supportsNetworkInterception: true,
    supportsContentBlocking: true,
  );

  @override
  EngineCapabilities get capabilities => _capabilities;

  @override
  bool get initialized => _initialized;

  @override
  String get profileId => _profileId;

  @override
  EngineProfileMode get mode => _mode;

  /// Native engine diagnostic information.
  Future<NativeEngineInfo> getEngineInfo() {
    _requireInitialized();
    return _bridge.getEngineInfo();
  }

  /// Initializes the native engine subsystem.
  ///
  /// Initialization is idempotent.
  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      await _bridge.initialize();

      // Ensure the default profile exists before reporting the engine ready.
      await _bridge.createProfile(_profileId, privateProfile: _mode.isPrivate);

      await _refreshCapabilities();

      _initialized = true;
    } catch (error) {
      healthMonitor.recordError();
      rethrow;
    }
  }

  /// Creates or switches to an engine profile.
  ///
  /// The profile itself is owned by the native implementation. This facade
  /// only tracks which profile is currently active.
  @override
  Future<void> createProfile({
    required String profileId,
    required EngineProfileMode mode,
  }) async {
    _requireInitialized();

    final String normalizedId = profileId.trim();

    if (normalizedId.isEmpty) {
      throw ArgumentError.value(
        profileId,
        'profileId',
        'Profile ID cannot be empty.',
      );
    }

    try {
      await _bridge.createProfile(normalizedId, privateProfile: mode.isPrivate);

      _profileId = normalizedId;
      _mode = mode;
    } catch (error) {
      healthMonitor.recordError();
      rethrow;
    }
  }

  /// Returns whether the supplied URI is supported by the engine.
  ///
  /// The engine itself accepts normal HTTP(S) navigation. Higher-level
  /// security and privacy policies should still run before this method.
  @override
  bool canNavigate(Uri uri) {
    if (uri.host.trim().isEmpty) {
      return false;
    }

    final String scheme = uri.scheme.toLowerCase();

    return scheme == 'http' || scheme == 'https';
  }

  /// Navigates the active profile.
  @override
  Future<void> navigate(Uri uri) async {
    _requireInitialized();

    if (!canNavigate(uri)) {
      throw ArgumentError.value(uri, 'uri', 'Unsupported navigation URI.');
    }

    final DateTime startedAt = DateTime.now();

    try {
      await _bridge.navigate(uri.toString(), profileId: _profileId);

      healthMonitor.recordNavigation(DateTime.now().difference(startedAt));
    } catch (error) {
      healthMonitor.recordError();
      rethrow;
    }
  }

  /// Sets the user agent of the active profile.
  @override
  Future<void> setUserAgent(String value) async {
    _requireInitialized();

    final String normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(value, 'value', 'User agent cannot be empty.');
    }

    try {
      await _bridge.setUserAgent(normalized, profileId: _profileId);
    } catch (error) {
      healthMonitor.recordError();
      rethrow;
    }
  }

  /// Replaces the blocked host list for the active profile.
  @override
  Future<void> setBlockedHosts(Iterable<String> hosts) async {
    _requireInitialized();

    try {
      await _bridge.setBlockedHosts(hosts, profileId: _profileId);
    } catch (error) {
      healthMonitor.recordError();
      rethrow;
    }
  }

  /// Clears data belonging to the active engine profile.
  @override
  Future<void> clearBrowsingData() async {
    _requireInitialized();

    try {
      await _bridge.clearProfile(_profileId, privateProfile: _mode.isPrivate);
    } catch (error) {
      healthMonitor.recordError();
      rethrow;
    }
  }

  /// Clears the current private profile session.
  @override
  Future<void> clearPrivateSession() async {
    if (!_initialized || !_mode.isPrivate) {
      return;
    }

    try {
      await _bridge.clearProfile(_profileId, privateProfile: true);
    } catch (error) {
      healthMonitor.recordError();
      rethrow;
    }
  }

  /// Returns the current engine health state.
  EngineHealthSnapshot healthSnapshot() {
    return healthMonitor.snapshot();
  }

  /// Refreshes capabilities reported by the native implementation.
  ///
  /// Missing native capability values do not overwrite the Dart-side
  /// capability contract. This allows the application to remain compatible
  /// with older native builds during migration.
  Future<void> refreshCapabilities() async {
    _requireInitialized();
    await _refreshCapabilities();
  }

  /// Disposes the active native profile.
  @override
  Future<void> dispose() async {
    if (!_initialized) {
      return;
    }

    try {
      await _bridge.disposeProfile(_profileId);
    } catch (error) {
      healthMonitor.recordError();
      rethrow;
    } finally {
      _initialized = false;
      _profileId = 'default';
      _mode = EngineProfileMode.normal;
    }
  }

  Future<void> _refreshCapabilities() async {
    try {
      final Map<String, Object?> native = await _bridge.getCapabilities();

      if (native.isEmpty) {
        return;
      }

      _capabilities = _mergeCapabilities(
        current: _capabilities,
        native: native,
      );
    } on MissingPluginException {
      // Older native builds may not expose getCapabilities yet.
      // Keep the safe Dart-side capability contract.
    } on PlatformException {
      // Capability reporting must not make an otherwise valid engine fail
      // during migration between native engine implementations.
    } catch (_) {
      // Same compatibility rule: capability discovery is supplementary.
    }
  }

  EngineCapabilities _mergeCapabilities({
    required EngineCapabilities current,
    required Map<String, Object?> native,
  }) {
    bool value(String key, bool fallback) {
      final Object? raw = native[key];

      if (raw is bool) {
        return raw;
      }

      return fallback;
    }

    String text(String key, String fallback) {
      final Object? raw = native[key];

      if (raw == null) {
        return fallback;
      }

      final String normalized = raw.toString().trim();

      return normalized.isEmpty ? fallback : normalized;
    }

    return EngineCapabilities(
      engineName: text('engineName', current.engineName),
      engineVersion: text('engineVersion', current.engineVersion),
      supportsJavaScript: value(
        'supportsJavaScript',
        current.supportsJavaScript,
      ),
      supportsDownloads: value('supportsDownloads', current.supportsDownloads),
      supportsFileUpload: value(
        'supportsFileUpload',
        current.supportsFileUpload,
      ),
      supportsPrivateHistoryIsolation: value(
        'supportsPrivateHistoryIsolation',
        current.supportsPrivateHistoryIsolation,
      ),
      supportsPerProfileCookies: value(
        'supportsPerProfileCookies',
        current.supportsPerProfileCookies,
      ),
      supportsPerProfileCache: value(
        'supportsPerProfileCache',
        current.supportsPerProfileCache,
      ),
      supportsPerProfileLocalStorage: value(
        'supportsPerProfileLocalStorage',
        current.supportsPerProfileLocalStorage,
      ),
      supportsNetworkInterception: value(
        'supportsNetworkInterception',
        current.supportsNetworkInterception,
      ),
      supportsContentBlocking: value(
        'supportsContentBlocking',
        current.supportsContentBlocking,
      ),
    );
  }

  void _requireInitialized() {
    if (!_initialized) {
      throw StateError('Native browser engine is not initialized.');
    }
  }
}
