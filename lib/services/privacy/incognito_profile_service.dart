import 'dart:math';

enum PrivacyProfileKind { normal, private }

class PrivacyProfile {
  const PrivacyProfile({
    required this.id,
    required this.kind,
    required this.createdAt,
  });

  final String id;
  final PrivacyProfileKind kind;
  final DateTime createdAt;

  bool get isPrivate => kind == PrivacyProfileKind.private;

  bool get isNormal => kind == PrivacyProfileKind.normal;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'kind': kind.name,
      'createdAt': createdAt.toIso8601String(),
      'isPrivate': isPrivate,
    };
  }
}

/// Flutter-side profile identity and lifecycle registry.
///
/// Native Android/iOS storage engines own the real persistent
/// storage implementation. This service owns only the Flutter-side
/// profile identity and lifecycle state.
///
/// Private profiles must never be persisted as restorable sessions.
class IncognitoProfileService {
  IncognitoProfileService({Random? random})
    : _random = random ?? Random.secure();

  final Map<String, PrivacyProfile> _profiles = <String, PrivacyProfile>{};

  final Random _random;

  PrivacyProfile create({required bool privateMode}) {
    final PrivacyProfileKind kind = privateMode
        ? PrivacyProfileKind.private
        : PrivacyProfileKind.normal;

    final String prefix = privateMode ? 'private' : 'normal';

    final DateTime now = DateTime.now();

    String id;

    do {
      id =
          '$prefix-'
          '${now.microsecondsSinceEpoch}-'
          '${_random.nextInt(1000000)}';
    } while (_profiles.containsKey(id));

    final PrivacyProfile profile = PrivacyProfile(
      id: id,
      kind: kind,
      createdAt: now,
    );

    _profiles[id] = profile;

    return profile;
  }

  PrivacyProfile? get(String id) {
    return _profiles[id.trim()];
  }

  bool contains(String id) {
    return _profiles.containsKey(id.trim());
  }

  List<PrivacyProfile> get activeProfiles {
    return List<PrivacyProfile>.unmodifiable(_profiles.values);
  }

  List<PrivacyProfile> get privateProfiles {
    return List<PrivacyProfile>.unmodifiable(
      _profiles.values.where((PrivacyProfile profile) => profile.isPrivate),
    );
  }

  List<PrivacyProfile> get normalProfiles {
    return List<PrivacyProfile>.unmodifiable(
      _profiles.values.where((PrivacyProfile profile) => profile.isNormal),
    );
  }

  int get profileCount => _profiles.length;

  int get privateProfileCount => privateProfiles.length;

  int get normalProfileCount => normalProfiles.length;

  void close(String id) {
    _profiles.remove(id.trim());
  }

  void closePrivateProfile(String id) {
    final PrivacyProfile? profile = _profiles[id.trim()];

    if (profile == null || !profile.isPrivate) {
      return;
    }

    _profiles.remove(profile.id);
  }

  void closePrivateProfiles() {
    final List<String> ids = privateProfiles
        .map((PrivacyProfile profile) => profile.id)
        .toList(growable: false);

    for (final String id in ids) {
      _profiles.remove(id);
    }
  }

  bool isPrivate(String id) {
    return _profiles[id.trim()]?.isPrivate ?? false;
  }

  bool isNormal(String id) {
    return _profiles[id.trim()]?.isNormal ?? false;
  }

  Map<String, Object?> snapshot() {
    return <String, Object?>{
      'profileCount': profileCount,
      'privateCount': privateProfileCount,
      'normalCount': normalProfileCount,
      'privatePersistence': false,
    };
  }
}
