import 'dart:async';

import 'browser_engine.dart';
import 'engine_capabilities.dart';
import 'native_engine_bridge.dart';

/// Production-oriented engine facade.
///
/// The Flutter UI talks to this interface instead of depending directly on
/// a platform WebView. Rendering remains platform-specific, while profile
/// state, policy, content blocking, downloads and lifecycle are centralized.
class NativeBrowserEngine implements BrowserEngine {
  NativeBrowserEngine({NativeEngineBridge? bridge})
      : _bridge = bridge ?? const NativeEngineBridge();

  final NativeEngineBridge _bridge;
  bool _initialized = false;
  String _profileId = 'default';
  EngineProfileMode _mode = EngineProfileMode.normal;

  @override
  EngineCapabilities get capabilities => const EngineCapabilities(
        engineName: 'Optimistic Chromium/WebView Engine Bridge',
        engineVersion: '9.0-stage2',
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

  bool get initialized => _initialized;
  String get profileId => _profileId;
  EngineProfileMode get mode => _mode;

  Future<void> createProfile({
    required String profileId,
    required EngineProfileMode mode,
  }) async {
    _profileId = profileId;
    _mode = mode;
    await _bridge.createProfile(profileId, privateProfile: mode.isPrivate);
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    await _bridge.initialize();
    await _bridge.createProfile(_profileId, privateProfile: _mode.isPrivate);
    _initialized = true;
  }

  @override
  bool canNavigate(Uri uri) {
    return uri.scheme == 'https' || uri.scheme == 'http';
  }

  Future<void> navigate(Uri uri) async {
    if (!canNavigate(uri)) {
      throw ArgumentError('Unsupported navigation scheme: ${uri.scheme}');
    }
    await _bridge.navigate(uri.toString(), profileId: _profileId);
  }

  Future<void> setUserAgent(String value) =>
      _bridge.setUserAgent(value, profileId: _profileId);

  Future<void> setBlockedHosts(Iterable<String> hosts) =>
      _bridge.setBlockedHosts(hosts, profileId: _profileId);

  Future<void> clearBrowsingData() =>
      _bridge.clearProfile(_profileId, privateProfile: _mode.isPrivate);

  @override
  Future<void> clearPrivateSession() async {
    if (_mode.isPrivate) {
      await _bridge.clearProfile(_profileId, privateProfile: true);
    }
  }

  @override
  Future<void> dispose() async {
    if (!_initialized) return;
    await _bridge.disposeProfile(_profileId);
    _initialized = false;
  }
}

enum EngineProfileMode {
  normal,
  private;

  bool get isPrivate => this == EngineProfileMode.private;
}
