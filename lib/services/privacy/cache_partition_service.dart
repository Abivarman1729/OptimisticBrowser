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
  final Map<String, Map<String, CacheEntry>> _partitions = {};

  void put({required String profileId, required String key, required int bytes}) {
    final bucket = _partitions.putIfAbsent(profileId, () => {});
    bucket[key] = CacheEntry(
      key: key,
      profileId: profileId,
      createdAt: DateTime.now(),
      bytes: bytes,
    );
  }

  CacheEntry? get(String profileId, String key) => _partitions[profileId]?[key];
  bool contains(String profileId, String key) =>
      _partitions[profileId]?.containsKey(key) ?? false;
  void remove(String profileId, String key) => _partitions[profileId]?.remove(key);
  void clearProfile(String profileId) => _partitions.remove(profileId);
  void clearAll() => _partitions.clear();

  int bytesFor(String profileId) =>
      _partitions[profileId]?.values.fold<int>(0, (sum, e) => sum + e.bytes) ?? 0;

  int entriesFor(String profileId) => _partitions[profileId]?.length ?? 0;
}
