import 'package:flutter/services.dart';

class BrowserPlatformService {
  const BrowserPlatformService();

  static const MethodChannel _channel =
      MethodChannel('optimistic_browser/platform');

  Future<void> configureEngine({
    required String profileId,
    required bool privateMode,
    required bool contentBlocking,
  }) async {
    await _channel.invokeMethod<void>('configureEngine', {
      'profileId': profileId,
      'privateMode': privateMode,
      'contentBlocking': contentBlocking,
    });
  }

  Future<void> setDesktopMode(bool enabled) async {
    await _channel.invokeMethod<void>('setDesktopMode', {
      'enabled': enabled,
    });
  }

  Future<void> clearProfile({
    required String profileId,
    required bool privateMode,
  }) async {
    await _channel.invokeMethod<void>('clearProfile', {
      'profileId': profileId,
      'privateMode': privateMode,
    });
  }

  Future<void> enableStrictCertificateMode(bool enabled) async {
    await _channel.invokeMethod<void>('strictCertificateMode', {
      'enabled': enabled,
    });
  }
}
