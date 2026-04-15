import 'package:flutter/material.dart';
import 'package:pharmacy_marketplace_app/core/constants/app_colors.dart';
import 'package:pharmacy_marketplace_app/models/cart_item.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({
    super.key,
    required this.items,
    required this.onBack,
    required this.onRemove,
    required this.onIncrease,
    required this.onDecrease,
  });

  final List<CartItem> items;
  final VoidCallback onBack;
  final void Function(int index) onRemove;
  final void Function(int index) onIncrease;
  final void Function(int index) onDecrease;

  @override
  Widget build(BuildContext context) {
    final subtotal = items.fold<double>(
      0,
      (sum, item) => sum + (item.medicine.price * item.quantity),
    );
    const shippingAndTax = 10.0;
    final total = subtotal + shippingAndTax;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Column(
          children: [
            Row(
              children: [
                _CircleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: onBack,
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Cart',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _CircleButton(
                  icon: Icons.delete_outline_rounded,
                  onTap: items.isEmpty
                      ? null
                      : () {
                          for (var i = items.length - 1; i >= 0; i--) {
                            onRemove(i);
                          }
                        },
                ),
                const SizedBox(width: 10),
                const _CircleButton(
                  icon: Icons.share_outlined,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: items.isEmpty
                  ? const _EmptyCartView()
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return _CartItemCard(
                                item: item,
                                onRemove: () => onRemove(index),
                                onIncrease: () => onIncrease(index),
                                onDecrease: () => onDecrease(index),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                        _CartSummary(
                          subtotal: subtotal,
                          shippingAndTax: shippingAndTax,
                          total: total,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Checkout',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onRemove,
    required this.onIncrease,
    required this.onDecrease,
  });

  final CartItem item;
  final VoidCallback onRemove;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: Image.asset(item.medicine.imageAsset, fit: BoxFit.contain),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.medicine.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.medicine.manufacturer,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Size: ${item.medicine.packageSize}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      '\$${item.medicine.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _QuantityButton(
                      icon: Icons.remove,
                      onTap: item.quantity == 1 ? null : onDecrease,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _QuantityButton(
                      icon: Icons.add,
                      onTap: onIncrease,
                      highlight: true,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onRemove,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.grey.shade300,
                        size: 21,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({
    required this.subtotal,
    required this.shippingAndTax,
    required this.total,
  });

  final double subtotal;
  final double shippingAndTax;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SummaryRow(label: 'Sub Total', value: '\$${subtotal.toStringAsFixed(2)}'),
        const SizedBox(height: 10),
        _SummaryRow(
          label: 'Shipping & Tax',
          value: '\$${shippingAndTax.toStringAsFixed(0)}',
        ),
        const SizedBox(height: 12),
        _SummaryRow(
          label: 'Total',
          value: '\$${total.toStringAsFixed(2)}',
          emphasize: true,
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: 15,
      fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
      color: emphasize ? AppColors.textPrimary : AppColors.textSecondary,
    );

    return Row(
      children: [
        Text(label, style: textStyle),
        const Spacer(),
        Text(value, style: textStyle),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            size: 20,
            color: onTap == null ? Colors.grey.shade300 : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: highlight ? AppColors.primary : const Color(0xFFF0DADF),
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: onTap == null
                ? Colors.grey.shade300
                : (highlight ? AppColors.primary : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Your cart is empty.',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
