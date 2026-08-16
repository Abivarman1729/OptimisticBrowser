import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CrashRecoveryState {
  const CrashRecoveryState({required this.startedAt, required this.lastHeartbeat, required this.cleanShutdown, required this.crashCount, this.lastUrl, this.lastTabId});
  final DateTime startedAt, lastHeartbeat;
  final bool cleanShutdown;
  final int crashCount;
  final String? lastUrl, lastTabId;
  Map<String, Object?> toJson() => {'startedAt': startedAt.toIso8601String(), 'lastHeartbeat': lastHeartbeat.toIso8601String(), 'cleanShutdown': cleanShutdown, 'crashCount': crashCount, 'lastUrl': lastUrl, 'lastTabId': lastTabId};
}

class CrashRecoveryService {
  static const _key = 'optimistic.v9.recovery';
  Timer? _timer;
  Future<CrashRecoveryState> start() async {
    final previous = await _load();
    final state = CrashRecoveryState(startedAt: DateTime.now(), lastHeartbeat: DateTime.now(), cleanShutdown: false, crashCount: previous != null && !previous.cleanShutdown ? previous.crashCount + 1 : previous?.crashCount ?? 0, lastUrl: previous?.lastUrl, lastTabId: previous?.lastTabId);
    await _save(state);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => heartbeat());
    return state;
  }
  Future<void> heartbeat({String? lastUrl, String? lastTabId}) async {
    final current = await _load(); if (current == null) return;
    await _save(CrashRecoveryState(startedAt: current.startedAt, lastHeartbeat: DateTime.now(), cleanShutdown: false, crashCount: current.crashCount, lastUrl: lastUrl ?? current.lastUrl, lastTabId: lastTabId ?? current.lastTabId));
  }
  Future<void> markCleanShutdown() async { final current = await _load(); if (current == null) return; await _save(CrashRecoveryState(startedAt: current.startedAt, lastHeartbeat: DateTime.now(), cleanShutdown: true, crashCount: current.crashCount, lastUrl: current.lastUrl, lastTabId: current.lastTabId)); _timer?.cancel(); }
  Future<CrashRecoveryState?> load() => _load();
  Future<CrashRecoveryState?> _load() async { final prefs = await SharedPreferences.getInstance(); final raw = prefs.getString(_key); if (raw == null) return null; try { final map = jsonDecode(raw) as Map<String, dynamic>; return CrashRecoveryState(startedAt: DateTime.parse('${map['startedAt']}'), lastHeartbeat: DateTime.parse('${map['lastHeartbeat']}'), cleanShutdown: map['cleanShutdown'] == true, crashCount: (map['crashCount'] as num?)?.toInt() ?? 0, lastUrl: map['lastUrl'] as String?, lastTabId: map['lastTabId'] as String?); } catch (_) { return null; } }
  Future<void> _save(CrashRecoveryState state) async { final prefs = await SharedPreferences.getInstance(); await prefs.setString(_key, jsonEncode(state.toJson())); }
  void dispose() => _timer?.cancel();
}
