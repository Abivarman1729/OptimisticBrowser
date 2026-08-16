
import 'models/browser_tab.dart';

class TabManager {
  final List<BrowserTab> _tabs = [];
  final List<BrowserTab> _recentlyClosed = [];
  int _activeIndex = -1;

  List<BrowserTab> get tabs => List.unmodifiable(_tabs);
  List<BrowserTab> get recentlyClosed => List.unmodifiable(_recentlyClosed);
  BrowserTab? get active =>
      _activeIndex >= 0 && _activeIndex < _tabs.length ? _tabs[_activeIndex] : null;

  BrowserTab create({String url = '', BrowserTabMode mode = BrowserTabMode.normal, String? profileId}) {
    final tab = BrowserTab(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      url: url,
      mode: mode,
      profileId: mode == BrowserTabMode.private ? null : profileId,
    );
    _tabs.add(tab);
    _activeIndex = _tabs.length - 1;
    return tab;
  }

  void select(String id) {
    final i = _tabs.indexWhere((t) => t.id == id);
    if (i >= 0) _activeIndex = i;
  }

  BrowserTab? close(String id) {
    final i = _tabs.indexWhere((t) => t.id == id);
    if (i < 0) return null;
    final tab = _tabs.removeAt(i);
    if (tab.mode == BrowserTabMode.normal) _recentlyClosed.insert(0, tab);
    if (_tabs.isEmpty) {
      _activeIndex = -1;
    } else {
      _activeIndex = _activeIndex.clamp(0, _tabs.length - 1);
    }
    return tab;
  }

  BrowserTab? reopenLastClosed() {
    if (_recentlyClosed.isEmpty) return null;
    final tab = _recentlyClosed.removeAt(0);
    _tabs.add(tab);
    _activeIndex = _tabs.length - 1;
    return tab;
  }

  void assignGroup(String id, String? groupId) {
    final i = _tabs.indexWhere((t) => t.id == id);
    if (i >= 0) _tabs[i].groupId = groupId;
  }

  void restore(List<BrowserTab> tabs, {String? activeId}) {
    _tabs
      ..clear()
      ..addAll(tabs);
    _activeIndex = activeId == null
        ? (_tabs.isEmpty ? -1 : 0)
        : _tabs.indexWhere((t) => t.id == activeId);
    if (_activeIndex < 0 && _tabs.isNotEmpty) _activeIndex = 0;
  }

  Map<String, Object?> toJson() => {
        'tabs': _tabs.map((e) => e.toJson()).toList(),
        'activeId': active?.id,
      };
}
