import 'package:flutter/material.dart';
import 'package:pharmacy_marketplace_app/core/constants/app_colors.dart';

import '../models/order_summary.dart';

class OrderThreadsSidebar extends StatelessWidget {
  const OrderThreadsSidebar({
    super.key,
    required this.orders,
    required this.selectedOrderId,
    required this.searchController,
    required this.searchText,
    required this.onOrderSelected,
    required this.onSearchChanged,
  });

  final List<OrderSummary> orders;
  final String? selectedOrderId;
  final TextEditingController searchController;
  final String searchText;
  final ValueChanged<String> onOrderSelected;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final visibleOrders = _filterOrders(orders, searchText);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE8ECF3))),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer inbox',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Order chats',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FB),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE4E8F0)),
                      ),
                      child: Text(
                        '${orders.length} orders',
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search order, pharmacy, status...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: searchText.trim().isNotEmpty
                        ? IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              searchController.clear();
                              onSearchChanged('');
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textSecondary,
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF7F8FC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFE4E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFE4E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE8ECF3)),
          Expanded(
            child: visibleOrders.isEmpty
                ? const _NoResultsState()
                : Scrollbar(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: visibleOrders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final order = visibleOrders[index];
                        return _ThreadListTile(
                          order: order,
                          isSelected: order.orderId == selectedOrderId,
                          onTap: () => onOrderSelected(order.orderId),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class OrderThreadStrip extends StatelessWidget {
  const OrderThreadStrip({
    super.key,
    required this.orders,
    required this.selectedOrderId,
    required this.onOrderSelected,
  });

  final List<OrderSummary> orders;
  final String? selectedOrderId;
  final ValueChanged<String> onOrderSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final order = orders[index];
          final isSelected = order.orderId == selectedOrderId;

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onOrderSelected(order.orderId),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFF2F4) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFFE4E8F0),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: _threadAccentFor(order),
                    child: Text(
                      _initialsFor(order),
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.45,
                    ),
                    child: Text(
                      'Order #${order.orderReference}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primaryDark
                            : AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ThreadListTile extends StatelessWidget {
  const _ThreadListTile({
    required this.order,
    required this.isSelected,
    required this.onTap,
  });

  final OrderSummary order;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColorFor(order);
    final secondaryLine = order.isAssigned
        ? '${order.pharmacyName} - ${order.statusLabel}'
        : '${order.pharmacyName} - Awaiting pharmacist';
    final tertiaryLine = order.requiresPrescription
        ? 'Prescription required'
        : 'Open conversation';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF3F5) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE6EAF1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: _threadAccentFor(order),
                child: Text(
                  _initialsFor(order),
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'Order #${order.orderReference}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _dateLabelFor(order),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      secondaryLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            tertiaryLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: order.requiresPrescription
                                  ? AppColors.warning
                                  : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              color: AppColors.textSecondary,
              size: 34,
            ),
            SizedBox(height: 12),
            Text(
              'No matching conversations',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Try a different order reference, pharmacy name, or status.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

List<OrderSummary> _filterOrders(List<OrderSummary> orders, String searchText) {
  final query = searchText.trim().toLowerCase();
  if (query.isEmpty) {
    return orders;
  }

  return orders
      .where((order) {
        return order.orderReference.toLowerCase().contains(query) ||
            order.pharmacyName.toLowerCase().contains(query) ||
            order.displayPharmacistName.toLowerCase().contains(query) ||
            order.statusLabel.toLowerCase().contains(query);
      })
      .toList(growable: false);
}

String _dateLabelFor(OrderSummary order) {
  final date = order.lastMessageAt ?? order.updatedAt ?? order.createdAt;
  if (date == null) {
    return '';
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

  return '${months[local.month - 1]} ${local.day}';
}

String _initialsFor(OrderSummary order) {
  final source = order.displayPharmacistName.trim().isNotEmpty
      ? order.displayPharmacistName.trim()
      : order.pharmacyName.trim();
  final parts = source
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);

  if (parts.isEmpty) {
    return 'PH';
  }

  if (parts.length == 1) {
    final segment = parts.first;
    return segment.length >= 2
        ? segment.substring(0, 2).toUpperCase()
        : segment.toUpperCase();
  }

  return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
}

Color _statusColorFor(OrderSummary order) {
  if (order.isClosed) {
    return AppColors.warning;
  }

  if (order.isActive) {
    return AppColors.success;
  }

  return AppColors.primaryDark;
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
