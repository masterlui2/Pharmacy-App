import 'package:flutter/material.dart';
import 'package:pharmacy_marketplace_app/core/config/maps_config.dart';
import 'package:pharmacy_marketplace_app/core/constants/app_colors.dart';
import 'package:pharmacy_marketplace_app/core/utils/currency.dart';
import 'package:pharmacy_marketplace_app/models/cart_item.dart';
import 'package:pharmacy_marketplace_app/models/delivery_address.dart';

enum _CheckoutStep {
  address,
  payment,
}

class CartScreen extends StatefulWidget {
  const CartScreen({
    super.key,
    required this.items,
    required this.onBack,
    required this.onRemove,
    required this.onIncrease,
    required this.onDecrease,
    required this.address,
    required this.onAddressChanged,
    required this.onLocateUser,
    required this.isLocating,
    required this.deliveryDistanceKm,
    required this.deliveryFee,
    required this.isDeliveryAvailable,
    required this.maxDeliveryRadiusKm,
    required this.paymentMethod,
    required this.onPaymentMethodChanged,
    required this.onCheckout,
  });

  final List<CartItem> items;
  final VoidCallback onBack;
  final void Function(int index) onRemove;
  final void Function(int index) onIncrease;
  final void Function(int index) onDecrease;
  final DeliveryAddress address;
  final ValueChanged<DeliveryAddress> onAddressChanged;
  final Future<void> Function() onLocateUser;
  final bool isLocating;
  final double? deliveryDistanceKm;
  final double deliveryFee;
  final bool isDeliveryAvailable;
  final double maxDeliveryRadiusKm;
  final PaymentMethod paymentMethod;
  final ValueChanged<PaymentMethod> onPaymentMethodChanged;
  final VoidCallback onCheckout;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  _CheckoutStep _step = _CheckoutStep.address;

  void _handleBack() {
    if (_step == _CheckoutStep.payment) {
      setState(() => _step = _CheckoutStep.address);
      return;
    }
    widget.onBack();
  }

