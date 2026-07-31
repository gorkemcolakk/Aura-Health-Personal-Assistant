part of '../aura_controller.dart';

mixin AuraChatMixin on AuraControllerBase {
  Future<void> askAi(String question) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty || isThinking) {
      return;
    }

    messages = [
      ...messages,
      ChatMessage(
        role: ChatRole.user,
        text: trimmed,
        createdAt: DateTime.now(),
      ),
    ];
    isThinking = true;
    notifyListeners();

    if (currentWeather == null) {
      try {
        await fetchWeather();
      } catch (e) {
        debugPrint("Error fetching weather before AI call: $e");
      }
    }

    final answer = await ai.ask(
      profile: profile,
      medications: medications,
      question: trimmed,
      langCode: languageCode,
      weather: currentWeather,
      apiKey: apiKey,
    );
    messages = [
      ...messages,
      ChatMessage(
        role: ChatRole.assistant,
        text: answer,
        createdAt: DateTime.now(),
      ),
    ];
    isThinking = false;
    notifyListeners();

    if (isVoiceOutputEnabled) {
      voice.speak(answer);
    }

    // Auto-save: kayıtlı sohbet varsa sessizce güncelle
    if (_activeSessionId != null) {
      await _silentSave();
      notifyListeners();
    }
  }

  Future<void> clearMessages() async {
    if (messages.length > 1) {
      messages = [messages.first];
      notifyListeners();
    }
  }

  void toggleVoiceOutput() {
    isVoiceOutputEnabled = !isVoiceOutputEnabled;
    if (!isVoiceOutputEnabled) {
      voice.stop();
    }
    notifyListeners();
  }

  // --- Chat Sessions ---
  Future<void> loadChatSessions() async {
    if (currentUserTc == null) return;
    chatSessions = await db.loadChatSessions(currentUserTc!);
    notifyListeners();
  }

  Future<void> saveCurrentChat({String? title}) async {
    if (currentUserTc == null || messages.length <= 1) return;

    final sessionId = _activeSessionId ?? DateTime.now().millisecondsSinceEpoch.toString();
    final sessionTitle = title ?? _chatTitleFromMessages();
    final lastMessageTime = messages.isNotEmpty ? messages.last.createdAt : DateTime.now();

    final session = ChatSession(
      id: sessionId,
      title: sessionTitle,
      messages: List.from(messages),
      createdAt: DateTime.now(),
      updatedAt: lastMessageTime,
    );

    await db.saveChatSession(currentUserTc!, session);
    _activeSessionId = sessionId;
    await loadChatSessions();
  }

  Future<void> switchToSession(ChatSession session) async {
    // Önce mevcut sohbeti kaydet (eğer aktif session varsa)
    if (_activeSessionId != null && _activeSessionId != session.id && messages.length > 1) {
      await _silentSave(forceSessionId: _activeSessionId);
    }
    _activeSessionId = session.id;
    messages = List.from(session.messages);
    notifyListeners();
  }

  Future<void> _silentSave({String? forceSessionId}) async {
    if (currentUserTc == null) return;
    final sid = forceSessionId ?? _activeSessionId;
    if (sid == null || messages.length <= 1) return;

    final existing = chatSessions.where((s) => s.id == sid).firstOrNull;
    final title = existing?.title ?? _chatTitleFromMessages();
    final lastMessageTime = messages.isNotEmpty ? messages.last.createdAt : (existing?.updatedAt ?? DateTime.now());

    final session = ChatSession(
      id: sid,
      title: title,
      messages: List.from(messages),
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: lastMessageTime,
    );
    await db.saveChatSession(currentUserTc!, session);
    
    final idx = chatSessions.indexWhere((s) => s.id == sid);
    if (idx >= 0) {
      chatSessions[idx] = session;
    } else {
      chatSessions = [session, ...chatSessions];
    }
    chatSessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> renameSession(ChatSession session, String newTitle) async {
    if (currentUserTc == null) return;
    final updated = ChatSession(
      id: session.id,
      title: newTitle,
      messages: session.messages,
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
    );
    await db.saveChatSession(currentUserTc!, updated);
    await loadChatSessions();
  }

  Future<void> deleteSession(ChatSession session) async {
    if (currentUserTc == null) return;
    await db.deleteChatSession(currentUserTc!, session.id);
    if (_activeSessionId == session.id) {
      _activeSessionId = null;
    }
    await loadChatSessions();
  }

  void newChat() {
    _activeSessionId = null;
    messages = [
      ChatMessage(
        role: ChatRole.assistant,
        text: 'Merhaba, ben Aura AI. Profilini, su hedefini ve ilaç düzenini dikkate alarak yardımcı olabilirim.',
        createdAt: DateTime.now(),
      ),
    ];
    notifyListeners();
  }

  String _chatTitleFromMessages() {
    for (final m in messages) {
      if (m.role == ChatRole.user && m.text.isNotEmpty) {
        return m.text.length > 40 ? '${m.text.substring(0, 40)}...' : m.text;
      }
    }
    return 'Yeni Sohbet';
  }
}
