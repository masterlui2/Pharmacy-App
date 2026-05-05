import 'package:flutter/material.dart';
import 'package:pharmacy_marketplace_app/core/constants/app_colors.dart';

import '../models/order_summary.dart';

class OrderChatHeader extends StatelessWidget {
  const OrderChatHeader({
    super.key,
    required this.selectedOrder,
    required this.orders,
    required this.onOrderSelected,
  });

  final OrderSummary selectedOrder;
  final List<OrderSummary> orders;
  final ValueChanged<String> onOrderSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFECEEF3))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ThreadAvatar(order: selectedOrder),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedOrder.displayPharmacistName,
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
                        '${selectedOrder.pharmacyName} - ${selectedOrder.statusLabel}',
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selectedOrder.requiresPrescription
                        ? const Color(0xFFFFF0D6)
                        : AppColors.secondary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    selectedOrder.requiresPrescription
                        ? 'Prescription'
                        : 'Order chat',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Your orders',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 102,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: orders.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _OrderSelectorCard(
                    order: order,
                    isSelected: order.orderId == selectedOrder.orderId,
                    onTap: () => onOrderSelected(order.orderId),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreadAvatar extends StatelessWidget {
  const _ThreadAvatar({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final accent = order.requiresPrescription
        ? const Color(0xFFFFF0D6)
        : order.isActive
            ? const Color(0xFFE5F7EE)
            : AppColors.secondary;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: accent,
          child: Icon(
            order.isAssigned
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
              color: order.isAssigned ? AppColors.success : AppColors.warning,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderSelectorCard extends StatelessWidget {
  const _OrderSelectorCard({
    required this.order,
    required this.isSelected,
    required this.onTap,
  });

  final OrderSummary order;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : const Color(0xFFF8F9FC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : const Color(0xFFE7EAF0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.orderReference}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  order.pharmacyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.92)
                        : AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.displayPharmacistName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.86)
                        : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      order.isAssigned
                          ? Icons.circle_rounded
                          : Icons.schedule_rounded,
                      size: 14,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.9)
                          : order.isAssigned
                              ? AppColors.success
                              : AppColors.warning,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.statusLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