  void _goToPayment() {
    setState(() => _step = _CheckoutStep.payment);
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.items.fold<double>(
      0,
      (sum, item) => sum + (item.medicine.price * item.quantity),
    );
    const serviceFee = 15.0;
    final total = subtotal + serviceFee + widget.deliveryFee;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Column(
          children: [
            _CheckoutHeader(
              step: _step,
              onBack: _handleBack,
            ),
            const SizedBox(height: 18),
            _CheckoutProgress(step: _step),
            const SizedBox(height: 18),
            Expanded(
              child: widget.items.isEmpty
                  ? const _EmptyCartView()
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _step == _CheckoutStep.address
                          ? _AddressStepView(
                              key: const ValueKey('address-step'),
                              address: widget.address,
                              onAddressChanged: widget.onAddressChanged,
                              onLocateUser: widget.onLocateUser,
                              isLocating: widget.isLocating,
                              deliveryDistanceKm: widget.deliveryDistanceKm,
                              deliveryFee: widget.deliveryFee,
                              isDeliveryAvailable: widget.isDeliveryAvailable,
                              maxDeliveryRadiusKm: widget.maxDeliveryRadiusKm,
                              subtotal: subtotal,
                              onContinue: _goToPayment,
                            )
                          : _PaymentStepView(
                              key: const ValueKey('payment-step'),
                              items: widget.items,
                              address: widget.address,
                              onEditAddress: () {
                                setState(() => _step = _CheckoutStep.address);
                              },
                              onRemove: widget.onRemove,
                              onIncrease: widget.onIncrease,
                              onDecrease: widget.onDecrease,
                              paymentMethod: widget.paymentMethod,
                              onPaymentMethodChanged:
                                  widget.onPaymentMethodChanged,
                              deliveryFee: widget.deliveryFee,
                              serviceFee: serviceFee,
                              subtotal: subtotal,
                              total: total,
                              isDeliveryAvailable: widget.isDeliveryAvailable,
                              onCheckout: widget.onCheckout,
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutHeader extends StatelessWidget {
  const _CheckoutHeader({
    required this.step,
    required this.onBack,
  });

  final _CheckoutStep step;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final title = step == _CheckoutStep.address
        ? 'Delivery address'
        : 'Payment';
    final caption = step == _CheckoutStep.address
        ? 'Step 1 of 2'
        : 'Step 2 of 2';

    return Row(
      children: [
        _CircleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: onBack,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                caption,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Clean checkout',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckoutProgress extends StatelessWidget {
  const _CheckoutProgress({
    required this.step,
  });

  final _CheckoutStep step;

  @override
  Widget build(BuildContext context) {
    final addressDone = true;
    final paymentDone = step == _CheckoutStep.payment;

    return Row(
      children: [
        Expanded(
          child: _ProgressPill(
            label: 'Address',
            isActive: step == _CheckoutStep.address,
            isDone: addressDone,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ProgressPill(
            label: 'Payment',
            isActive: step == _CheckoutStep.payment,
            isDone: paymentDone,
          ),
        ),
      ],
    );
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({
    required this.label,
    required this.isActive,
    required this.isDone,
  });

  final String label;
  final bool isActive;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final background = isActive ? AppColors.primaryDark : Colors.white;
    final foreground = isActive ? Colors.white : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive ? AppColors.primaryDark : AppColors.secondary,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: isActive ? Colors.white : AppColors.primaryDark,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressStepView extends StatelessWidget {
  const _AddressStepView({
    super.key,
    required this.address,
    required this.onAddressChanged,
    required this.onLocateUser,
    required this.isLocating,
    required this.deliveryDistanceKm,
    required this.deliveryFee,
    required this.isDeliveryAvailable,
    required this.maxDeliveryRadiusKm,
    required this.subtotal,
    required this.onContinue,
  });

  final DeliveryAddress address;
  final ValueChanged<DeliveryAddress> onAddressChanged;
  final Future<void> Function() onLocateUser;
  final bool isLocating;
  final double? deliveryDistanceKm;
  final double deliveryFee;
  final bool isDeliveryAvailable;
  final double maxDeliveryRadiusKm;
  final double subtotal;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              _SectionCard(
                title: 'Who receives the order',
                subtitle: 'Keep this short and easy to verify for the rider.',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _AddressField(
                            label: 'Recipient',
                            initialValue: address.recipientName,
                            onChanged: (value) {
                              onAddressChanged(
                                address.copyWith(recipientName: value),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AddressField(
                            label: 'Phone',
                            keyboardType: TextInputType.phone,
                            initialValue: address.phoneNumber,
                            onChanged: (value) {
                              onAddressChanged(
                                address.copyWith(phoneNumber: value),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Delivery location',
                subtitle: 'Set the address clearly so delivery pricing can update correctly.',
                child: Column(
                  children: [
                    _AddressField(
                      label: 'Address label',
                      initialValue: address.addressLabel,
                      onChanged: (value) {
                        onAddressChanged(address.copyWith(addressLabel: value));
                      },
                    ),
                    const SizedBox(height: 12),
                    _AddressField(
                      label: 'Street / building',
                      initialValue: address.streetAddress,
                      onChanged: (value) {
                        onAddressChanged(
                          address.copyWith(
                            streetAddress: value,
                            clearCoordinates: true,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _AddressField(
                            label: 'Barangay / district',
                            initialValue: address.barangay,
                            onChanged: (value) {
                              onAddressChanged(
                                address.copyWith(
                                  barangay: value,
                                  clearCoordinates: true,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AddressField(
                            label: 'City',
                            initialValue: address.city,
                            onChanged: (value) {
                              onAddressChanged(
                                address.copyWith(
                                  city: value,
                                  clearCoordinates: true,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _AddressField(
                      label: 'Landmark / notes',
                      initialValue: address.notes,
                      maxLines: 2,
                      onChanged: (value) {
                        onAddressChanged(address.copyWith(notes: value));
                      },
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        MapsConfig.isConfigured
                            ? 'Google Maps key is already loaded from lib/core/config/app_api_keys.dart.'
                            : 'No Google Maps key found yet. Paste it into lib/core/config/app_api_keys.dart.',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLocating ? null : onLocateUser,
                        icon: Icon(
                          isLocating
                              ? Icons.location_searching_rounded
                              : Icons.my_location_rounded,
                        ),
                        label: Text(
                          isLocating
                              ? 'Detecting your location...'
                              : 'Use current location',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Delivery coverage',
                subtitle:
                    'Davao delivery is limited to ${maxDeliveryRadiusKm.toStringAsFixed(0)} km from the city center.',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _HighlightStat(
                            label: 'Coverage',
                            value: isDeliveryAvailable
                                ? 'Available'
                                : 'Unavailable',
                            color: isDeliveryAvailable
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _HighlightStat(
                            label: 'Delivery fee',
                            value: deliveryFee > 0
                                ? formatPrice(deliveryFee)
                                : 'N/A',
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        deliveryDistanceKm == null
                            ? 'Set a manual Davao address or tap current location to calculate the fee automatically.'
                            : 'Detected distance from Davao center: ${deliveryDistanceKm!.toStringAsFixed(1)} km. ${isDeliveryAvailable ? 'Delivery fee updated for this address.' : 'This location is outside the configured delivery zone.'}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _BottomActionBar(
          title: 'Items subtotal',
          value: formatPrice(subtotal),
          buttonLabel: 'Continue to payment',
          onPressed: isDeliveryAvailable ? onContinue : null,
        ),
      ],
    );
  }
}

class _PaymentStepView extends StatelessWidget {
  const _PaymentStepView({
    super.key,
    required this.items,
    required this.address,
    required this.onEditAddress,
    required this.onRemove,
    required this.onIncrease,
    required this.onDecrease,
    required this.paymentMethod,
    required this.onPaymentMethodChanged,
    required this.deliveryFee,
    required this.serviceFee,
    required this.subtotal,
    required this.total,
    required this.isDeliveryAvailable,
    required this.onCheckout,
  });

  final List<CartItem> items;
  final DeliveryAddress address;
  final VoidCallback onEditAddress;
  final void Function(int index) onRemove;
  final void Function(int index) onIncrease;
  final void Function(int index) onDecrease;
  final PaymentMethod paymentMethod;
  final ValueChanged<PaymentMethod> onPaymentMethodChanged;
  final double deliveryFee;
  final double serviceFee;
  final double subtotal;
  final double total;
  final bool isDeliveryAvailable;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              _SectionCard(
                title: 'Deliver to',
                subtitle: 'Review the address before selecting payment.',
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                address.addressLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                address.shortAddress,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${address.recipientName} • ${address.phoneNumber}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: onEditAddress,
                          child: const Text('Edit'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Mode of payment',
                subtitle: 'Choose the payment option that will be processed through PayMongo.',
                child: Column(
                  children: PaymentMethod.values.map((method) {
                    final isSelected = method == paymentMethod;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => onPaymentMethodChanged(method),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryDark
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                method == PaymentMethod.card
                                    ? Icons.credit_card_rounded
                                    : Icons.account_balance_wallet_rounded,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.primaryDark,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      method.label,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      method.caption,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white70
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Order items',
                subtitle: '${items.length} medicine item(s)',
                child: Column(
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      _CartItemCard(
                        item: items[index],
                        onRemove: () => onRemove(index),
                        onIncrease: () => onIncrease(index),
                        onDecrease: () => onDecrease(index),
                      ),
                      if (index != items.length - 1)
                        const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Order summary',
                subtitle: address.shortAddress,
                child: Column(
                  children: [
                    _SummaryRow(
                      label: 'Subtotal',
                      value: formatPrice(subtotal),
                    ),
                    const SizedBox(height: 10),
                    _SummaryRow(
                      label: 'Delivery fee',
                      value: deliveryFee > 0 ? formatPrice(deliveryFee) : 'N/A',
                    ),
                    const SizedBox(height: 10),
                    _SummaryRow(
                      label: 'Platform fee',
                      value: formatPrice(serviceFee),
                    ),
                    const SizedBox(height: 12),
                    _SummaryRow(
                      label: 'Total',
                      value: formatPrice(total),
                      emphasize: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _BottomActionBar(
          title: 'Total',
          value: formatPrice(total),
          buttonLabel: 'Place order with ${paymentMethod.label}',
          onPressed: isDeliveryAvailable ? onCheckout : null,
        ),
      ],
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.title,
    required this.value,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String value;
  final String buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressField extends StatelessWidget {
  const _AddressField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.keyboardType,
    this.maxLines = 1,
  });

  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey('$label-$initialValue'),
      initialValue: initialValue,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _HighlightStat extends StatelessWidget {
  const _HighlightStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
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
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
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
                      formatPrice(item.medicine.price),
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
                        color: Colors.grey.shade400,
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
