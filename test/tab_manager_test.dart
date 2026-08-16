import 'package:flutter_test/flutter_test.dart';
import 'package:optimistic_browser/features/browser/models/browser_tab.dart';
import 'package:optimistic_browser/features/browser/tab_manager.dart';

void main() {
  test('creates, selects, groups and closes tabs', () {
    final manager = TabManager();
    final first = manager.create();
    final second = manager.create();
    manager.assignGroup(second.id, 'group-1');

    expect(manager.active?.id, second.id);
    expect(manager.tabs.length, 2);
    expect(manager.tabs.last.groupId, 'group-1');

    manager.select(first.id);
    expect(manager.active?.id, first.id);

    manager.close(second.id);
    expect(manager.tabs.length, 1);
    expect(manager.recentlyClosed.length, 1);
    expect(manager.recentlyClosed.first.mode, BrowserTabMode.normal);
  });

  test('private tabs are not added to recently closed', () {
    final manager = TabManager();
    final tab = manager.create(mode: BrowserTabMode.private);
    manager.close(tab.id);
    expect(manager.recentlyClosed, isEmpty);
  });
}
