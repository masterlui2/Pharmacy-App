import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pharmacy_marketplace_app/core/constants/app_colors.dart';
import 'package:pharmacy_marketplace_app/features/order_chat/models/order_summary.dart';
import 'package:pharmacy_marketplace_app/features/order_chat/repositories/order_chat_repository.dart';
import 'package:pharmacy_marketplace_app/features/order_chat/widgets/order_chat_placeholder.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({
    super.key,
    this.highlightedOrderReference,
    this.onOpenSupportChat,
  });

  final String? highlightedOrderReference;
  final VoidCallback? onOpenSupportChat;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderChatRepository _repository = OrderChatRepository();

  String? _selectedOrderId;
  String? _lastAppliedHighlightedReference;

  @override
  void didUpdateWidget(covariant OrdersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.highlightedOrderReference != widget.highlightedOrderReference) {
      _lastAppliedHighlightedReference = null;
    }
  }

  void _selectOrder(String orderId) {
    if (orderId == _selectedOrderId) {
      return;
    }

    setState(() => _selectedOrderId = orderId);
  }

  void _syncSelectedOrder(List<OrderSummary> orders) {
    if (orders.isEmpty) {
      return;
    }

    final highlightedReference = widget.highlightedOrderReference?.trim();
    OrderSummary? nextSelection;

    if (highlightedReference != null &&
        highlightedReference.isNotEmpty &&
        highlightedReference != _lastAppliedHighlightedReference) {
      nextSelection = _findMatchingOrder(orders, highlightedReference);
      if (nextSelection != null) {
        _lastAppliedHighlightedReference = highlightedReference;
      }
    }

    if (nextSelection == null && _selectedOrderId != null) {
      for (final order in orders) {
        if (order.orderId == _selectedOrderId) {
          nextSelection = order;
          break;
        }
      }
    }

    nextSelection ??= _pickDefaultOrder(orders);

    if (nextSelection.orderId == _selectedOrderId) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || nextSelection?.orderId == _selectedOrderId) {
        return;
      }

      setState(() => _selectedOrderId = nextSelection!.orderId);
    });
  }

  OrderSummary _pickDefaultOrder(List<OrderSummary> orders) {
    for (final order in orders) {
      if (_isActiveOrOpen(order)) {
        return order;
      }
    }

    return orders.first;
  }

  OrderSummary? _findMatchingOrder(List<OrderSummary> orders, String reference) {
    final normalizedReference = reference.trim().toLowerCase();
    if (normalizedReference.isEmpty) {
      return null;
    }

    for (final order in orders) {
      final orderReference = order.orderReference.trim().toLowerCase();
      final orderId = order.orderId.trim().toLowerCase();
      if (orderReference == normalizedReference || orderId == normalizedReference) {
        return order;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        initialData: FirebaseAuth.instance.currentUser,
        builder: (context, authSnapshot) {
          final currentUser = authSnapshot.data;
          if (currentUser == null) {
            return const OrderChatPlaceholder(
              icon: Icons.receipt_long_outlined,
              title: 'Sign in to track your orders',
              message:
                  'Your order status, pharmacy updates, and delivery progress will appear here after checkout.',
            );
          }

          return StreamBuilder<List<OrderSummary>>(
            stream: _repository.streamCustomerOrders(customerUid: currentUser.uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const OrderChatPlaceholder(
                  icon: Icons.error_outline_rounded,
                  title: 'Unable to load your orders',
                  message:
                      'Check your Firestore data and confirm customer orders are available for this account.',
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final orders = snapshot.data ?? const <OrderSummary>[];
              final activeCount = orders.where(_isActiveOrOpen).length;

              if (orders.isEmpty) {
                return _OrdersEmptyState(
                  highlightedOrderReference: widget.highlightedOrderReference,
                );
              }

              _syncSelectedOrder(orders);

              final selectedOrder = orders.firstWhere(
                (order) => order.orderId == _selectedOrderId,
                orElse: () => _pickDefaultOrder(orders),
              );
              final waitingForHighlightedOrder =
                  widget.highlightedOrderReference?.trim().isNotEmpty == true &&
                  _findMatchingOrder(
                        orders,
                        widget.highlightedOrderReference!.trim(),
                      ) ==
                      null;

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                children: [
                  const Text(
                    'Orders',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    activeCount == 0
                        ? '${orders.length} order${orders.length == 1 ? '' : 's'} in history'
                        : '$activeCount active - ${orders.length} total order${orders.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (waitingForHighlightedOrder) ...[
                    const SizedBox(height: 16),
                    _PendingOrderSyncBanner(
                      orderReference: widget.highlightedOrderReference!.trim(),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _SelectedOrderHero(
                    order: selectedOrder,
                    onOpenSupportChat: widget.onOpenSupportChat,
                  ),
                  const SizedBox(height: 16),
                  _OrderStatusPanel(order: selectedOrder),
                  const SizedBox(height: 18),
                  const Text(
                    'Your order history',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final order in orders) ...[
                    _OrderListCard(
                      order: order,
                      isSelected: order.orderId == selectedOrder.orderId,
                      onTap: () => _selectOrder(order.orderId),
                    ),
                    if (order.orderId != orders.last.orderId)
                      const SizedBox(height: 12),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

bool _isActiveOrOpen(OrderSummary order) {
  if (order.isClosed) {
    return false;
  }

  return _orderStageIndex(order.status) < _orderStages.length - 1;
}

class _OrdersEmptyState extends StatelessWidget {
  const _OrdersEmptyState({this.highlightedOrderReference});

  final String? highlightedOrderReference;

  @override
  Widget build(BuildContext context) {
    final normalizedReference = highlightedOrderReference?.trim();
    if (normalizedReference != null && normalizedReference.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.sync_rounded,
                    color: AppColors.primaryDark,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Finalizing your order',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Payment is complete for order #$normalizedReference. We are waiting for the backend to publish the order status here.',
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
      );
    }

    return const OrderChatPlaceholder(
      icon: Icons.local_shipping_outlined,
      title: 'No orders yet',
      message:
          'After checkout, your orders will appear here with status updates from the pharmacy and POS.',
    );
  }
}

class _PendingOrderSyncBanner extends StatelessWidget {
  const _PendingOrderSyncBanner({required this.orderReference});

  final String orderReference;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF5E2B9)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Payment completed for order #$orderReference. Waiting for the POS to sync this order into your live timeline.',
              style: const TextStyle(
                color: AppColors.textPrimary,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedOrderHero extends StatelessWidget {
  const _SelectedOrderHero({
    required this.order,
    required this.onOpenSupportChat,
  });

  final OrderSummary order;
  final VoidCallback? onOpenSupportChat;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order);
    final updatedLabel = _formatOrderDateTime(
      order.updatedAt ?? order.lastMessageAt ?? order.createdAt,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Currently selected',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order #${order.orderReference}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  order.statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _OrderMetaChip(
                icon: Icons.storefront_outlined,
                label: order.pharmacyName,
              ),
              _OrderMetaChip(
                icon: Icons.person_outline_rounded,
                label: order.displayPharmacistName,
              ),
              if (order.requiresPrescription)
                const _OrderMetaChip(
                  icon: Icons.description_outlined,
                  label: 'Prescription required',
                  accent: AppColors.warning,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _HeroStat(
                    label: 'Updated',
                    value: updatedLabel,
                  ),
                ),
                Expanded(
                  child: _HeroStat(
                    label: 'Started',
                    value: _formatOrderDateTime(order.createdAt),
                  ),
                ),
              ],
            ),
          ),
          if (onOpenSupportChat != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenSupportChat,
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('Message pharmacy'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryDark,
                  side: const BorderSide(color: AppColors.secondary),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _OrderMetaChip extends StatelessWidget {
  const _OrderMetaChip({
    required this.icon,
    required this.label,
    this.accent = AppColors.primaryDark,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderStatusPanel extends StatelessWidget {
  const _OrderStatusPanel({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    if (order.isClosed) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF3D7AF)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.statusLabel,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'This order is no longer active. Review the latest update from the pharmacy or contact support from the chat tab if you need help.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final currentStageIndex = _orderStageIndex(order.status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery flow',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _orderStageDescription(order, currentStageIndex),
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < _orderStages.length; index++) ...[
            _StageRow(
              stage: _orderStages[index],
              isDone: index < currentStageIndex,
              isCurrent: index == currentStageIndex,
              isPending: index > currentStageIndex,
              isLast: index == _orderStages.length - 1,
            ),
          ],
        ],
      ),
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.stage,
    required this.isDone,
    required this.isCurrent,
    required this.isPending,
    required this.isLast,
  });

  final _OrderStage stage;
  final bool isDone;
  final bool isCurrent;
  final bool isPending;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final accent = isDone || isCurrent
        ? AppColors.primaryDark
        : const Color(0xFFD6D9E0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.primaryDark
                    : isCurrent
                        ? AppColors.secondary
                        : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: accent, width: 2),
              ),
              child: Icon(
                isDone
                    ? Icons.check_rounded
                    : isCurrent
                        ? Icons.local_shipping_outlined
                        : stage.icon,
                size: 14,
                color: isDone
                    ? Colors.white
                    : isCurrent
                        ? AppColors.primaryDark
                        : accent,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 42,
                color: isDone ? AppColors.primaryDark : const Color(0xFFE8EBF1),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.title,
                  style: TextStyle(
                    color: isPending ? AppColors.textSecondary : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  stage.caption,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderListCard extends StatelessWidget {
  const _OrderListCard({
    required this.order,
    required this.isSelected,
    required this.onTap,
  });

  final OrderSummary order;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : const Color(0xFFFFFBFC),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFEFE2E5),
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _statusIcon(order),
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.orderReference}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.pharmacyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatOrderDateTime(order.sortDate),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      order.statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (order.requiresPrescription) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Rx needed',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderStage {
  const _OrderStage({
    required this.title,
    required this.caption,
    required this.icon,
  });

  final String title;
  final String caption;
  final IconData icon;
}

const List<_OrderStage> _orderStages = <_OrderStage>[
  _OrderStage(
    title: 'Order placed',
    caption: 'Your order is confirmed and waiting for pharmacy review.',
    icon: Icons.receipt_long_outlined,
  ),
  _OrderStage(
    title: 'Preparing',
    caption: 'The pharmacy is checking stock, payment, and prescription needs.',
    icon: Icons.inventory_2_outlined,
  ),
  _OrderStage(
    title: 'On the way',
    caption: 'The order is packed and moving toward dispatch or delivery.',
    icon: Icons.delivery_dining_outlined,
  ),
  _OrderStage(
    title: 'Delivered',
    caption: 'The order was completed and delivered successfully.',
    icon: Icons.home_filled,
  ),
];

int _orderStageIndex(String status) {
  final normalized = status.trim().toLowerCase();

  if (normalized.contains('delivered') ||
      normalized.contains('complete') ||
      normalized.contains('completed')) {
    return 3;
  }

  if (normalized.contains('dispatch') ||
      normalized.contains('rider') ||
      normalized.contains('transit') ||
      normalized.contains('ship') ||
      normalized.contains('way') ||
      normalized.contains('delivery')) {
    return 2;
  }

  if (normalized.contains('prepar') ||
      normalized.contains('paid') ||
      normalized.contains('confirm') ||
      normalized.contains('process') ||
      normalized.contains('pack') ||
      normalized.contains('review') ||
      normalized.contains('ready')) {
    return 1;
  }

  return 0;
}

String _orderStageDescription(OrderSummary order, int stageIndex) {
  if (stageIndex >= _orderStages.length - 1) {
    return 'This order is completed. Review the order card below for the latest pharmacy and delivery details.';
  }

  if (stageIndex == 2) {
    return 'The pharmacy has moved this order past preparation. Delivery or handoff is the current focus.';
  }

  if (stageIndex == 1) {
    return 'The pharmacy is actively working on this order. Status updates will move automatically as the backend changes the order.';
  }

  return 'Your order is recorded and waiting for the next action from the pharmacy team.';
}

Color _statusColor(OrderSummary order) {
  if (order.isClosed) {
    return AppColors.warning;
  }

  final stageIndex = _orderStageIndex(order.status);
  if (stageIndex >= _orderStages.length - 1) {
    return AppColors.success;
  }

  if (stageIndex == 2) {
    return AppColors.primaryDark;
  }

  return AppColors.primary;
}

IconData _statusIcon(OrderSummary order) {
  if (order.isClosed) {
    return Icons.error_outline_rounded;
  }

  final stageIndex = _orderStageIndex(order.status);
  switch (stageIndex) {
    case 3:
      return Icons.check_circle_rounded;
    case 2:
      return Icons.local_shipping_rounded;
    case 1:
      return Icons.inventory_2_rounded;
    default:
      return Icons.receipt_long_rounded;
  }
}

String _formatOrderDateTime(DateTime? dateTime) {
  if (dateTime == null) {
    return 'Pending update';
  }

  final local = dateTime.toLocal();
  final now = DateTime.now();
  final isToday =
      local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour >= 12 ? 'PM' : 'AM';

  if (isToday) {
    return 'Today, $hour:$minute $suffix';
  }

  return '${local.month}/${local.day}/${local.year} - $hour:$minute $suffix';
}
