import '../engine/native_engine.dart';
import '../engine/browser_engine.dart';
import '../engine/engine_health_monitor.dart';

import '../../services/privacy/incognito_profile_service.dart';
import '../../services/privacy/storage_partition_service.dart';
import '../../services/privacy/cookie_policy_service.dart';
import '../../services/privacy/cache_partition_service.dart';
import '../../services/privacy/ad_tracker_blocker.dart';

import '../../services/downloads/download_manager.dart';

import '../../services/permissions/permission_manager.dart';
import '../../services/permissions/permission_policy.dart';

import '../../services/security/certificate_security_service.dart';
import '../../services/security/certificate_pin_store.dart';

import '../../services/reader/reader_mode_service.dart';
import '../../services/translation/page_translation_service.dart';
import '../../services/translation/translation_chunker.dart';

import '../../services/media/picture_in_picture_service.dart';
import '../../services/media/pip_state_service.dart';

import '../../services/tabs/advanced_tab_group_service.dart';
import '../../services/tabs/tab_session_service.dart';

import '../../services/recovery/crash_recovery_service.dart';
import '../../services/release/production_release_checker.dart';

class V8ApplicationKernel {
  V8ApplicationKernel({
    NativeBrowserEngine? engine,
    IncognitoProfileService? profiles,
    StoragePartitionService? partitions,
    DownloadManager? downloads,
  }) : engine = engine ?? NativeBrowserEngine(),
       profiles = profiles ?? IncognitoProfileService(),
       partitions = partitions ?? StoragePartitionService(),
       downloads = downloads ?? DownloadManager();

  // ---------------------------------------------------------------------------
  // Core
  // ---------------------------------------------------------------------------

  final NativeBrowserEngine engine;
  final IncognitoProfileService profiles;
  final StoragePartitionService partitions;
  final DownloadManager downloads;

  // ---------------------------------------------------------------------------
  // Privacy
  // ---------------------------------------------------------------------------

  final CookiePolicyService cookies = CookiePolicyService();
  final CachePartitionService cache = CachePartitionService();
  final AdTrackerBlocker blocker = AdTrackerBlocker();

  // ---------------------------------------------------------------------------
  // Permissions
  // ---------------------------------------------------------------------------

  final PermissionManager permissions = PermissionManager();
  final PermissionPolicy permissionPolicy = PermissionPolicy();

  // ---------------------------------------------------------------------------
  // Security
  // ---------------------------------------------------------------------------

  final CertificateSecurityService certificates =
      const CertificateSecurityService();

  final CertificatePinStore pins = CertificatePinStore();

  // ---------------------------------------------------------------------------
  // Browser features
  // ---------------------------------------------------------------------------

  final ReaderModeService reader = ReaderModeService();
  final PageTranslationService translation = PageTranslationService();
  final TranslationChunker translationChunks = TranslationChunker();

  final PictureInPictureService pip = PictureInPictureService();
  final PipStateService pipState = PipStateService();

  // ---------------------------------------------------------------------------
  // Tabs / sessions
  // ---------------------------------------------------------------------------

  final AdvancedTabGroupService tabGroups = AdvancedTabGroupService();
  final TabSessionService tabSessions = TabSessionService();

  // ---------------------------------------------------------------------------
  // Recovery / release
  // ---------------------------------------------------------------------------

  final CrashRecoveryService recovery = CrashRecoveryService();
  final ProductionReleaseChecker releaseChecker = ProductionReleaseChecker();

  final EngineHealthMonitor health = EngineHealthMonitor();

  // ---------------------------------------------------------------------------
  // Kernel state
  // ---------------------------------------------------------------------------

  bool _ready = false;

  String? _normalProfileId;
  String? _activeProfileId;

  bool get ready => _ready;

  String? get normalProfileId => _normalProfileId;

  String? get activeProfileId => _activeProfileId;

  bool get activeProfileIsPrivate {
    final id = _activeProfileId;
    if (id == null) {
      return false;
    }

    final profile = profiles.get(id);
    return profile?.isPrivate ?? false;
  }

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  Future<void> initialize() async {
    if (_ready) {
      return;
    }

    await recovery.start();

    await engine.initialize();

    final profile = profiles.create(privateMode: false);

    await engine.createProfile(
      profileId: profile.id,
      mode: EngineProfileMode.normal,
    );

    partitions.open(profileId: profile.id, privateMode: false);

    _normalProfileId = profile.id;
    _activeProfileId = profile.id;
    _ready = true;
  }

  // ---------------------------------------------------------------------------
  // Private window
  // ---------------------------------------------------------------------------

  Future<String> createPrivateWindow() async {
    _requireReady();

    final profile = profiles.create(privateMode: true);

    partitions.open(profileId: profile.id, privateMode: true);

    await engine.createProfile(
      profileId: profile.id,
      mode: EngineProfileMode.private,
    );

    _activeProfileId = profile.id;

    return profile.id;
  }

  // ---------------------------------------------------------------------------
  // Profile switching
  // ---------------------------------------------------------------------------

