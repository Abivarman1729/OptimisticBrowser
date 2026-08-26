class CacheEntry {
  const CacheEntry({
    required this.key,
    required this.profileId,
    required this.createdAt,
    required this.bytes,
  });

  final String key;
  final String profileId;
  final DateTime createdAt;
  final int bytes;
}

class CachePartitionService {
  final Map<String, Map<String, CacheEntry>> _partitions =
      <String, Map<String, CacheEntry>>{};

  void put({
    required String profileId,
    required String key,
    required int bytes,
  }) {
    final String normalizedProfileId = profileId.trim();
    final String normalizedKey = key.trim();

    if (normalizedProfileId.isEmpty) {
      throw ArgumentError.value(
        profileId,
        'profileId',
        'Profile ID must not be empty.',
      );
    }

    if (normalizedKey.isEmpty) {
      throw ArgumentError.value(key, 'key', 'Cache key must not be empty.');
    }

    if (bytes < 0) {
      throw ArgumentError.value(
        bytes,
        'bytes',
        'Cache size must not be negative.',
      );
    }

    final Map<String, CacheEntry> bucket = _partitions.putIfAbsent(
      normalizedProfileId,
      () => <String, CacheEntry>{},
    );

    bucket[normalizedKey] = CacheEntry(
      key: normalizedKey,
      profileId: normalizedProfileId,
      createdAt: DateTime.now(),
      bytes: bytes,
    );
  }

  CacheEntry? get(String profileId, String key) {
    return _partitions[profileId.trim()]?[key.trim()];
  }

  bool contains(String profileId, String key) {
    return _partitions[profileId.trim()]?.containsKey(key.trim()) ?? false;
  }

  void remove(String profileId, String key) {
    final Map<String, CacheEntry>? bucket = _partitions[profileId.trim()];

    bucket?.remove(key.trim());

    if (bucket != null && bucket.isEmpty) {
      _partitions.remove(profileId.trim());
    }
  }

  void clearProfile(String profileId) {
    _partitions.remove(profileId.trim());
  }

  void clearAll() {
    _partitions.clear();
  }

  int bytesFor(String profileId) {
    final Map<String, CacheEntry>? bucket = _partitions[profileId.trim()];

    if (bucket == null || bucket.isEmpty) {
      return 0;
    }

    return bucket.values.fold<int>(
      0,
      (int total, CacheEntry entry) => total + entry.bytes,
    );
  }

  int entriesFor(String profileId) {
    return _partitions[profileId.trim()]?.length ?? 0;
  }

  Set<String> keysFor(String profileId) {
    final Map<String, CacheEntry>? bucket = _partitions[profileId.trim()];

    if (bucket == null) {
      return const <String>{};
    }

    return Set<String>.unmodifiable(bucket.keys);
  }

  bool isIsolated(String firstProfile, String secondProfile) {
    final String first = firstProfile.trim();
    final String second = secondProfile.trim();

    if (first.isEmpty || second.isEmpty) {
      return false;
    }

    if (first == second) {
      return false;
    }

    final bool firstExists = _partitions.containsKey(first);

    final bool secondExists = _partitions.containsKey(second);

    return firstExists && secondExists;
  }

  List<CacheEntry> snapshot(String profileId) {
    final Map<String, CacheEntry>? bucket = _partitions[profileId.trim()];

    if (bucket == null) {
      return const <CacheEntry>[];
    }

    return List<CacheEntry>.unmodifiable(bucket.values);
  }

  int profileCount() {
    return _partitions.length;
  }
}
