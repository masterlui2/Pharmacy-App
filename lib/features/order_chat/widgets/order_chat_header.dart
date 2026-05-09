import 'package:flutter/material.dart';
import 'package:pharmacy_marketplace_app/core/constants/app_colors.dart';

import '../models/order_summary.dart';

class OrderChatHeader extends StatelessWidget {
  const OrderChatHeader({
    super.key,
    required this.order,
    required this.messageCount,
    this.isWideLayout = false,
  });

  final OrderSummary order;
  final int messageCount;
  final bool isWideLayout;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColorFor(order);
    final statusLabel = order.statusLabel;
    final messageLabel = messageCount == 1
        ? '1 message'
        : '$messageCount messages';

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8ECF3))),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isWideLayout ? 24 : 16,
          isWideLayout ? 18 : 16,
          isWideLayout ? 24 : 16,
          isWideLayout ? 18 : 16,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: isWideLayout ? 28 : 24,
              backgroundColor: _threadAccentFor(order),
              child: Text(
                _initialsFor(order),
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: isWideLayout ? 18 : 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.displayPharmacistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: isWideLayout ? 18 : 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Order #${order.orderReference} | ${order.pharmacyName}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HeaderChip(
                        icon: Icons.circle,
                        label: statusLabel,
                        foreground: statusColor,
                        iconSize: 10,
                      ),
                      if (order.requiresPrescription)
                        const _HeaderChip(
                          icon: Icons.description_outlined,
                          label: 'Prescription required',
                          foreground: AppColors.warning,
                        ),
                      _HeaderChip(
                        icon: Icons.inventory_2_outlined,
                        label: order.isAssigned
                            ? 'Pharmacist assigned'
                            : 'Awaiting pharmacist',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isWideLayout) ...[
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    statusLabel,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    messageLabel,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.icon,
    required this.label,
    this.foreground = AppColors.textPrimary,
    this.iconSize = 16,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.5,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE4E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: foreground, size: iconSize),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
