import 'dart:convert';

import 'chat_message.dart';

class ChatSession {
  final String id;
  String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatSession.newSession() {
    final now = DateTime.now();
    return ChatSession(
      id: now.millisecondsSinceEpoch.toString(),
      title: 'Yeni Sohbet',
      messages: [],
      createdAt: now,
      updatedAt: now,
    );
  }

  String toJson() => jsonEncode({
        'id': id,
        'title': title,
        'messages': messages
            .map((m) => {
                  'role': m.role.name,
                  'text': m.text,
                  'createdAt': m.createdAt.toIso8601String(),
                })
            .toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      });

  factory ChatSession.fromJson(String source) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    return ChatSession(
      id: data['id'] as String,
      title: data['title'] as String? ?? 'Sohbet',
      messages: (data['messages'] as List<dynamic>?)
              ?.map((m) => ChatMessage(
                    role: ChatRole.values.firstWhere(
                      (r) => r.name == m['role'],
                      orElse: () => ChatRole.user,
                    ),
                    text: m['text'] as String? ?? '',
                    createdAt: DateTime.tryParse(m['createdAt']?.toString() ?? '') ?? DateTime.now(),
                  ))
              .toList() ??
          [],
      createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(data['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  static String encodeList(List<ChatSession> sessions) =>
      jsonEncode(sessions.map((s) => s.toJson()).toList());

  static List<ChatSession> decodeList(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list.map((item) {
      final data = item is String ? jsonDecode(item) : item;
      return ChatSession.fromJson(jsonEncode(data));
    }).toList();
  }
}
