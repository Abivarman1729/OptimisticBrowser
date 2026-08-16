import 'dart:async';

enum StorageArea { cookies, cache, localStorage, indexedDb, serviceWorkers }

class StoragePartition {
  const StoragePartition({
    required this.profileId,
    required this.privateMode,
    required this.namespace,
  });

  final String profileId;
  final bool privateMode;
  final String namespace;

  Map<String, Object?> toJson() => {
        'profileId': profileId,
        'privateMode': privateMode,
        'namespace': namespace,
      };
}

class StoragePartitionService {
  final Map<String, StoragePartition> _partitions = {};
  final Map<String, Map<StorageArea, Set<String>>> _keys = {};

  StoragePartition open({
    required String profileId,
    required bool privateMode,
  }) {
    final namespace = privateMode ? 'private:$profileId' : 'normal:$profileId';
    final partition = StoragePartition(
      profileId: profileId,
      privateMode: privateMode,
      namespace: namespace,
    );
    _partitions[profileId] = partition;
    _keys.putIfAbsent(profileId, () => {});
    for (final area in StorageArea.values) {
      _keys[profileId]!.putIfAbsent(area, () => <String>{});
    }
    return partition;
  }

  StoragePartition? partitionFor(String profileId) => _partitions[profileId];

  void recordKey(String profileId, StorageArea area, String key) {
    _keys.putIfAbsent(profileId, () => {});
    _keys[profileId]!.putIfAbsent(area, () => <String>{}).add(key);
  }

  Set<String> keys(String profileId, StorageArea area) =>
      Set.unmodifiable(_keys[profileId]?[area] ?? const <String>{});

  Future<void> clear(
    String profileId, {
    Set<StorageArea>? areas,
  }) async {
    final bucket = _keys[profileId];
    if (bucket == null) return;
    final targets = areas ?? StorageArea.values.toSet();
    for (final area in targets) {
      bucket[area]?.clear();
    }
  }

  Future<void> close(String profileId) async {
    await clear(profileId);
    _keys.remove(profileId);
    _partitions.remove(profileId);
  }

  bool isIsolated(String firstProfile, String secondProfile) {
    final a = _partitions[firstProfile];
    final b = _partitions[secondProfile];
    if (a == null || b == null) return false;
    return a.namespace != b.namespace;
  }
}
