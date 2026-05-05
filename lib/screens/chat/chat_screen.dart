import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final Map<String, int> _messageCountsByThread = <String, int>{};

  String? _selectedThreadId;
  bool _isSending = false;

  @override
  void dispose() {
    _composerController.dispose();
    _messageScrollController.dispose();
    super.dispose();
  }

  void _selectThread(String orderId) {
    if (orderId == _selectedThreadId) {
      return;
    }

    setState(() => _selectedThreadId = orderId);
    _scrollMessagesToBottom(animated: false);
  }

  void _syncSelectedThread(List<_OrderChatThread> threads) {
    final nextSelectedId = threads.isEmpty
        ? null
        : threads.any((thread) => thread.orderId == _selectedThreadId)
        ? _selectedThreadId
        : threads.first.orderId;

    if (nextSelectedId == _selectedThreadId) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || nextSelectedId == _selectedThreadId) {
        return;
      }

      setState(() => _selectedThreadId = nextSelectedId);
      _scrollMessagesToBottom(animated: false);
    });
  }

  void _syncMessageViewport(String orderId, int messageCount) {
    final previousCount = _messageCountsByThread[orderId];
    if (previousCount == messageCount) {
      return;
    }

    _messageCountsByThread[orderId] = messageCount;
    _scrollMessagesToBottom(animated: previousCount != null);
  }

  Future<void> _sendMessage(_OrderChatThread thread) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final text = _composerController.text.trim();

    if (currentUser == null) {
      _showMessage('Please sign in to message the pharmacist.');
      return;
    }
    if (text.isEmpty || _isSending) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSending = true);

    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(thread.orderId)
          .collection('messages')
          .add({
            'type': 'text',
            'text': text,
            'orderId': thread.orderId,
            'orderReference': thread.orderReference,
            'senderUid': currentUser.uid,
            'senderRole': 'customer',
            'senderName': _displayNameFor(currentUser),
            'recipientRole': 'pharmacist',
            'pharmacistUid': thread.pharmacistUid,
            'createdAt': FieldValue.serverTimestamp(),
          });

      _composerController.clear();
      _scrollMessagesToBottom();
    } on FirebaseException catch (error) {
      _showMessage(
        error.message ?? 'Unable to send your message to the pharmacist.',
      );
    } catch (_) {
      _showMessage('Unable to send your message right now.');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  String _displayNameFor(User user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = user.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email;
    }

    return 'Customer';
  }

  void _showPrescriptionHint(_OrderChatThread thread) {
    final message = thread.needsPrescription
        ? 'This order requires a prescription. Ask the POS to attach the prescription workflow to order ${thread.orderReference}.'
        : 'Prescription upload is not connected yet for this order.';
    _showMessage(message);
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const SafeArea(
        child: ColoredBox(
          color: Colors.white,
          child: _ChatPlaceholder(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Sign in to chat with your pharmacist',
            message:
                'Your order-linked support threads appear here after checkout.',
          ),
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: ColoredBox(
        color: Colors.white,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('customerUid', isEqualTo: currentUser.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const _ChatPlaceholder(
                icon: Icons.error_outline_rounded,
                title: 'Unable to load pharmacist chats',
                message:
                    'Check your Firestore data and confirm the order documents are available for this customer.',
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs =
                snapshot.data?.docs ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[];
            final threads =
                docs.map(_OrderChatThread.fromDoc).toList(growable: false)
                  ..sort((a, b) => b.sortDate.compareTo(a.sortDate));

            if (threads.isEmpty) {
              return const _ChatPlaceholder(
                icon: Icons.local_shipping_outlined,
                title: 'No pharmacist chats yet',
                message:
                    'Once your POS creates an order and assigns a pharmacist, the conversation thread will appear here automatically.',
              );
            }

            _syncSelectedThread(threads);

            final selected = threads.firstWhere(
              (thread) => thread.orderId == _selectedThreadId,
              orElse: () => threads.first,
            );

            return Column(
              children: [
                _ChatHeader(
                  selected: selected,
                  threads: threads,
                  onThreadSelected: _selectThread,
                ),
                Expanded(
                  child: _OrderMessagesPane(
                    thread: selected,
                    currentUserUid: currentUser.uid,
                    scrollController: _messageScrollController,
                    onMessageCountChanged: _syncMessageViewport,
                  ),
                ),
                _MessageComposer(
                  controller: _composerController,
                  enabled: !_isSending,
                  isSending: _isSending,
                  onChanged: (_) => setState(() {}),
                  onUploadPrescription: () => _showPrescriptionHint(selected),
                  onSend: () => _sendMessage(selected),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OrderMessagesPane extends StatelessWidget {
  const _OrderMessagesPane({
    required this.thread,
    required this.currentUserUid,
    required this.scrollController,
    required this.onMessageCountChanged,
  });

  final _OrderChatThread thread;
  final String currentUserUid;
  final ScrollController scrollController;
  final void Function(String orderId, int messageCount) onMessageCountChanged;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .doc(thread.orderId)
          .collection('messages')
          .orderBy('createdAt')
          .limitToLast(150)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _ChatPlaceholder(
            icon: Icons.sms_failed_outlined,
            title: 'Unable to load messages',
            message:
                'Confirm the POS is writing chat items into orders/{orderId}/messages.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs =
            snapshot.data?.docs ??
            <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final messages = docs
            .map((doc) => _OrderChatMessage.fromDoc(doc, currentUserUid))
            .toList(growable: false);

        onMessageCountChanged(thread.orderId, messages.length);

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          itemCount: messages.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _ConversationIntroCard(thread: thread);
            }

            final message = messages[index - 1];
            if (message.isSystem) {
              return _SystemMessagePill(message: message);
            }

            final previous = index - 2 >= 0 ? messages[index - 2] : null;
            final next = index < messages.length ? messages[index] : null;
            final startsGroup =
                previous == null ||
                previous.isSystem ||
                previous.isMe != message.isMe;
            final endsGroup =
                next == null || next.isSystem || next.isMe != message.isMe;

            return _MessageBubble(
              message: message,
              accent: thread.accent,
              startsGroup: startsGroup,
              endsGroup: endsGroup,
            );
          },
        );
      },
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.selected,
    required this.threads,
    required this.onThreadSelected,
  });

  final _OrderChatThread selected;
  final List<_OrderChatThread> threads;
  final ValueChanged<String> onThreadSelected;

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
            _ThreadAvatar(
              accent: selected.accent,
              assigned: selected.isAssigned,
            ),
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
                  Text(
                    selected.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Switch order chat',
              onSelected: onThreadSelected,
              icon: const Icon(Icons.more_horiz_rounded),
              itemBuilder: (context) {
                return [
                  for (final thread in threads)
                    PopupMenuItem<String>(
                      value: thread.orderId,
                      child: Row(
                        children: [
                          Icon(
                            thread.orderId == selected.orderId
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: thread.orderId == selected.orderId
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  thread.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Order #${thread.orderReference}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
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
  const _ThreadAvatar({required this.accent, required this.assigned});

  final Color accent;
  final bool assigned;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: accent,
          child: Icon(
            assigned
                ? Icons.local_pharmacy_rounded
                : Icons.support_agent_rounded,
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
              color: assigned ? AppColors.success : AppColors.warning,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConversationIntroCard extends StatelessWidget {
  const _ConversationIntroCard({required this.thread});

  final _OrderChatThread thread;

  @override
  Widget build(BuildContext context) {
    final orderStatusColor = thread.isActive
        ? AppColors.success
        : thread.isClosed
        ? AppColors.warning
        : AppColors.primaryDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order #${thread.orderReference}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.person_outline_rounded,
                label: thread.title,
              ),
              _InfoChip(
                icon: Icons.receipt_long_outlined,
                label: thread.statusLabel,
                foreground: orderStatusColor,
              ),
              _InfoChip(
                icon: Icons.storefront_outlined,
                label: thread.pharmacyName,
              ),
              if (thread.needsPrescription)
                const _InfoChip(
                  icon: Icons.description_outlined,
                  label: 'Prescription required',
                  foreground: AppColors.warning,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            thread.isAssigned
                ? 'Messages in this thread are linked to your order and can be handled by the assigned pharmacist in the POS.'
                : 'Your order has no assigned pharmacist yet. The POS can assign one later and keep using this same thread.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.foreground = AppColors.primaryDark,
  });

  final IconData icon;
  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemMessagePill extends StatelessWidget {
  const _SystemMessagePill({required this.message});

  final _OrderChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F5F8),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            message.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
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

  final _OrderChatMessage message;
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
                  if (!isMe &&
                      startsGroup &&
                      message.senderName.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 4),
                      child: Text(
                        message.senderName,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
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
                        message.timestampLabel,
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
  const _MessageComposer({
    required this.controller,
    required this.enabled,
    required this.isSending,
    required this.onChanged,
    required this.onUploadPrescription,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool isSending;
  final ValueChanged<String> onChanged;
  final VoidCallback onUploadPrescription;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;

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
              tooltip: 'Prescription details',
              visualDensity: VisualDensity.compact,
              onPressed: onUploadPrescription,
              icon: const Icon(Icons.description_outlined),
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
                  enabled: enabled,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  onChanged: onChanged,
                  onSubmitted: (_) => onSend(),
                  decoration: const InputDecoration(
                    hintText: 'Message your pharmacist',
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
              onPressed: enabled && hasText ? onSend : null,
              icon: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatPlaceholder extends StatelessWidget {
  const _ChatPlaceholder({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: AppColors.primaryDark, size: 36),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderChatThread {
  _OrderChatThread({
    required this.orderId,
    required this.orderReference,
    required this.pharmacyName,
    required this.pharmacistUid,
    required this.pharmacistName,
    required this.status,
    required this.sortDate,
    required this.needsPrescription,
  });

  factory _OrderChatThread.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final status =
        _readString(data, const [
          'status',
          'orderStatus',
          'order_status',
          'paymentStatus',
          'payment_status',
        ]) ??
        'Processing';
    final needsPrescription =
        _readBool(data, const [
          'requiresPrescription',
          'prescriptionRequired',
          'prescription.required',
        ]) ??
        false;

    return _OrderChatThread(
      orderId: doc.id,
      orderReference:
          _readString(data, const [
            'referenceNumber',
            'reference_number',
            'orderReference',
            'order_reference',
          ]) ??
          doc.id,
      pharmacyName:
          _readString(data, const [
            'pharmacyName',
            'pharmacy.name',
            'storeName',
            'branchName',
          ]) ??
          'Your pharmacy',
      pharmacistUid: _readString(data, const [
        'pharmacistUid',
        'pharmacist.uid',
      ]),
      pharmacistName:
          _readString(data, const [
            'pharmacistName',
            'pharmacist.name',
            'pharmacist.displayName',
          ]) ??
          '',
      status: status,
      sortDate:
          _readDate(data, const ['lastMessageAt', 'updatedAt', 'createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      needsPrescription: needsPrescription,
    );
  }

  final String orderId;
  final String orderReference;
  final String pharmacyName;
  final String? pharmacistUid;
  final String pharmacistName;
  final String status;
  final DateTime sortDate;
  final bool needsPrescription;

  bool get isAssigned =>
      pharmacistName.trim().isNotEmpty ||
      (pharmacistUid != null && pharmacistUid!.trim().isNotEmpty);

  bool get isClosed {
    final normalized = status.toLowerCase();
    return normalized.contains('cancel') ||
        normalized.contains('failed') ||
        normalized.contains('declined');
  }

  bool get isActive {
    final normalized = status.toLowerCase();
    return normalized.contains('deliver') ||
        normalized.contains('paid') ||
        normalized.contains('complete');
  }

  String get title {
    final normalizedName = pharmacistName.trim();
    if (normalizedName.isNotEmpty) {
      return normalizedName;
    }
    return isAssigned ? 'Assigned pharmacist' : 'Pharmacy support';
  }

  String get subtitle {
    final statusText = statusLabel;
    if (!isAssigned) {
      return 'Order #$orderReference - $statusText - awaiting assignment';
    }
    return 'Order #$orderReference - $pharmacyName - $statusText';
  }

  String get statusLabel => _formatStatus(status);

  Color get accent {
    if (needsPrescription) {
      return const Color(0xFFFFF0D6);
    }
    if (isActive) {
      return const Color(0xFFE5F7EE);
    }
    return AppColors.secondary;
  }
}

class _OrderChatMessage {
  _OrderChatMessage({
    required this.text,
    required this.senderName,
    required this.senderRole,
    required this.timestamp,
    required this.isMe,
    required this.isPending,
  });

  factory _OrderChatMessage.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String currentUserUid,
  ) {
    final data = doc.data();
    final senderUid = _readString(data, const ['senderUid', 'authorUid']) ?? '';
    final senderRole =
        _readString(data, const ['senderRole', 'role'])?.toLowerCase() ??
        'pharmacist';

    return _OrderChatMessage(
      text: _readString(data, const ['text', 'message', 'body']) ?? '',
      senderName:
          _readString(data, const [
            'senderName',
            'authorName',
            'displayName',
          ]) ??
          '',
      senderRole: senderRole,
      timestamp:
          _readDate(data, const ['createdAt', 'timestamp']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isMe: senderUid == currentUserUid || senderRole == 'customer',
      isPending: doc.metadata.hasPendingWrites,
    );
  }

  final String text;
  final String senderName;
  final String senderRole;
  final DateTime timestamp;
  final bool isMe;
  final bool isPending;

  bool get isSystem => senderRole == 'system';

  String get timestampLabel {
    if (isPending || timestamp.millisecondsSinceEpoch == 0) {
      return 'Sending...';
    }
    return _formatMessageTime(timestamp);
  }
}

String? _readString(Map<String, dynamic> data, List<String> paths) {
  for (final path in paths) {
    final value = _readPath(data, path);
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

bool? _readBool(Map<String, dynamic> data, List<String> paths) {
  for (final path in paths) {
    final value = _readPath(data, path);
    if (value is bool) {
      return value;
    }
  }
  return null;
}

DateTime? _readDate(Map<String, dynamic> data, List<String> paths) {
  for (final path in paths) {
    final value = _readPath(data, path);
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return null;
}

Object? _readPath(Map<String, dynamic> data, String path) {
  Object? current = data;
  for (final segment in path.split('.')) {
    if (current is Map<String, dynamic> && current.containsKey(segment)) {
      current = current[segment];
      continue;
    }
    return null;
  }
  return current;
}

String _formatStatus(String status) {
  final words = status
      .trim()
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty);

  return words
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

String _formatMessageTime(DateTime date) {
  final local = date.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  final now = DateTime.now();
  final isToday =
      local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;

  if (isToday) {
    return '$hour:$minute $suffix';
  }

  return '${local.month}/${local.day} $hour:$minute $suffix';
}
