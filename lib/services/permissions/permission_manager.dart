import 'dart:async';

import 'package:flutter/services.dart';

enum BrowserPermission {
  camera,
  microphone,
  location,
  notifications,
  clipboard,
  downloads,
  autoplay,
}

enum PermissionState { unknown, granted, denied, restricted }

class PermissionDecision {
  const PermissionDecision(this.permission, this.state);

  final BrowserPermission permission;
  final PermissionState state;
}

class PermissionManager {
  PermissionManager();

  static const MethodChannel _channel =
      MethodChannel('optimistic_browser/permissions');

  final Map<BrowserPermission, PermissionState> _cache = {};

  Future<PermissionState> request(BrowserPermission permission) async {
    final result = await _channel.invokeMethod<String>('request', {
      'permission': permission.name,
    });
    final state = _parse(result);
    _cache[permission] = state;
    return state;
  }

  Future<PermissionState> check(BrowserPermission permission) async {
    final cached = _cache[permission];
    if (cached != null) return cached;
    final result = await _channel.invokeMethod<String>('check', {
      'permission': permission.name,
    });
    final state = _parse(result);
    _cache[permission] = state;
    return state;
  }

  Future<void> revoke(BrowserPermission permission) async {
    await _channel.invokeMethod<void>('revoke', {
      'permission': permission.name,
    });
    _cache.remove(permission);
  }

  List<PermissionDecision> snapshot() => BrowserPermission.values
      .map((p) => PermissionDecision(
            p,
            _cache[p] ?? PermissionState.unknown,
          ))
      .toList(growable: false);

  PermissionState _parse(String? value) {
    return PermissionState.values.firstWhere(
      (state) => state.name == value,
      orElse: () => PermissionState.unknown,
    );
  }
}
