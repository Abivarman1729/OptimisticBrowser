import 'package:flutter/services.dart';

/// Native MethodChannel bridge used by the browser engine.
///
/// The Dart side owns the contract. Android/iOS implementations provide the
/// actual rendering engine and profile storage backend.
class NativeEngineBridge {
  const NativeEngineBridge();

  static const String channelName = 'optimistic_browser/native_engine';

  static const MethodChannel _channel = MethodChannel(channelName);

  /// Initializes the native engine subsystem.
  Future<void> initialize() async {
    await _channel.invokeMethod<void>('initialize');
  }

  /// Creates a native engine profile.
  Future<void> createProfile(
    String profileId, {
    required bool privateProfile,
  }) async {
    _validateProfileId(profileId);

    await _channel.invokeMethod<void>('createProfile', <String, Object?>{
      'profileId': profileId,
      'privateProfile': privateProfile,
    });
  }

  /// Navigates a profile to [url].
  Future<void> navigate(String url, {required String profileId}) async {
    _validateProfileId(profileId);

    if (url.trim().isEmpty) {
      throw ArgumentError.value(url, 'url', 'Navigation URL cannot be empty.');
    }

    await _channel.invokeMethod<void>('navigate', <String, Object?>{
      'url': url,
      'profileId': profileId,
    });
  }

  /// Changes the user agent for a profile.
  Future<void> setUserAgent(String value, {required String profileId}) async {
    _validateProfileId(profileId);

    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, 'value', 'User agent cannot be empty.');
    }

    await _channel.invokeMethod<void>('setUserAgent', <String, Object?>{
      'value': value,
      'profileId': profileId,
    });
  }

  /// Replaces the blocked-host list for a profile.
  Future<void> setBlockedHosts(
    Iterable<String> hosts, {
    required String profileId,
  }) async {
    _validateProfileId(profileId);

    final List<String> normalizedHosts = hosts
        .map((String host) => host.trim().toLowerCase())
        .where((String host) => host.isNotEmpty)
        .toSet()
        .toList(growable: false);

    await _channel.invokeMethod<void>('setBlockedHosts', <String, Object?>{
      'profileId': profileId,
      'hosts': normalizedHosts,
    });
  }

  /// Clears all browser data belonging to a profile.
  Future<void> clearProfile(
    String profileId, {
    required bool privateProfile,
  }) async {
    _validateProfileId(profileId);

    await _channel.invokeMethod<void>('clearProfile', <String, Object?>{
      'profileId': profileId,
      'privateProfile': privateProfile,
    });
  }

  /// Releases the native resources associated with a profile.
  Future<void> disposeProfile(String profileId) async {
    _validateProfileId(profileId);

    await _channel.invokeMethod<void>('disposeProfile', <String, Object?>{
      'profileId': profileId,
    });
  }

  /// Retrieves native engine capabilities.
  Future<Map<String, Object?>> getCapabilities() async {
    final Map<Object?, Object?>? result = await _channel
        .invokeMethod<Map<Object?, Object?>>('getCapabilities');

    if (result == null || result.isEmpty) {
      return <String, Object?>{};
    }

    return _stringKeyedMap(result);
  }

  /// Retrieves diagnostic information about the native engine.
  Future<NativeEngineInfo> getEngineInfo() async {
    final Map<Object?, Object?>? result = await _channel
        .invokeMethod<Map<Object?, Object?>>('getEngineInfo');

    return NativeEngineInfo.fromMap(result ?? const <Object?, Object?>{});
  }

  /// Sends a generic lifecycle command to the native engine.
  ///
  /// This is intentionally limited to lifecycle use. Navigation and profile
  /// operations should continue using their typed methods above.
  Future<void> shutdown() async {
    await _channel.invokeMethod<void>('shutdown');
  }

  static Map<String, Object?> _stringKeyedMap(Map<Object?, Object?> source) {
    final Map<String, Object?> output = <String, Object?>{};

    for (final MapEntry<Object?, Object?> entry in source.entries) {
      final Object? key = entry.key;

      if (key is String) {
        output[key] = entry.value;
      }
    }

    return output;
  }

  static void _validateProfileId(String profileId) {
    if (profileId.trim().isEmpty) {
      throw ArgumentError.value(
        profileId,
        'profileId',
        'Profile ID cannot be empty.',
      );
    }
  }
}

/// Information reported by the native engine implementation.
class NativeEngineInfo {
  const NativeEngineInfo({
    required this.platform,
    required this.engine,
    required this.version,
    required this.profileBackend,
  });

  final String platform;
  final String engine;
  final String version;
  final String profileBackend;

  factory NativeEngineInfo.fromMap(Map<Object?, Object?> map) {
    return NativeEngineInfo(
      platform: _readString(map, 'platform'),
      engine: _readString(map, 'engine'),
      version: _readString(map, 'version'),
      profileBackend: _readString(map, 'profileBackend'),
    );
  }

  Map<String, String> toJson() {
    return <String, String>{
      'platform': platform,
      'engine': engine,
      'version': version,
      'profileBackend': profileBackend,
    };
  }

  @override
  String toString() {
    return 'NativeEngineInfo('
        'platform: $platform, '
        'engine: $engine, '
        'version: $version, '
        'profileBackend: $profileBackend'
        ')';
  }

  static String _readString(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];

    if (value == null) {
      return 'unknown';
    }

    final String text = value.toString().trim();

    return text.isEmpty ? 'unknown' : text;
  }
}
