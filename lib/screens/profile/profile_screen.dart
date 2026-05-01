import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pharmacy_marketplace_app/core/constants/app_colors.dart';
import 'package:pharmacy_marketplace_app/core/utils/currency.dart';
import 'package:pharmacy_marketplace_app/models/delivery_address.dart';
import 'package:pharmacy_marketplace_app/screens/auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.address,
    required this.paymentMethod,
    required this.deliveryFee,
    required this.isDeliveryAvailable,
  });

  final DeliveryAddress address;
  final PaymentMethod paymentMethod;
  final double deliveryFee;
  final bool isDeliveryAvailable;

  @override
  Widget build(BuildContext context) {
    final deliveryStatus = isDeliveryAvailable
        ? 'Available in ${address.city}'
        : 'Outside delivery zone';
    final deliveryStatusColor = isDeliveryAvailable
        ? AppColors.success
        : AppColors.warning;
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final displayName = firebaseUser?.displayName?.trim();
    final profileName = displayName == null || displayName.isEmpty
        ? address.recipientName
        : displayName;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        children: [
          const Text(
            'Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _ProfileHeader(
            name: profileName,
            phoneNumber: address.phoneNumber,
            deliveryStatus: deliveryStatus,
            deliveryStatusColor: deliveryStatusColor,
          ),
          const SizedBox(height: 14),
          _ProfileStats(
            deliveryFee: deliveryFee,
            paymentMethod: paymentMethod,
            isDeliveryAvailable: isDeliveryAvailable,
          ),
          const SizedBox(height: 18),
          _ProfileSection(
            title: 'Delivery',
            children: [
              _ProfileRow(
                icon: Icons.home_work_outlined,
                title: address.addressLabel,
                subtitle: address.shortAddress,
                trailing: Icons.edit_location_alt_outlined,
              ),
              _ProfileRow(
                icon: Icons.delivery_dining_rounded,
                title: 'Delivery coverage',
                subtitle: deliveryStatus,
                statusColor: deliveryStatusColor,
              ),
              _ProfileRow(
                icon: Icons.sticky_note_2_outlined,
                title: 'Rider note',
                subtitle: address.notes.trim().isEmpty
                    ? 'No delivery notes added'
                    : address.notes,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ProfileSection(
            title: 'Orders and Payment',
            children: [
              _ProfileRow(
                icon: _paymentIcon(paymentMethod),
                title: paymentMethod.label,
                subtitle: paymentMethod.caption,
                trailing: Icons.chevron_right_rounded,
              ),
              _ProfileRow(
                icon: Icons.receipt_long_outlined,
                title: 'Order history',
                subtitle: 'Track medicines, receipts, and delivery updates',
                trailing: Icons.chevron_right_rounded,
              ),
              _OrderTrackingRows(user: firebaseUser),
              const _ProfileRow(
                icon: Icons.medical_information_outlined,
                title: 'Prescriptions',
                subtitle: 'Manage uploads required by the pharmacist',
                trailing: Icons.chevron_right_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ProfileSection(
            title: 'Support',
            children: [
              const _ProfileRow(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Pharmacy support',
                subtitle: 'Ask about orders, stock, or prescription checks',
                trailing: Icons.chevron_right_rounded,
              ),
              const _ProfileRow(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Order alerts, delivery updates, and reminders',
                trailing: Icons.chevron_right_rounded,
              ),
              _ProfileRow(
                icon: Icons.logout_rounded,
                title: 'Sign out',
                subtitle: 'Leave this customer account',
                statusColor: AppColors.primary,
                onTap: () => _signOut(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(LoginScreen.routeName, (route) => false);
  }
}

class _OrderTrackingRows extends StatelessWidget {
  const _OrderTrackingRows({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final currentUser = user;
    if (currentUser == null) {
      return const _ProfileRow(
        icon: Icons.receipt_long_outlined,
        title: 'Order tracking',
        subtitle: 'Sign in to track your pharmacy orders',
        trailing: Icons.chevron_right_rounded,
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('customerUid', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _ProfileRow(
            icon: Icons.receipt_long_outlined,
            title: 'Order tracking',
            subtitle: 'Unable to load order updates',
            statusColor: AppColors.warning,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const _ProfileRow(
            icon: Icons.receipt_long_outlined,
            title: 'Order tracking',
            subtitle: 'Loading order updates',
            trailing: Icons.sync_rounded,
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _ProfileRow(
            icon: Icons.receipt_long_outlined,
            title: 'Order tracking',
            subtitle: 'No customer orders found yet',
            trailing: Icons.chevron_right_rounded,
          );
        }

        final sortedDocs = docs.toList()
          ..sort((a, b) {
            final aDate = _readOrderDate(a.data());
            final bDate = _readOrderDate(b.data());
            return bDate.compareTo(aDate);
          });
        final visibleDocs = sortedDocs.take(3).toList(growable: false);

        return Column(
          children: [
            for (final doc in visibleDocs)
              _buildOrderRow(doc, totalCount: docs.length),
          ],
        );
      },
    );
  }

  Widget _buildOrderRow(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required int totalCount,
  }) {
    final data = doc.data();
    final reference =
        _readText(data, const [
          'referenceNumber',
          'reference_number',
          'orderReference',
          'order_reference',
        ]) ??
        doc.id;
    final status =
        _readText(data, const [
          'status',
          'orderStatus',
          'order_status',
          'paymentStatus',
          'payment_status',
        ]) ??
        'Processing';
    final updatedAt = _readOrderDate(data);
    final trackedCount = totalCount == 1 ? '1 order' : '$totalCount orders';

    return _ProfileRow(
      icon: Icons.receipt_long_outlined,
      title: 'Order #$reference',
      subtitle:
          '${_formatStatus(status)} - updated ${_formatOrderDate(updatedAt)} - $trackedCount tracked',
      statusColor: _statusColor(status),
      trailing: Icons.chevron_right_rounded,
    );
  }

  static String? _readText(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static DateTime _readOrderDate(Map<String, dynamic> data) {
    for (final key in const ['updatedAt', 'createdAt', 'paidAt']) {
      final value = data[key];
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
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String _formatStatus(String status) {
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

  static String _formatOrderDate(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) {
      return 'pending';
    }

    final local = date.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.month}/${local.day}/${local.year} $hour:$minute';
  }

  static Color _statusColor(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized.contains('deliver') ||
        normalized.contains('paid') ||
        normalized.contains('complete')) {
      return AppColors.success;
    }
    if (normalized.contains('cancel') ||
        normalized.contains('failed') ||
        normalized.contains('declined')) {
      return AppColors.warning;
    }
    return AppColors.primaryDark;
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.phoneNumber,
    required this.deliveryStatus,
    required this.deliveryStatusColor,
  });

  final String name;
  final String phoneNumber;
  final String deliveryStatus;
  final Color deliveryStatusColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phoneNumber,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    deliveryStatus,
                    style: TextStyle(
                      color: deliveryStatusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({
    required this.deliveryFee,
    required this.paymentMethod,
    required this.isDeliveryAvailable,
  });

  final double deliveryFee;
  final PaymentMethod paymentMethod;
  final bool isDeliveryAvailable;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Delivery',
            value: isDeliveryAvailable ? formatPrice(deliveryFee) : 'N/A',
            icon: Icons.delivery_dining_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Payment',
            value: paymentMethod.label,
            icon: _paymentIcon(paymentMethod),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryDark, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
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
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.statusColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final IconData? trailing;
  final Color? statusColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = statusColor ?? AppColors.primaryDark;
    final row = Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: accent, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: statusColor ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Icon(trailing, color: AppColors.textSecondary),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: onTap == null
          ? row
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: row,
            ),
    );
  }
}

IconData _paymentIcon(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.card:
      return Icons.credit_card_rounded;
    case PaymentMethod.cod:
      return Icons.payments_outlined;
    case PaymentMethod.gcash:
    case PaymentMethod.maya:
      return Icons.account_balance_wallet_rounded;
  }
}
