class CertificatePinStore {
  final Map<String, Set<String>> _pins = {};

  void addPin(String host, String sha256) {
    final value = _normalize(sha256);
    if (value.length < 32) {
      throw ArgumentError('Certificate fingerprint is too short.');
    }
    _pins.putIfAbsent(host.toLowerCase(), () => {}).add(value);
  }

  void removePin(String host, String sha256) {
    final set = _pins[host.toLowerCase()];
    if (set == null) return;
    set.remove(_normalize(sha256));
    if (set.isEmpty) _pins.remove(host.toLowerCase());
  }

  bool hasPins(String host) => _pins.containsKey(host.toLowerCase());

  bool matches(String host, String sha256) {
    final set = _pins[host.toLowerCase()];
    if (set == null) return true;
    return set.contains(_normalize(sha256));
  }

  Set<String> pinsFor(String host) =>
      Set.unmodifiable(_pins[host.toLowerCase()] ?? const <String>{});

  Map<String, List<String>> export() => {
        for (final e in _pins.entries) e.key: e.value.toList(),
      };

  String _normalize(String value) =>
      value.replaceAll(':', '').replaceAll(' ', '').toLowerCase();
}
