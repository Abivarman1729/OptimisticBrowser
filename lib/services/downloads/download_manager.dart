import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum DownloadState { queued, running, paused, completed, failed, cancelled }

class DownloadTask {
  DownloadTask({
    required this.id,
    required this.url,
    required this.filePath,
    this.totalBytes = 0,
    this.receivedBytes = 0,
    this.state = DownloadState.queued,
    this.error,
    this.mimeType,
    this.fileName,
  });

  final String id;
  final String url;
  final String filePath;
  int totalBytes;
  int receivedBytes;
  DownloadState state;
  String? error;
  String? mimeType;
  String? fileName;

  double get progress => totalBytes <= 0 ? 0 : (receivedBytes / totalBytes).clamp(0, 1);

  Map<String, Object?> toJson() => {
        'id': id, 'url': url, 'filePath': filePath, 'totalBytes': totalBytes,
        'receivedBytes': receivedBytes, 'state': state.name, 'error': error,
        'mimeType': mimeType, 'fileName': fileName,
      };

  static DownloadTask fromJson(Map<String, dynamic> json) => DownloadTask(
        id: '${json['id']}', url: '${json['url']}', filePath: '${json['filePath']}',
        totalBytes: (json['totalBytes'] as num?)?.toInt() ?? 0,
        receivedBytes: (json['receivedBytes'] as num?)?.toInt() ?? 0,
        state: DownloadState.values.firstWhere((e) => e.name == json['state'], orElse: () => DownloadState.queued),
        error: json['error'] as String?, mimeType: json['mimeType'] as String?, fileName: json['fileName'] as String?,
      );
}

/// Durable, resumable download queue. Pausing cancels the current HTTP stream;
/// resuming continues from the existing partial file using HTTP Range.
class DownloadManager {
  static const _storageKey = 'optimistic.v9.downloads';
  final Map<String, DownloadTask> _tasks = {};
  final Map<String, http.Client> _clients = {};
  final StreamController<DownloadTask> _events = StreamController<DownloadTask>.broadcast();

  Stream<DownloadTask> get events => _events.stream;
  List<DownloadTask> get tasks => List.unmodifiable(_tasks.values);

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _tasks
        ..clear()
        ..addAll({for (final e in list) '${e['id']}': DownloadTask.fromJson(Map<String, dynamic>.from(e as Map))});
      for (final task in _tasks.values) {
        if (task.state == DownloadState.running) task.state = DownloadState.paused;
      }
    } catch (_) {}
  }

  Future<DownloadTask> start({required Uri uri, required String filePath, Map<String, String>? headers, String? id}) async {
    final task = id == null ? DownloadTask(id: '${DateTime.now().microsecondsSinceEpoch}', url: uri.toString(), filePath: filePath) : _tasks[id]!;
    _tasks[task.id] = task;
    task.state = DownloadState.running;
    task.error = null;
    await _persist();
    _emit(task);

    final file = File(task.filePath);
    await file.parent.create(recursive: true);
    final existing = await file.exists() ? await file.length() : 0;
    task.receivedBytes = existing;
    final client = http.Client();
    _clients[task.id] = client;

    try {
      final request = http.Request('GET', uri);
      request.headers.addAll(headers ?? {});
      if (existing > 0) request.headers['Range'] = 'bytes=$existing-';
      final response = await client.send(request);
      if (response.statusCode != 200 && response.statusCode != 206) {
        throw HttpException('Download failed: HTTP ${response.statusCode}');
      }
      task.mimeType = response.headers['content-type'];
      final contentLength = response.contentLength ?? 0;
      task.totalBytes = response.statusCode == 206 ? existing + contentLength : contentLength;
      if (response.statusCode == 200 && existing > 0) {
        task.receivedBytes = 0;
      }
      final sink = file.openWrite(mode: response.statusCode == 206 ? FileMode.append : FileMode.write);
      await for (final chunk in response.stream) {
        if (task.state != DownloadState.running) break;
        sink.add(chunk);
        task.receivedBytes += chunk.length;
        _emit(task);
        if (task.receivedBytes % (256 * 1024) < chunk.length) await _persist();
      }
      await sink.flush();
      await sink.close();
      if (task.state == DownloadState.running) {
        task.state = task.totalBytes > 0 && task.receivedBytes < task.totalBytes ? DownloadState.paused : DownloadState.completed;
        if (task.state == DownloadState.completed) await _persist();
      } else {
        await _persist();
      }
    } catch (error) {
      if (task.state == DownloadState.running) {
        task.state = DownloadState.failed;
        task.error = error.toString();
      }
      await _persist();
    } finally {
      _clients.remove(task.id)?.close();
      _emit(task);
    }
    return task;
  }

  void cancel(String id) {
    final task = _tasks[id];
    if (task == null) return;
    task.state = DownloadState.cancelled;
    _clients.remove(id)?.close();
    _emit(task);
    _persist();
  }

  void pause(String id) {
    final task = _tasks[id];
    if (task == null || task.state != DownloadState.running) return;
    task.state = DownloadState.paused;
    _clients.remove(id)?.close();
    _emit(task);
    _persist();
  }

  Future<DownloadTask?> resume(String id, {Map<String, String>? headers}) async {
    final task = _tasks[id];
    if (task == null || (task.state != DownloadState.paused && task.state != DownloadState.failed)) return task;
    return start(uri: Uri.parse(task.url), filePath: task.filePath, headers: headers, id: id);
  }

  Future<void> remove(String id, {bool deletePartialFile = false}) async {
    final task = _tasks.remove(id);
    _clients.remove(id)?.close();
    if (deletePartialFile && task != null) { try { await File(task.filePath).delete(); } catch (_) {} }
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_tasks.values.map((e) => e.toJson()).toList()));
  }

  void _emit(DownloadTask task) { if (!_events.isClosed) _events.add(task); }
  Future<void> dispose() async { for (final client in _clients.values) { client.close(); } _clients.clear(); await _events.close(); }
}
