import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../state/aura_controller.dart';
import '../state/aura_scope.dart';

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final _question = TextEditingController();

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AuraScope.of(context);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aura AI',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('Kişisel profilini dikkate alan sağlık koçu.'),
                  ],
                ),
                IconButton(
                  onPressed: controller.clearMessages,
                  icon: const Icon(Icons.delete_sweep),
                  tooltip: 'Sohbeti Temizle',
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              itemCount:
                  controller.messages.length + (controller.isThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= controller.messages.length) {
                  return const _ThinkingBubble();
                }
                return _ChatBubble(message: controller.messages[index]);
              },
            ),
          ),
          if (!controller.isThinking)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _QuickButton(
                      label: 'Bugünkü sağlık özetim',
                      onTap: () {
                        _question.text = 'Bugünkü sağlık özetimi çıkar';
                        _send(controller);
                      },
                    ),
                    const SizedBox(width: 8),
                    _QuickButton(
                      label: 'Su tüketimim nasıl?',
                      onTap: () {
                        _question.text = 'Su tüketimimi değerlendir';
                        _send(controller);
                      },
                    ),
                    const SizedBox(width: 8),
                    _QuickButton(
                      label: 'Kilo kontrolü tavsiyesi',
                      onTap: () {
                        _question.text = 'Kilo kontrolü için tavsiye ver';
                        _send(controller);
                      },
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
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
                  onPressed: controller.isThinking
                      ? null
                      : () => _send(controller),
                  icon: const Icon(Icons.arrow_upward),
                ),
              ],
            ),
          ),
        ],
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
              const Text(
                'Aura AI ile konuşabilmek için ücretsiz bir Google Gemini API anahtarına ihtiyacın var.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keyController,
                decoration: const InputDecoration(
                  hintText: 'AIzaSy...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                if (keyController.text.trim().isNotEmpty) {
                  controller.setApiKey(keyController.text.trim());
                  Navigator.pop(context);
                  _send(controller); // retry send
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
          color: isUser ? const Color(0xFF1A8C83) : Theme.of(context).colorScheme.surface,
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
