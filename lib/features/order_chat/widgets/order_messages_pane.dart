import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pharmacy_marketplace_app/core/constants/app_colors.dart';

import '../models/order_chat_message.dart';
import '../models/order_summary.dart';
import '../repositories/order_chat_repository.dart';
import 'order_chat_placeholder.dart';

class OrderMessagesPane extends StatelessWidget {
  const OrderMessagesPane({
    super.key,
    required this.repository,
    required this.order,
    required this.currentUserUid,
    required this.scrollController,
    required this.onMessageCountChanged,
  });

  final OrderChatRepository repository;
  final OrderSummary order;
  final String currentUserUid;
  final ScrollController scrollController;
  final void Function(String orderId, int messageCount) onMessageCountChanged;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderChatMessage>>(
      stream: repository.streamMessages(order.orderId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const OrderChatPlaceholder(
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

        final messages = snapshot.data ?? const <OrderChatMessage>[];
        onMessageCountChanged(order.orderId, messages.length);

        if (messages.isEmpty) {
          return _EmptyConversationState(order: order);
        }

        return DecoratedBox(
          decoration: const BoxDecoration(color: Colors.white),
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final previous = index > 0 ? messages[index - 1] : null;
              final next = index + 1 < messages.length
                  ? messages[index + 1]
                  : null;

              final startsGroup =
                  previous == null ||
                  !_belongsToSameGroup(previous, message, currentUserUid);
              final endsGroup =
                  next == null ||
                  !_belongsToSameGroup(message, next, currentUserUid);
              final showDateDivider =
                  previous == null ||
                  !_isSameDay(previous.createdAt, message.createdAt);

              return Column(
                children: [
                  if (showDateDivider)
                    _DateDivider(label: _dateLabelFor(message.createdAt)),
                  _MessageBubble(
                    message: message,
                    order: order,
                    currentUserUid: currentUserUid,
                    startsGroup: startsGroup,
                    endsGroup: endsGroup,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

bool _belongsToSameGroup(
  OrderChatMessage previous,
  OrderChatMessage current,
  String currentUserUid,
) {
  final previousIsCustomer = previous.isFromCustomer(currentUserUid);
  final currentIsCustomer = current.isFromCustomer(currentUserUid);

  if (previousIsCustomer != currentIsCustomer) {
    return false;
  }

  if (previous.isSystem != current.isSystem) {
    return false;
  }

  return previous.senderName.trim() == current.senderName.trim();
}

bool _isSameDay(DateTime? left, DateTime? right) {
  if (left == null || right == null) {
    return false;
  }

  final a = left.toLocal();
  final b = right.toLocal();
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class _EmptyConversationState extends StatelessWidget {
  const _EmptyConversationState({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final message = order.isAssigned
        ? 'Send your first message and the pharmacist will respond here.'
        : 'This order does not have an assigned pharmacist yet. You can start the conversation now and keep using the same thread later.';

    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.white),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFD),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE3E8F0)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: _threadAccentFor(order),
                    child: Icon(
                      order.isAssigned
                          ? Icons.local_pharmacy_rounded
                          : Icons.support_agent_rounded,
                      size: 28,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'No messages yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
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
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F5F9),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
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
    required this.order,
    required this.currentUserUid,
    required this.startsGroup,
    required this.endsGroup,
  });

  final OrderChatMessage message;
  final OrderSummary order;
  final String currentUserUid;
  final bool startsGroup;
  final bool endsGroup;

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return _SystemMessageBubble(message: message);
    }

    final isCustomer = message.isFromCustomer(currentUserUid);
    final maxBubbleWidth = math.min(
      MediaQuery.sizeOf(context).width * 0.72,
      520.0,
    );

    return Padding(
      padding: EdgeInsets.only(
        top: startsGroup ? 10 : 2,
        bottom: endsGroup ? 10 : 2,
      ),
      child: Row(
        mainAxisAlignment: isCustomer
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCustomer) ...[
            endsGroup
                ? CircleAvatar(
                    radius: 16,
                    backgroundColor: _threadAccentFor(order),
                    child: Icon(
                      Icons.local_pharmacy_rounded,
                      color: AppColors.textPrimary,
                      size: 16,
                    ),
                  )
                : const SizedBox(width: 32),
            const SizedBox(width: 10),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isCustomer ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(
                    isCustomer ? 20 : (endsGroup ? 8 : 20),
                  ),
                  bottomRight: Radius.circular(
                    isCustomer ? (endsGroup ? 8 : 20) : 20,
                  ),
                ),
                border: isCustomer
                    ? null
                    : Border.all(color: const Color(0xFFE3E8F0)),
                boxShadow: isCustomer
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(
                            0xFF101828,
                          ).withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isCustomer && startsGroup)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                _senderLabel(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              message.timestampLabel,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isCustomer
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    if (isCustomer && endsGroup) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          message.timestampLabel,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ] else if (!isCustomer && endsGroup && !startsGroup) ...[
                      const SizedBox(height: 6),
                      Text(
                        message.timestampLabel,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _senderLabel() {
    final senderName = message.senderName.trim();
    if (senderName.isNotEmpty) {
      return senderName;
    }

    return order.displayPharmacistName;
  }
}

class _SystemMessageBubble extends StatelessWidget {
  const _SystemMessageBubble({required this.message});

  final OrderChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F5F9),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            message.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }
}

String _dateLabelFor(DateTime? date) {
  if (date == null) {
    return 'Conversation';
  }

  final local = date.toLocal();
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour >= 12 ? 'PM' : 'AM';

  return '${months[local.month - 1]} ${local.day}, ${local.year} $hour:$minute $suffix';
}

Color _threadAccentFor(OrderSummary order) {
  if (order.requiresPrescription) {
    return const Color(0xFFFFF4E2);
  }

  if (order.isActive) {
    return const Color(0xFFEAF8F1);
  }

  return const Color(0xFFFFEEF1);
}
