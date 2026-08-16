import 'dart:math';

enum PrivacyProfileKind { normal, private }
class PrivacyProfile {
  const PrivacyProfile({required this.id, required this.kind, required this.createdAt});
  final String id; final PrivacyProfileKind kind; final DateTime createdAt;
  bool get isPrivate => kind == PrivacyProfileKind.private;
}

/// Flutter-side identity/lifecycle registry. Native Android/iOS bridges own the
/// actual storage partition. Private tabs are never restored to disk.
class IncognitoProfileService {
  final Map<String, PrivacyProfile> _profiles = <String, PrivacyProfile>{};
  final Random _random = Random.secure();
  PrivacyProfile create({required bool privateMode}) {
    final kind = privateMode ? PrivacyProfileKind.private : PrivacyProfileKind.normal;
    final prefix = privateMode ? 'private' : 'normal';
    final id = '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(999999)}';
    final profile = PrivacyProfile(id: id, kind: kind, createdAt: DateTime.now());
    _profiles[id] = profile; return profile;
  }
  PrivacyProfile? get(String id) => _profiles[id];
  List<PrivacyProfile> get activeProfiles => List.unmodifiable(_profiles.values);
  List<PrivacyProfile> get privateProfiles => _profiles.values.where((e) => e.isPrivate).toList(growable: false);
  bool contains(String id) => _profiles.containsKey(id);
  void close(String id) => _profiles.remove(id);
  void closePrivateProfiles() { for (final id in privateProfiles.map((e) => e.id).toList()) { _profiles.remove(id); } }
  Map<String, Object?> snapshot() => {'profileCount': _profiles.length, 'privateCount': privateProfiles.length, 'privatePersistence': false};
}
