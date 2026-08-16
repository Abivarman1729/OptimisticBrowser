import 'package:flutter_test/flutter_test.dart';

import 'package:optimistic_browser/core/engine/engine_capabilities.dart';
import 'package:optimistic_browser/services/privacy/incognito_profile_service.dart';
import 'package:optimistic_browser/services/privacy/storage_partition_service.dart';

void main() {
  test('private profile receives a distinct storage namespace', () {
    final service = StoragePartitionService();
    final normal = service.open(profileId: 'normal-1', privateMode: false);
    final privateProfile =
        service.open(profileId: 'private-1', privateMode: true);

    expect(normal.namespace, isNot(privateProfile.namespace));
    expect(service.isIsolated(normal.profileId, privateProfile.profileId), isTrue);
  });

  test('production private capability requires all storage partitions', () {
    const capabilities = EngineCapabilities(
      engineName: 'stage2',
      engineVersion: '9.0-stage2',
      supportsJavaScript: true,
      supportsDownloads: true,
      supportsFileUpload: true,
      supportsPrivateHistoryIsolation: true,
      supportsPerProfileCookies: true,
      supportsPerProfileCache: true,
      supportsPerProfileLocalStorage: true,
      supportsNetworkInterception: true,
      supportsContentBlocking: true,
    );

    expect(capabilities.productionPrivateProfileReady, isTrue);
  });

  test('private profiles are explicitly represented', () {
    final service = IncognitoProfileService();
    final profile = service.create(privateMode: true);
    expect(profile.isPrivate, isTrue);
    expect(service.privateProfiles, hasLength(1));
  });
}
