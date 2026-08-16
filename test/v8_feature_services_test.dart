import 'package:flutter_test/flutter_test.dart';

import 'package:optimistic_browser/core/features/v8_feature_registry.dart';
import 'package:optimistic_browser/services/privacy/ad_tracker_blocker.dart';
import 'package:optimistic_browser/services/privacy/incognito_profile_service.dart';
import 'package:optimistic_browser/services/privacy/storage_partition_service.dart';
import 'package:optimistic_browser/services/reader/reader_mode_service.dart';
import 'package:optimistic_browser/services/tabs/advanced_tab_group_service.dart';

void main() {
  test('all eighteen V8 features are registered', () {
    expect(V8FeatureRegistry.all.length, 18);
  });

  test('private profile is marked private', () {
    final service = IncognitoProfileService();
    final profile = service.create(privateMode: true);
    expect(profile.isPrivate, isTrue);
  });

  test('storage partitions are isolated', () {
    final service = StoragePartitionService();
    service.open(profileId: 'normal', privateMode: false);
    service.open(profileId: 'private', privateMode: true);
    expect(service.isIsolated('normal', 'private'), isTrue);
  });

  test('content blocker catches a known tracker', () {
    final blocker = AdTrackerBlocker();
    expect(
      blocker.shouldBlock(Uri.parse('https://www.google-analytics.com/a.js')),
      isTrue,
    );
  });

  test('reader mode extracts readable text', () {
    final reader = ReaderModeService();
    final result = reader.extract(
      url: 'https://example.com',
      title: 'Example',
      html: '<h1>Hello</h1><p>This is readable article content.</p>',
    );
    expect(result.wordCount, greaterThan(0));
  });

  test('tab groups keep a tab in one group', () {
    final groups = AdvancedTabGroupService();
    final a = groups.create('A');
    final b = groups.create('B');
    groups.addTab(a.id, 'tab-1');
    groups.addTab(b.id, 'tab-1');
    expect(groups.groupForTab('tab-1')?.id, b.id);
  });
}
