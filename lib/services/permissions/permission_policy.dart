import 'permission_manager.dart';

class PermissionPolicy {
  PermissionPolicy({
    Map<BrowserPermission, PermissionState>? defaults,
  }) : _defaults = {
          for (final p in BrowserPermission.values)
            p: PermissionState.denied,
          ...?defaults,
        };

  final Map<BrowserPermission, PermissionState> _defaults;
  final Map<String, Map<BrowserPermission, PermissionState>> _sites = {};

  void setSiteRule(
    String host,
    BrowserPermission permission,
    PermissionState state,
  ) {
    _sites.putIfAbsent(host.toLowerCase(), () => {})[permission] = state;
  }

  void clearSite(String host) => _sites.remove(host.toLowerCase());

  PermissionState decide(Uri uri, BrowserPermission permission) =>
      _sites[uri.host.toLowerCase()]?[permission] ??
      _defaults[permission] ??
      PermissionState.unknown;

  bool canAutoGrant(Uri uri, BrowserPermission permission) =>
      decide(uri, permission) == PermissionState.granted;

  Map<String, Object?> export() => {
        'defaults': {
          for (final e in _defaults.entries) e.key.name: e.value.name,
        },
        'sites': {
          for (final e in _sites.entries)
            e.key: {
              for (final p in e.value.entries) p.key.name: p.value.name,
            },
        },
      };
}
