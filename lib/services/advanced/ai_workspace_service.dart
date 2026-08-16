class AiUsage {
  const AiUsage({this.inputTokens = 0, this.outputTokens = 0});
  final int inputTokens;
  final int outputTokens;
  int get totalTokens => inputTokens + outputTokens;
}

class AiConversation {
  AiConversation({required this.id, required this.title, this.folder = 'General'});
  final String id;
  String title;
  String folder;
  final List<Map<String, String>> messages = [];
}

class AiWorkspaceService {
  final Map<String, AiConversation> _conversations = {};

  AiConversation createConversation(String id, String title, {String folder = 'General'}) {
    return _conversations.putIfAbsent(id, () => AiConversation(id: id, title: title, folder: folder));
  }

  List<AiConversation> byFolder(String folder) => _conversations.values.where((c) => c.folder == folder).toList(growable: false);
  List<AiConversation> all() => _conversations.values.toList(growable: false);
  void moveToFolder(String id, String folder) => _conversations[id]?.folder = folder;
  void addMessage(String id, String role, String content) => _conversations[id]?.messages.add({'role': role, 'content': content});

  Stream<String> streamText(String text, {int chunkSize = 24}) async* {
    for (var i = 0; i < text.length; i += chunkSize) {
      final end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
      yield text.substring(i, end);
      await Future<void>.delayed(Duration.zero);
    }
  }

  AiUsage estimateUsage(String input, String output) => AiUsage(
        inputTokens: _estimate(input),
        outputTokens: _estimate(output),
      );

  int _estimate(String value) => value.trim().isEmpty ? 0 : (value.runes.length / 4).ceil();
}
