import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../state/aura_controller.dart';
import '../state/aura_scope.dart';

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final _question = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _question.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = AuraScope.of(context);

    return Scaffold(
      key: const ValueKey('ai_coach'),
      drawer: _ChatDrawer(controller: controller),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 18, 12, 6),
              child: Row(
                children: [
                  // Hamburger menu
                  Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                      tooltip: 'Sohbetler',
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Aura AI', style: Theme.of(context).textTheme.headlineMedium),
                        if (controller.activeSessionId != null)
                          Text(
                            'Kayıtlı sohbet',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Save button
                  IconButton(
                    onPressed: () => _saveChat(controller),
                    icon: const Icon(Icons.save_outlined),
                    tooltip: 'Sohbeti Kaydet',
                  ),
                  // Clear button
                  IconButton(
                    onPressed: controller.clearMessages,
                    icon: const Icon(Icons.delete_sweep),
                    tooltip: 'Temizle',
                  ),
                ],
              ),
            ),
            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                itemCount: controller.messages.length + (controller.isThinking ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= controller.messages.length) {
                    return const _ThinkingBubble();
                  }
                  return _ChatBubble(message: controller.messages[index]);
                },
              ),
            ),
            // Quick buttons
            if (!controller.isThinking)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _QuickButton(label: 'Bugünkü sağlık özetim', onTap: () {
                        _question.text = 'Bugünkü sağlık özetimi çıkar';
                        _send(controller);
                      }),
                      const SizedBox(width: 8),
                      _QuickButton(label: 'Su tüketimim nasıl?', onTap: () {
                        _question.text = 'Su tüketimimi değerlendir';
                        _send(controller);
                      }),
                      const SizedBox(width: 8),
                      _QuickButton(label: 'Kilo kontrolü tavsiyesi', onTap: () {
                        _question.text = 'Kilo kontrolü için tavsiye ver';
                        _send(controller);
                      }),
                    ],
                  ),
                ),
              ),
            // Input
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _question,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Bugünkü durumumu yorumla...',
                        prefixIcon: Icon(Icons.chat_bubble_outline),
                      ),
                      onSubmitted: (_) => _send(controller),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    tooltip: 'Gönder',
                    onPressed: controller.isThinking ? null : () => _send(controller),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _send(AuraController controller) {
    if (controller.apiKey == null || controller.apiKey!.isEmpty) {
      _showApiKeyDialog(controller);
      return;
    }

    final question = _question.text;
    _question.clear();
    controller.askAi(question);
    _scrollToBottom();
  }

  void _saveChat(AuraController controller) {
    if (controller.messages.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kaydedilecek mesaj yok')),
      );
      return;
    }

    final titleController = TextEditingController(
      text: controller.messages
          .firstWhere((m) => m.role == ChatRole.user, orElse: () => ChatMessage(role: ChatRole.user, text: '', createdAt: DateTime.now()))
          .text,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sohbeti Kaydet'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(hintText: 'Sohbet başlığı'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim().isEmpty ? 'Yeni Sohbet' : titleController.text.trim();
              controller.saveCurrentChat(title: title);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sohbet kaydedildi ✅'), duration: Duration(seconds: 2)),
              );
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog(AuraController controller) {
    final keyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('DeepSeek API Anahtarı Gerekli'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('AI ile konuşmak için API anahtarı gerekli.'),
              const SizedBox(height: 12),
              TextField(
                controller: keyController,
                decoration: const InputDecoration(hintText: 'sk-...', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
            FilledButton(
              onPressed: () {
                if (keyController.text.trim().isNotEmpty) {
                  controller.setApiKey(keyController.text.trim());
                  Navigator.pop(context);
                  _send(controller);
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }
}

// --- Sidebar Drawer ---
class _ChatDrawer extends StatelessWidget {
  const _ChatDrawer({required this.controller});

  final AuraController controller;

  @override
  Widget build(BuildContext context) {
    final sessions = controller.chatSessions;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.78,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Row(
                children: [
                  Text('Sohbetler', style: Theme.of(context).textTheme.headlineSmall),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      controller.newChat();
                      Navigator.pop(context);
                    },
                    tooltip: 'Yeni Sohbet',
                  ),
                ],
              ),
            ),
            const Divider(),
            if (sessions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Henüz kayıtlı sohbet yok.\nBir sohbeti kaydet butonu ile kaydedebilirsin.'),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: sessions.length,
                  itemBuilder: (ctx, index) {
                    final session = sessions[index];
                    final isActive = controller.activeSessionId == session.id;

                    return ListTile(
                      selected: isActive,
                      selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      leading: Icon(
                        Icons.chat_bubble_outline,
                        color: isActive ? Theme.of(context).colorScheme.primary : null,
                      ),
                      title: Text(
                        session.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        '${session.messages.length} mesaj',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18),
                        onSelected: (action) {
                          if (action == 'rename') _renameSession(context, session);
                          if (action == 'delete') _deleteSession(context, session);
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'rename', child: Text('Yeniden Adlandır')),
                          const PopupMenuItem(value: 'delete', child: Text('Sil', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                      onTap: () {
                        controller.switchToSession(session);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _renameSession(BuildContext context, ChatSession session) {
    final ctrl = TextEditingController(text: session.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeniden Adlandır'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Yeni başlık'), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                controller.renameSession(session, name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _deleteSession(BuildContext context, ChatSession session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sohbeti Sil'),
        content: Text('"${session.title}" silinecek. Emin misin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              controller.deleteSession(session);
              Navigator.pop(ctx);
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 330),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isUser ? const Radius.circular(6) : null,
            bottomLeft: isUser ? null : const Radius.circular(6),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const SizedBox(
          width: 64,
          child: LinearProgressIndicator(minHeight: 6),
        ),
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  const _QuickButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withValues(alpha: .2)),
      ),
      onPressed: onTap,
    );
  }
}
