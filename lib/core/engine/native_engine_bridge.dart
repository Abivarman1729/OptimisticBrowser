import 'package:flutter/services.dart';

/// MethodChannel bridge for native engine adapters.
///
/// Android can map this contract to a dedicated profile-aware WebView/Chromium
/// implementation. iOS can map it to WKWebView data stores. A future embedded
/// Rust/Chromium runtime can implement the same commands without changing Dart.
class NativeEngineBridge {
  const NativeEngineBridge();

  static const MethodChannel _channel =
      MethodChannel('optimistic_browser/native_engine');

  Future<void> initialize() async {
    await _channel.invokeMethod<void>('initialize');
  }

  Future<void> createProfile(
    String profileId, {
    required bool privateProfile,
  }) async {
    await _channel.invokeMethod<void>('createProfile', {
      'profileId': profileId,
      'privateProfile': privateProfile,
    });
  }

  Future<void> navigate(
    String url, {
    required String profileId,
  }) async {
    await _channel.invokeMethod<void>('navigate', {
      'url': url,
      'profileId': profileId,
    });
  }

  Future<void> setUserAgent(
    String value, {
    required String profileId,
  }) async {
    await _channel.invokeMethod<void>('setUserAgent', {
      'value': value,
      'profileId': profileId,
    });
  }

  Future<void> clearProfile(
    String profileId, {
    required bool privateProfile,
  }) async {
    await _channel.invokeMethod<void>('clearProfile', {
      'profileId': profileId,
      'privateProfile': privateProfile,
    });
  }

  Future<void> disposeProfile(String profileId) async {
    await _channel.invokeMethod<void>('disposeProfile', {
      'profileId': profileId,
    });
  }

  Future<void> setBlockedHosts(
    Iterable<String> hosts, {
    required String profileId,
  }) async {
    await _channel.invokeMethod<void>('setBlockedHosts', {
      'profileId': profileId,
      'hosts': hosts.toList(growable: false),
    });
  }

  Future<Map<String, Object?>> getCapabilities() async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'getCapabilities',
    );
    return Map<String, Object?>.from(
      (result ?? const <Object?, Object?>{}),
    );
  }
}


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
      platform: '${map['platform'] ?? 'unknown'}',
      engine: '${map['engine'] ?? 'unknown'}',
      version: '${map['version'] ?? 'unknown'}',
      profileBackend: '${map['profileBackend'] ?? 'unknown'}',
    );
  }
}

extension NativeEngineBridgeInfo on NativeEngineBridge {
  Future<NativeEngineInfo> getEngineInfo() async {
    final result = await NativeEngineBridge._channel.invokeMethod<Map<Object?, Object?>>(
      'getEngineInfo',
    );
    return NativeEngineInfo.fromMap(result ?? const {});
  }
}
