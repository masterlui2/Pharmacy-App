import 'package:flutter/material.dart';
import 'package:pharmacy_marketplace_app/core/constants/app_colors.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _composerController = TextEditingController();
  final ScrollController _messageScrollController = ScrollController();
  late List<_ChatThread> _threads;
  int _selectedThreadIndex = 0;

  @override
  void initState() {
    super.initState();
    _threads = [
      _ChatThread(
        title: 'Order Support',
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
            text:
                'Noted. We already marked your order for contactless delivery.',
            isMe: false,
            timestamp: '2:16 PM',
          ),
        ],
      ),
      _ChatThread(
        title: 'Pharmacist Support',
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
    _messageScrollController.dispose();
    super.dispose();
  }

  void _selectThread(int index) {
    if (index == _selectedThreadIndex) {
      return;
    }

    setState(() => _selectedThreadIndex = index);
    _scrollMessagesToBottom(animated: false);
  }

  void _sendMessage() {
    final value = _composerController.text.trim();
    if (value.isEmpty) {
      return;
    }

    setState(() {
      final selected = _threads[_selectedThreadIndex];
      selected.messages.add(
        _ChatMessage(text: value, isMe: true, timestamp: 'Now'),
      );
      _composerController.clear();
    });
    _scrollMessagesToBottom();
  }

  void _scrollMessagesToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_messageScrollController.hasClients) {
        return;
      }

      final target = _messageScrollController.position.maxScrollExtent;
      if (animated) {
        _messageScrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
        return;
      }

      _messageScrollController.jumpTo(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = _threads[_selectedThreadIndex];

    return SafeArea(
      bottom: false,
      child: ColoredBox(
        color: Colors.white,
        child: Column(
          children: [
            _ChatHeader(
              selected: selected,
              threads: _threads,
              selectedIndex: _selectedThreadIndex,
              onThreadSelected: _selectThread,
            ),
            Expanded(
              child: ListView.builder(
                controller: _messageScrollController,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                itemCount: selected.messages.length,
                itemBuilder: (context, index) {
                  final message = selected.messages[index];
                  final previous = index == 0
                      ? null
                      : selected.messages[index - 1];
                  final next = index == selected.messages.length - 1
                      ? null
                      : selected.messages[index + 1];
                  final startsGroup =
                      previous == null || previous.isMe != message.isMe;
                  final endsGroup = next == null || next.isMe != message.isMe;

                  return _MessageBubble(
                    message: message,
                    accent: selected.accent,
                    startsGroup: startsGroup,
                    endsGroup: endsGroup,
                  );
                },
              ),
            ),
            _MessageComposer(
              controller: _composerController,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.selected,
    required this.threads,
    required this.selectedIndex,
    required this.onThreadSelected,
  });

  final _ChatThread selected;
  final List<_ChatThread> threads;
  final int selectedIndex;
  final ValueChanged<int> onThreadSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFECEEF3))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          children: [
            _ThreadAvatar(accent: selected.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selected.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          selected.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<int>(
              tooltip: 'Switch support chat',
              initialValue: selectedIndex,
              onSelected: onThreadSelected,
              icon: const Icon(Icons.more_horiz_rounded),
              itemBuilder: (context) {
                return [
                  for (var index = 0; index < threads.length; index++)
                    PopupMenuItem<int>(
                      value: index,
                      child: Row(
                        children: [
                          Icon(
                            index == selectedIndex
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: index == selectedIndex
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              threads[index].title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreadAvatar extends StatelessWidget {
  const _ThreadAvatar({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: accent,
          child: const Icon(
            Icons.local_pharmacy_rounded,
            color: AppColors.textPrimary,
            size: 22,
          ),
        ),
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.accent,
    required this.startsGroup,
    required this.endsGroup,
  });

  final _ChatMessage message;
  final Color accent;
  final bool startsGroup;
  final bool endsGroup;

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;

    return Padding(
      padding: EdgeInsets.only(
        top: startsGroup ? 10 : 2,
        bottom: endsGroup ? 6 : 2,
      ),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            endsGroup
                ? CircleAvatar(
                    radius: 13,
                    backgroundColor: accent,
                    child: const Icon(
                      Icons.local_pharmacy_rounded,
                      color: AppColors.textPrimary,
                      size: 14,
                    ),
                  )
                : const SizedBox(width: 26),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.72,
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary : const Color(0xFFF1F2F6),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(
                          !isMe && endsGroup ? 5 : 18,
                        ),
                        bottomRight: Radius.circular(
                          isMe && endsGroup ? 5 : 18,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          color: isMe ? Colors.white : AppColors.textPrimary,
                          height: 1.32,
                        ),
                      ),
                    ),
                  ),
                  if (endsGroup) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        message.timestamp,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFECEEF3))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              tooltip: 'Upload prescription',
              visualDensity: VisualDensity.compact,
              onPressed: () {},
              icon: const Icon(Icons.upload_file_rounded),
              color: AppColors.primary,
            ),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F2F6),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: const InputDecoration(
                    hintText: 'Message',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Send',
              visualDensity: VisualDensity.compact,
              onPressed: onSend,
              icon: const Icon(Icons.send_rounded),
              color: AppColors.primary,
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
