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
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            children: [
              _ConversationIntroCard(order: order),
              _EmptyConversationState(order: order),
            ],
          );
        }

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          itemCount: messages.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _ConversationIntroCard(order: order);
            }

            final message = messages[index - 1];
            final previous = index > 1 ? messages[index - 2] : null;
            final next = index < messages.length ? messages[index] : null;

            final startsGroup =
                previous == null ||
                !_belongsToSameGroup(previous, message, currentUserUid);
            final endsGroup =
                next == null || !_belongsToSameGroup(message, next, currentUserUid);

            return _MessageBubble(
              message: message,
              order: order,
              currentUserUid: currentUserUid,
              startsGroup: startsGroup,
              endsGroup: endsGroup,
            );
          },
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

class _ConversationIntroCard extends StatelessWidget {
  const _ConversationIntroCard({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final orderStatusColor = order.isActive
        ? AppColors.success
        : order.isClosed
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
            'Order #${order.orderReference}',
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
                label: order.displayPharmacistName,
              ),
              _InfoChip(
                icon: Icons.receipt_long_outlined,
                label: order.statusLabel,
                foreground: orderStatusColor,
              ),
              _InfoChip(
                icon: Icons.storefront_outlined,
                label: order.pharmacyName,
              ),
              if (order.requiresPrescription)
                const _InfoChip(
                  icon: Icons.description_outlined,
                  label: 'Prescription required',
                  foreground: AppColors.warning,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            order.isAssigned
                ? 'Messages in this thread are linked to your order and are shared with the pharmacist and POS backend.'
                : 'Your order has no assigned pharmacist yet. The POS can assign one later and continue using this same thread.',
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

class _EmptyConversationState extends StatelessWidget {
  const _EmptyConversationState({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECEEF3)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.forum_outlined,
              color: AppColors.primaryDark,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No messages yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            order.isAssigned
                ? 'Start the conversation for this order and the pharmacist replies will appear here.'
                : 'You can send the first message now. Once a pharmacist is assigned in the POS, replies will appear in this thread.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
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
    final isCustomer = message.isFromCustomer(currentUserUid);
    final senderLabel = _senderLabel();
    final accent = order.requiresPrescription
        ? const Color(0xFFFFF0D6)
        : order.isActive
            ? const Color(0xFFE5F7EE)
            : AppColors.secondary;

    return Padding(
      padding: EdgeInsets.only(
        top: startsGroup ? 10 : 2,
        bottom: endsGroup ? 6 : 2,
      ),
      child: Row(
        mainAxisAlignment:
            isCustomer ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCustomer) ...[
            endsGroup
                ? CircleAvatar(
                    radius: 13,
                    backgroundColor: accent,
                    child: Icon(
                      message.isSystem
                          ? Icons.info_outline_rounded
                          : Icons.local_pharmacy_rounded,
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
                crossAxisAlignment:
                    isCustomer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isCustomer && startsGroup && senderLabel.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 4),
                      child: Text(
                        senderLabel,
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
                      color: _bubbleColor(isCustomer),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft:
                            Radius.circular(!isCustomer && endsGroup ? 5 : 18),
                        bottomRight:
                            Radius.circular(isCustomer && endsGroup ? 5 : 18),
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
                          color: isCustomer ? Colors.white : AppColors.textPrimary,
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

  Color _bubbleColor(bool isCustomer) {
    if (isCustomer) {
      return AppColors.primary;
    }

    if (message.isSystem) {
      return const Color(0xFFF4F5F8);
    }

    return const Color(0xFFF1F2F6);
  }

  String _senderLabel() {
    final senderName = message.senderName.trim();
    if (senderName.isNotEmpty) {
      return senderName;
    }

    if (message.isSystem) {
      return 'System';
    }

    return order.displayPharmacistName;
  }
}
