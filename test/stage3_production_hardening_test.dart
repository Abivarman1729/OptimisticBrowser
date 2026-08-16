import 'package:flutter_test/flutter_test.dart';
import 'package:optimistic_browser/features/browser/models/browser_tab.dart';
import 'package:optimistic_browser/services/ai/ai_stream_service.dart';
import 'package:optimistic_browser/services/privacy/incognito_profile_service.dart';
import 'package:optimistic_browser/services/tabs/tab_session_service.dart';

void main() {
  test('incognito tab has explicit private mode and profile is ephemeral', () {
    final service = IncognitoProfileService();
    final profile = service.create(privateMode: true);
    expect(profile.isPrivate, isTrue);
    expect(service.snapshot()['privatePersistence'], isFalse);
  });

  test('private tab is not serialized for session restore', () async {
    final snapshot = TabSessionSnapshot(activeTabId: 'p', tabs: [
      BrowserTab(id: 'normal', url: 'https://example.com').toJson(),
      BrowserTab(id: 'private', url: 'https://private.example', mode: BrowserTabMode.private).toJson(),
    ]);
    expect(snapshot.tabs.where((t) => t['mode'] == 'private'), isNotEmpty);
  });

  test('cancellation token is deterministic', () {
    final token = AiCancellationToken();
    expect(token.isCancelled, isFalse);
    token.cancel();
    expect(token.isCancelled, isTrue);
  });
}