  Future<bool> activateProfile(String profileId) async {
    _requireReady();

    final profile = profiles.get(profileId);

    if (profile == null) {
      return false;
    }

    final existingPartition = partitions.partitionFor(profileId);

    if (existingPartition == null) {
      partitions.open(profileId: profile.id, privateMode: profile.isPrivate);
    }

    await engine.createProfile(
      profileId: profile.id,
      mode: profile.isPrivate
          ? EngineProfileMode.private
          : EngineProfileMode.normal,
    );

    _activeProfileId = profile.id;

    return true;
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  Future<bool> open(Uri uri) async {
    _requireReady();

    final started = DateTime.now();

    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return false;
    }

    if (!certificates.allow(uri)) {
      return false;
    }

    if (blocker.shouldBlock(uri)) {
      return false;
    }

    final target = uri.scheme == 'http' ? uri.replace(scheme: 'https') : uri;

    if (!engine.canNavigate(target)) {
      return false;
    }

    try {
      await engine.navigate(target);

      health.recordNavigation(DateTime.now().difference(started));

      return true;
    } catch (_) {
      health.recordError();
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Cookies
  // ---------------------------------------------------------------------------

  bool allowCookie({required Uri firstParty, required Uri origin}) {
    return cookies.allowSetCookie(firstParty: firstParty, cookieOrigin: origin);
  }

  void storeCookie(String profileId, BrowserCookie cookie) {
    cookies.store(profileId, cookie);
  }

  List<BrowserCookie> cookiesFor(String profileId, Uri uri) {
    return cookies.cookiesFor(profileId, uri);
  }

  // ---------------------------------------------------------------------------
  // Cache
  // ---------------------------------------------------------------------------

  void cacheResponse({
    required String profileId,
    required String key,
    required int bytes,
  }) {
    if (bytes < 0) {
      throw ArgumentError.value(
        bytes,
        'bytes',
        'Cache size cannot be negative.',
      );
    }

    cache.put(profileId: profileId, key: key, bytes: bytes);
  }

  bool hasCached(String profileId, String key) {
    return cache.contains(profileId, key);
  }

  // ---------------------------------------------------------------------------
  // Storage partitions
  // ---------------------------------------------------------------------------

  StoragePartition? partitionFor(String profileId) {
    return partitions.partitionFor(profileId);
  }

  bool profilesAreIsolated(String firstProfile, String secondProfile) {
    return partitions.isIsolated(firstProfile, secondProfile);
  }

  // ---------------------------------------------------------------------------
  // Certificate pinning
  // ---------------------------------------------------------------------------

  bool certificateMatches(String host, String fingerprint) {
    return pins.matches(host, fingerprint);
  }

  void pinCertificate(String host, String fingerprint) {
    pins.addPin(host, fingerprint);
  }

  // ---------------------------------------------------------------------------
  // Private profile cleanup
  // ---------------------------------------------------------------------------

  Future<void> clearPrivateProfile(String profileId) async {
    final profile = profiles.get(profileId);

    if (profile == null || !profile.isPrivate) {
      return;
    }

    cookies.clear(profileId);
    cache.clearProfile(profileId);

    await partitions.close(profileId);

    profiles.close(profileId);

    if (_activeProfileId == profileId) {
      final normalId = _normalProfileId;

      if (normalId != null) {
        await activateProfile(normalId);
      } else {
        _activeProfileId = null;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Clear every private profile
  // ---------------------------------------------------------------------------

  Future<void> clearAllPrivateProfiles() async {
    final privateIds = profiles.privateProfiles
        .map((profile) => profile.id)
        .toList(growable: false);

    for (final profileId in privateIds) {
      cookies.clear(profileId);
      cache.clearProfile(profileId);

      await partitions.close(profileId);

      profiles.close(profileId);
    }

    final normalId = _normalProfileId;

    if (normalId != null) {
      await activateProfile(normalId);
    } else {
      _activeProfileId = null;
    }
  }

  // ---------------------------------------------------------------------------
  // Health
  // ---------------------------------------------------------------------------

  void recordEngineError() {
    health.recordError();
  }

  EngineHealthSnapshot engineHealth() {
    return health.snapshot();
  }

  // ---------------------------------------------------------------------------
  // Diagnostics
  // ---------------------------------------------------------------------------

  Map<String, Object?> diagnostics() {
    return <String, Object?>{
      'ready': _ready,
      'activeProfileId': _activeProfileId,
      'normalProfileId': _normalProfileId,
      'activeProfileIsPrivate': activeProfileIsPrivate,
      'profileCount': profiles.activeProfiles.length,
      'privateProfileCount': profiles.privateProfiles.length,
      'engineInitialized': engine.initialized,
      'engineProfileId': engine.profileId,
      'engineMode': engine.mode.name,
      'blockedCount': blocker.blockedCount,
      'healthErrorCount': health.snapshot().errorCount,
    };
  }

  // ---------------------------------------------------------------------------
  // Production check
  // ---------------------------------------------------------------------------

  Future<ProductionReleaseReport> productionCheck({
    required String version,
    required bool debugMode,
    required bool signingConfigured,
    required bool testsPresent,
    required bool privacyPolicyPresent,
  }) {
    return releaseChecker.run(
      version: version,
      debugMode: debugMode,
      hasSigningConfig: signingConfigured,
      hasTests: testsPresent,
      hasPrivacyPolicy: privacyPolicyPresent,
    );
  }

  // ---------------------------------------------------------------------------
  // Shutdown
  // ---------------------------------------------------------------------------

  Future<void> shutdown() async {
    if (!_ready) {
      return;
    }

    final privateIds = profiles.privateProfiles
        .map((profile) => profile.id)
        .toList(growable: false);

    for (final profileId in privateIds) {
      cookies.clear(profileId);
      cache.clearProfile(profileId);
      await partitions.close(profileId);
      profiles.close(profileId);
    }

    await recovery.markCleanShutdown();

    await engine.dispose();

    await downloads.dispose();

    recovery.dispose();

    _activeProfileId = null;
    _normalProfileId = null;
    _ready = false;
  }

  // ---------------------------------------------------------------------------
  // Internal guard
  // ---------------------------------------------------------------------------

  void _requireReady() {
    if (!_ready) {
      throw StateError('V8 application kernel is not initialized.');
    }
  }
}
