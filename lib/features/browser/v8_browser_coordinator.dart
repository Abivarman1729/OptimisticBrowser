import 'dart:async';

import '../../core/engine/browser_engine.dart';
import '../../core/engine/native_engine.dart';
import '../../core/features/v8_feature_registry.dart';
import '../../services/downloads/download_manager.dart';
import '../../services/privacy/ad_tracker_blocker.dart';
import '../../services/privacy/incognito_profile_service.dart';
import '../../services/privacy/storage_partition_service.dart';
import '../../services/recovery/crash_recovery_service.dart';
import '../../services/security/network_request_policy.dart';

class V8BrowserCoordinator {
  V8BrowserCoordinator({
    NativeBrowserEngine? engine,
    IncognitoProfileService? profiles,
    StoragePartitionService? partitions,
    DownloadManager? downloads,
    AdTrackerBlocker? blocker,
    CrashRecoveryService? recovery,
  }) : engine = engine ?? NativeBrowserEngine(),
       profiles = profiles ?? IncognitoProfileService(),
       partitions = partitions ?? StoragePartitionService(),
       downloads = downloads ?? DownloadManager(),
       blocker = blocker ?? AdTrackerBlocker(),
       recovery = recovery ?? CrashRecoveryService();

  final NativeBrowserEngine engine;
  final IncognitoProfileService profiles;
  final StoragePartitionService partitions;
  final DownloadManager downloads;
  final AdTrackerBlocker blocker;
  final CrashRecoveryService recovery;

  late final NetworkRequestPolicy network = NetworkRequestPolicy(
    blocker: blocker,
  );

  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    await recovery.start();
    await engine.initialize();
    final profile = profiles.create(privateMode: false);
    await engine.createProfile(
      profileId: profile.id,
      mode: EngineProfileMode.normal,
    );
    partitions.open(profileId: profile.id, privateMode: false);
    _started = true;
  }

  Future<String> openPrivateProfile() async {
    final profile = profiles.create(privateMode: true);
    await engine.createProfile(
      profileId: profile.id,
      mode: EngineProfileMode.private,
    );
    partitions.open(profileId: profile.id, privateMode: true);
    return profile.id;
  }

  Future<void> activateProfile(String profileId) async {
    final profile = profiles.get(profileId);
    if (profile == null) {
      throw StateError('Unknown browser profile: $profileId');
    }
    await engine.createProfile(
      profileId: profileId,
      mode: profile.isPrivate
          ? EngineProfileMode.private
          : EngineProfileMode.normal,
    );
  }

  Future<void> closeProfile(String profileId) async {
    final profile = profiles.get(profileId);
    if (profile == null) return;
    await engine.dispose();
    profiles.close(profileId);
    partitions.close(profileId);
  }

  Future<bool> navigate(Uri uri) async {
    final decision = network.evaluate(uri);
    if (!decision.allowed) return false;
    await engine.navigate(decision.finalUri);
    return true;
  }

  Future<void> shutdown() async {
    if (!_started) return;
    await recovery.markCleanShutdown();
    await engine.dispose();
    await downloads.dispose();
    _started = false;
  }

  List<V8Feature> get features => V8FeatureRegistry.all;
}
