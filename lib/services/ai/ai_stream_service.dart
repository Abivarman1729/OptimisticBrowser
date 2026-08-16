import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

enum AiStreamProvider { genericSse, openAiCompatible, anthropic, jsonLines }

class AiCancellationToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}

class AiStreamChunk {
  const AiStreamChunk({required this.text, this.done = false, this.error, this.usage});
  final String text;
  final bool done;
  final String? error;
  final Map<String, Object?>? usage;
}

class AiStreamService {
  AiStreamService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Stream<AiStreamChunk> stream({
    required Uri endpoint,
    required String prompt,
    Map<String, String>? headers,
    AiStreamProvider provider = AiStreamProvider.openAiCompatible,
    AiCancellationToken? cancellation,
    int maxRetries = 2,
    Duration retryDelay = const Duration(milliseconds: 500),
  }) async* {
    final token = cancellation ?? AiCancellationToken();
    Object? lastError;
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      if (token.isCancelled) { yield const AiStreamChunk(text: '', done: true); return; }
      try {
        final request = http.Request('POST', endpoint)
          ..headers.addAll({'content-type': 'application/json', ...?headers})
          ..body = jsonEncode({'prompt': prompt, 'stream': true});
        final response = await _client.send(request);
        if (response.statusCode < 200 || response.statusCode >= 300) throw StateError('AI endpoint returned HTTP ${response.statusCode}');
        await for (final line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
          if (token.isCancelled) { yield const AiStreamChunk(text: '', done: true); return; }
          final parsed = _parse(line.trim(), provider);
          if (parsed != null) {
            if (parsed.done) { yield parsed; return; }
            if (parsed.text.isNotEmpty || parsed.usage != null) yield parsed;
          }
        }
        yield const AiStreamChunk(text: '', done: true);
        return;
      } catch (error) {
        lastError = error;
        if (attempt == maxRetries || token.isCancelled) break;
        await Future<void>.delayed(retryDelay * (attempt + 1));
      }
    }
    yield AiStreamChunk(text: '', error: '$lastError', done: true);
  }

  AiStreamChunk? _parse(String line, AiStreamProvider provider) {
    if (line.isEmpty) return null;
    var value = line;
    if (value.startsWith('data:')) value = value.substring(5).trim();
    if (value == '[DONE]') return const AiStreamChunk(text: '', done: true);
    try {
      final data = jsonDecode(value);
      if (data is! Map<String, dynamic>) return AiStreamChunk(text: value);
      final usage = data['usage'] is Map ? Map<String, Object?>.from(data['usage'] as Map) : null;
      switch (provider) {
        case AiStreamProvider.anthropic:
          final delta = data['delta'];
          if (delta is Map && delta['text'] != null) return AiStreamChunk(text: '${delta['text']}', usage: usage);
          if (data['type'] == 'message_stop') return AiStreamChunk(text: '', done: true, usage: usage);
        case AiStreamProvider.jsonLines:
          return AiStreamChunk(text: '${data['text'] ?? data['content'] ?? ''}', usage: usage);
        case AiStreamProvider.genericSse:
        case AiStreamProvider.openAiCompatible:
          final choices = data['choices'];
          if (choices is List && choices.isNotEmpty && choices.first is Map) {
            final first = Map<String, dynamic>.from(choices.first as Map);
            final delta = first['delta'];
            if (delta is Map && delta['content'] != null) return AiStreamChunk(text: '${delta['content']}', usage: usage);
            if (first['text'] != null) return AiStreamChunk(text: '${first['text']}', usage: usage);
          }
          return AiStreamChunk(text: '${data['text'] ?? data['content'] ?? ''}', usage: usage);
      }
    } catch (_) {
      return AiStreamChunk(text: value);
    }
    return null;
  }
  void dispose() => _client.close();
}
