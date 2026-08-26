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

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'profileId': profileId,
      'privateMode': privateMode,
      'namespace': namespace,
    };
  }
}

class StoragePartitionService {
  final Map<String, StoragePartition> _partitions =
      <String, StoragePartition>{};

  final Map<String, Map<StorageArea, Set<String>>> _keys =
      <String, Map<StorageArea, Set<String>>>{};

  StoragePartition open({
    required String profileId,
    required bool privateMode,
  }) {
    final String normalizedProfileId = profileId.trim();

    if (normalizedProfileId.isEmpty) {
      throw ArgumentError.value(
        profileId,
        'profileId',
        'Profile ID must not be empty.',
      );
    }

    final String namespacePrefix = privateMode ? 'private' : 'normal';

    final String namespace = '$namespacePrefix:$normalizedProfileId';

    final StoragePartition partition = StoragePartition(
      profileId: normalizedProfileId,
      privateMode: privateMode,
      namespace: namespace,
    );

    _partitions[normalizedProfileId] = partition;

    final Map<StorageArea, Set<String>> bucket = _keys.putIfAbsent(
      normalizedProfileId,
      () => <StorageArea, Set<String>>{},
    );

    for (final StorageArea area in StorageArea.values) {
      bucket.putIfAbsent(area, () => <String>{});
    }

    return partition;
  }

  StoragePartition? partitionFor(String profileId) {
    return _partitions[profileId.trim()];
  }

  bool contains(String profileId) {
    return _partitions.containsKey(profileId.trim());
  }

  void recordKey(String profileId, StorageArea area, String key) {
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
      throw ArgumentError.value(key, 'key', 'Storage key must not be empty.');
    }

    final Map<StorageArea, Set<String>> bucket = _keys.putIfAbsent(
      normalizedProfileId,
      () => <StorageArea, Set<String>>{},
    );

    bucket.putIfAbsent(area, () => <String>{}).add(normalizedKey);
  }

  Set<String> keys(String profileId, StorageArea area) {
    final Set<String>? values = _keys[profileId.trim()]?[area];

    if (values == null) {
      return const <String>{};
    }

    return Set<String>.unmodifiable(values);
  }

  Future<void> clear(String profileId, {Set<StorageArea>? areas}) async {
    final String normalizedProfileId = profileId.trim();

    final Map<StorageArea, Set<String>>? bucket = _keys[normalizedProfileId];

    if (bucket == null) {
      return;
    }

    final Set<StorageArea> targets = areas == null
        ? StorageArea.values.toSet()
        : Set<StorageArea>.from(areas);

    for (final StorageArea area in targets) {
      bucket[area]?.clear();
    }
  }

  Future<void> close(String profileId) async {
    final String normalizedProfileId = profileId.trim();

    if (normalizedProfileId.isEmpty) {
      return;
    }

    await clear(normalizedProfileId);

    _keys.remove(normalizedProfileId);
    _partitions.remove(normalizedProfileId);
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

    final StoragePartition? a = _partitions[first];
    final StoragePartition? b = _partitions[second];

    if (a == null || b == null) {
      return false;
    }

    return a.namespace != b.namespace;
  }

  int partitionCount() {
    return _partitions.length;
  }

  List<StoragePartition> snapshot() {
    return List<StoragePartition>.unmodifiable(_partitions.values);
  }

  Future<void> clearAll() async {
    final List<String> ids = _partitions.keys.toList(growable: false);

    for (final String id in ids) {
      await close(id);
    }
  }
}
