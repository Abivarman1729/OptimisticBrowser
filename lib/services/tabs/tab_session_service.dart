import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TabSessionSnapshot {
  const TabSessionSnapshot({required this.activeTabId, required this.tabs});
  final String? activeTabId;
  final List<Map<String, Object?>> tabs;
  Map<String, Object?> toJson() => {'activeTabId': activeTabId, 'tabs': tabs};
}

class TabSessionService {
  static const _key = 'optimistic.v9.tab_session';
  Future<void> save(TabSessionSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    // Private/incognito tabs are deliberately never persisted.
    final filtered = snapshot.tabs.where((tab) => tab['mode'] != 'private').toList(growable: false);
    await prefs.setString(_key, jsonEncode({'activeTabId': snapshot.activeTabId, 'tabs': filtered}));
  }
  Future<TabSessionSnapshot?> load() async {
    final prefs = await SharedPreferences.getInstance(); final raw = prefs.getString(_key); if (raw == null) return null;
    try { final map = jsonDecode(raw) as Map<String, dynamic>; final rawTabs = map['tabs']; final tabs = rawTabs is List ? rawTabs.whereType<Map<String, dynamic>>().where((e) => e['mode'] != 'private').map((e) => Map<String, Object?>.from(e)).toList() : <Map<String, Object?>>[]; return TabSessionSnapshot(activeTabId: map['activeTabId'] as String?, tabs: tabs); } catch (_) { return null; }
  }
  Future<void> clear() async { final prefs = await SharedPreferences.getInstance(); await prefs.remove(_key); }
}
