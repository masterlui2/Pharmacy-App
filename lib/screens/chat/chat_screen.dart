import 'package:flutter/material.dart';
import 'package:pharmacy_marketplace_app/core/constants/app_colors.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _composerController = TextEditingController();
  late List<_ChatThread> _threads;
  int _selectedThreadIndex = 0;

  @override
  void initState() {
    super.initState();
    _threads = [
      _ChatThread(
        title: 'Mercury Davao Support',
        subtitle: 'Online now',
        accent: const Color(0xFFE5F7EE),
        messages: [
          const _ChatMessage(
            text: 'Hello! We are checking your rider assignment for Matina.',
            isMe: false,
            timestamp: '2:14 PM',
          ),
          const _ChatMessage(
            text: 'Please keep my order contactless if possible.',
            isMe: true,
            timestamp: '2:15 PM',
          ),
          const _ChatMessage(
            text: 'Noted. We already marked your order for contactless delivery.',
            isMe: false,
            timestamp: '2:16 PM',
          ),
        ],
      ),
      _ChatThread(
        title: 'Pharmacist On Duty',
        subtitle: 'Replies in a few minutes',
        accent: const Color(0xFFFFF0D6),
        messages: [
          const _ChatMessage(
            text: 'Your Cetirizine request needs a valid prescription upload.',
            isMe: false,
            timestamp: '11:22 AM',
          ),
          const _ChatMessage(
            text: 'Thanks, I will upload it after checkout.',
            isMe: true,
            timestamp: '11:24 AM',
          ),
        ],
      ),
    ];
  }

  @override
  void dispose() {
    _composerController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final value = _composerController.text.trim();
    if (value.isEmpty) {
      return;
    }

    setState(() {
      final selected = _threads[_selectedThreadIndex];
      selected.messages.add(
        _ChatMessage(
          text: value,
          isMe: true,
          timestamp: 'Now',
        ),
      );
      _composerController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = _threads[_selectedThreadIndex];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chats',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Support, pharmacy updates, and rider coordination in one place.',
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _threads.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final thread = _threads[index];
                  final isSelected = index == _selectedThreadIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedThreadIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 220,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryDark : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryDark
                              : AppColors.secondary,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                isSelected ? Colors.white : thread.accent,
                            child: Icon(
                              Icons.chat_bubble_rounded,
                              color: isSelected
                                  ? AppColors.primaryDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  thread.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  thread.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white70
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: selected.accent,
                          child: const Icon(
                            Icons.storefront_rounded,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selected.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                selected.subtitle,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.phone_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: ListView.separated(
                        itemCount: selected.messages.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final message = selected.messages[index];
                          return Align(
                            alignment: message.isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 280),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: message.isMe
                                    ? AppColors.primaryDark
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.text,
                                    style: TextStyle(
                                      color: message.isMe
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                      height: 1.45,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    message.timestamp,
                                    style: TextStyle(
                                      color: message.isMe
                                          ? Colors.white70
                                          : AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.attach_file_rounded),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _composerController,
                            minLines: 1,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Send a message to support',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: _sendMessage,
                          style: FilledButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(14),
                            backgroundColor: AppColors.primaryDark,
                          ),
                          child: const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatThread {
  _ChatThread({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.messages,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final List<_ChatMessage> messages;
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
  });

  final String text;
  final bool isMe;
  final String timestamp;
}
