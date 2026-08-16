import 'package:flutter/services.dart';

class PictureInPictureService {
  const PictureInPictureService();

  static const MethodChannel _channel =
      MethodChannel('optimistic_browser/picture_in_picture');

  Future<bool> isSupported() async {
    final value = await _channel.invokeMethod<bool>('isSupported');
    return value ?? false;
  }

  Future<bool> enter({
    required double aspectRatio,
  }) async {
    final value = await _channel.invokeMethod<bool>('enter', {
      'aspectRatio': aspectRatio.clamp(0.5, 2.5),
    });
    return value ?? false;
  }

  Future<void> exit() async {
    await _channel.invokeMethod<void>('exit');
  }

  Future<void> setActions(List<String> actions) async {
    await _channel.invokeMethod<void>('setActions', {
      'actions': actions,
    });
  }
}
