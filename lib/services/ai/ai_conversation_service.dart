import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum ConversationRole { system, user, assistant }

class AiMessage {
  const AiMessage({
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final ConversationRole role;
  final String content;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
        'role': role.name,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AiMessage.fromJson(Map<String, dynamic> json) => AiMessage(
        role: ConversationRole.values.firstWhere(
          (e) => e.name == json['role'],
          orElse: () => ConversationRole.user,
        ),
        content: '${json['content'] ?? ''}',
        createdAt: DateTime.tryParse('${json['createdAt']}') ?? DateTime.now(),
      );
}

class AiConversation {
  AiConversation({
    required this.id,
    required this.title,
    List<AiMessage>? messages,
  }) : messages = messages ?? <AiMessage>[];

  final String id;
  String title;
  final List<AiMessage> messages;

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'messages': messages.map((e) => e.toJson()).toList(),
      };

  factory AiConversation.fromJson(Map<String, dynamic> json) {
    final raw = json['messages'];
    return AiConversation(
      id: '${json['id']}',
      title: '${json['title'] ?? 'Conversation'}',
      messages: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(AiMessage.fromJson)
              .toList()
          : <AiMessage>[],
    );
  }
}

class AiConversationService {
  static const _key = 'optimistic.ai.conversations';

  Future<List<AiConversation>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return <AiConversation>[];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return <AiConversation>[];
      return list
          .whereType<Map<String, dynamic>>()
          .map(AiConversation.fromJson)
          .toList();
    } catch (_) {
      return <AiConversation>[];
    }
  }

  Future<void> save(List<AiConversation> conversations) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(conversations.map((e) => e.toJson()).toList()),
    );
  }

  Future<AiConversation> create(String title) async {
    final conversations = await load();
    final item = AiConversation(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.trim().isEmpty ? 'New conversation' : title.trim(),
    );
    conversations.insert(0, item);
    await save(conversations);
    return item;
  }

  Future<void> append(String id, AiMessage message) async {
    final conversations = await load();
    final index = conversations.indexWhere((e) => e.id == id);
    if (index < 0) return;
    conversations[index].messages.add(message);
    await save(conversations);
  }

  Future<void> delete(String id) async {
    final conversations = await load();
    conversations.removeWhere((e) => e.id == id);
    await save(conversations);
  }
}
