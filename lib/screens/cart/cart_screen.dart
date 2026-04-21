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
    this.paymentStatus,
    this.orderReference,
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
  final Future<void> Function() onCheckout;
  final String? paymentStatus;
  final String? orderReference;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  _CheckoutStep _step = _CheckoutStep.payment;

  void _handleBack() {
    if (_step == _CheckoutStep.payment) {
      widget.onBack();
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
              deliveryDistanceKm: widget.deliveryDistanceKm,
            ),
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
                              deliveryDistanceKm: widget.deliveryDistanceKm,
                              deliveryFee: widget.deliveryFee,
                              serviceFee: serviceFee,
                              subtotal: subtotal,
                              total: total,
                              isDeliveryAvailable: widget.isDeliveryAvailable,
                              onCheckout: widget.onCheckout,
                              paymentStatus: widget.paymentStatus,
                              orderReference: widget.orderReference,
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
    required this.deliveryDistanceKm,
  });

  final _CheckoutStep step;
  final VoidCallback onBack;
  final double? deliveryDistanceKm;

  @override
  Widget build(BuildContext context) {
    final etaMinutes = deliveryDistanceKm == null
        ? 20
        : (12 + (deliveryDistanceKm! * 4.2)).round();
    final title = step == _CheckoutStep.address
        ? 'Delivery address'
        : 'QuickCare Pharmacy';
    final caption = step == _CheckoutStep.address
        ? 'Step 1 of 2'
        : deliveryDistanceKm == null
            ? 'Distance from you: calculating... ($etaMinutes mins)'
            : 'Distance from you: ${deliveryDistanceKm!.toStringAsFixed(1)} km ($etaMinutes mins)';

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
            color: step == _CheckoutStep.payment
                ? const Color(0xFFEAF7EE)
                : AppColors.secondary,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            step == _CheckoutStep.payment ? 'Open now' : 'Clean checkout',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: step == _CheckoutStep.payment
                  ? const Color(0xFF15803D)
                  : AppColors.primaryDark,
            ),
          ),
        ),
      ],
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
    required this.deliveryDistanceKm,
    required this.deliveryFee,
    required this.serviceFee,
    required this.subtotal,
    required this.total,
    required this.isDeliveryAvailable,
    required this.onCheckout,
    this.paymentStatus,
    this.orderReference,
  });

  final List<CartItem> items;
  final DeliveryAddress address;
  final VoidCallback onEditAddress;
  final void Function(int index) onRemove;
  final void Function(int index) onIncrease;
  final void Function(int index) onDecrease;
  final PaymentMethod paymentMethod;
  final ValueChanged<PaymentMethod> onPaymentMethodChanged;
  final double? deliveryDistanceKm;
  final double deliveryFee;
  final double serviceFee;
  final double subtotal;
  final double total;
  final bool isDeliveryAvailable;
  final Future<void> Function() onCheckout;
  final String? paymentStatus;
  final String? orderReference;

  @override
  Widget build(BuildContext context) {
    final normalizedPaymentStatus = paymentStatus?.trim().toLowerCase();
    final isPaymentSuccessful = normalizedPaymentStatus == 'success';
    final driverNote = address.notes.trim().isEmpty
        ? 'Add a note to driver'
        : address.notes.trim();
    final deliveryMeta = deliveryDistanceKm == null
        ? 'Delivery is being estimated for this address.'
        : '${deliveryDistanceKm!.toStringAsFixed(1)} km away - arrives in about ${(12 + (deliveryDistanceKm! * 4.2)).round()} mins';
    final promoHint = paymentMethod == PaymentMethod.cod
        ? 'Promo not applied'
        : 'Add a promo';
    void showPaymentPicker() {
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return _PaymentMethodSheet(
            selectedMethod: paymentMethod,
            onSelected: (method) {
              Navigator.of(context).pop();
              onPaymentMethodChanged(method);
            },
          );
        },
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              _CheckoutSection(
                title: isPaymentSuccessful ? 'Order status' : 'Delivery information',
                child: isPaymentSuccessful
                    ? _PaymentSuccessCard(
                        orderReference: orderReference,
                        address: address,
                        deliveryDistanceKm: deliveryDistanceKm,
                      )
                    : Column(
                        children: [
                          _InfoRow(
                            icon: Icons.location_on_outlined,
                            title: address.shortAddress,
                            subtitle:
                                '${address.recipientName} - ${address.phoneNumber}',
                            trailing: IconButton(
                              onPressed: onEditAddress,
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.sticky_note_2_outlined,
                            title: driverNote,
                            subtitle: deliveryMeta,
                            trailing: TextButton(
                              onPressed: onEditAddress,
                              child: const Text('Edit'),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              _CheckoutSection(
                title: 'Order Summary',
                actionLabel: isPaymentSuccessful ? null : 'Add items',
                onActionTap: isPaymentSuccessful
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Use the quantity controls below to add more items.',
                            ),
                          ),
                        );
                      },
                child: Column(
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      _CheckoutSummaryItem(
                        item: items[index],
                        onRemove: () => onRemove(index),
                        onIncrease: () => onIncrease(index),
                        onDecrease: () => onDecrease(index),
                      ),
                      if (index != items.length - 1)
                        const Divider(height: 24, color: Color(0xFFF1E8EA)),
                    ],
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFF1E8EA)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _CheckoutSection(
                title: 'Pricing breakdown',
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
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(height: 1, color: Color(0xFFF1E8EA)),
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
              const SizedBox(height: 16),
              _CheckoutSection(
                title: 'Payment method',
                child: Column(
                  children: [
                    _SelectedPaymentRow(
                      method: paymentMethod,
                      onTap: isPaymentSuccessful ? null : showPaymentPicker,
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF1E8EA)),
                    const SizedBox(height: 12),
                    _PromoRow(
                      label: isPaymentSuccessful ? 'Payment confirmed' : promoHint,
                      onTap: isPaymentSuccessful
                          ? null
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Promo code entry can be connected here next.',
                                  ),
                                ),
                              );
                            },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        isPaymentSuccessful
            ? _PaymentSuccessFooter(
                total: total,
                address: address,
                deliveryDistanceKm: deliveryDistanceKm,
              )
            : _BottomActionBar(
                title: 'Total estimated cost',
                value: formatPrice(total),
                buttonLabel: 'Place Order',
                onPressed: isDeliveryAvailable ? () => onCheckout() : null,
              ),
      ],
    );
  }
}

class _PaymentSuccessCard extends StatelessWidget {
  const _PaymentSuccessCard({
    required this.orderReference,
    required this.address,
    required this.deliveryDistanceKm,
  });

  final String? orderReference;
  final DeliveryAddress address;
  final double? deliveryDistanceKm;

  @override
  Widget build(BuildContext context) {
    final etaMinutes = deliveryDistanceKm == null
        ? 20
        : (12 + (deliveryDistanceKm! * 4.2)).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD1F0DA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF15803D),
                size: 28,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Payment successful',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF14532D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your order has been confirmed. Please wait while the pharmacy prepares your medicine for delivery.',
            style: TextStyle(
              color: Colors.green.shade900,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          _SuccessMetaRow(
            icon: Icons.receipt_long_outlined,
            label: 'Order reference',
            value: orderReference?.isNotEmpty == true
                ? orderReference!
                : 'Payment confirmed',
          ),
          const SizedBox(height: 10),
          _SuccessMetaRow(
            icon: Icons.local_shipping_outlined,
            label: 'Delivery status',
            value: 'Preparing for dispatch',
          ),
          const SizedBox(height: 10),
          _SuccessMetaRow(
            icon: Icons.schedule_rounded,
            label: 'Estimated arrival',
            value: '$etaMinutes mins to ${address.addressLabel}',
          ),
        ],
      ),
    );
  }
}

class _SuccessMetaRow extends StatelessWidget {
  const _SuccessMetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF15803D)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$label: $value',
            style: const TextStyle(
              color: Color(0xFF166534),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentSuccessFooter extends StatelessWidget {
  const _PaymentSuccessFooter({
    required this.total,
    required this.address,
    required this.deliveryDistanceKm,
  });

  final double total;
  final DeliveryAddress address;
  final double? deliveryDistanceKm;

  @override
  Widget build(BuildContext context) {
    final etaMinutes = deliveryDistanceKm == null
        ? 20
        : (12 + (deliveryDistanceKm! * 4.2)).round();

    return _CheckoutInfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Paid and queued for delivery',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                formatPrice(total),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'We will deliver to ${address.shortAddress}. Please keep your phone nearby while the rider is on the way.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAF8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'Estimated arrival: about $etaMinutes minutes',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutInfoCard extends StatelessWidget {
  const _CheckoutInfoCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12150F10),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CheckoutSection extends StatelessWidget {
  const _CheckoutSection({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _CheckoutInfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (actionLabel != null)
                TextButton(
                  onPressed: onActionTap,
                  child: Text(actionLabel!),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF9F2F3),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primaryDark),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        trailing ?? const SizedBox.shrink(),
      ],
    );
  }
}

class _CheckoutSummaryItem extends StatelessWidget {
  const _CheckoutSummaryItem({
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF6EFF1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              item.medicine.imageAsset,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.medication_outlined,
                  color: AppColors.primaryDark,
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF6EFF1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${item.quantity}x',
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.medicine.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.medicine.manufacturer} - ${item.medicine.packageSize}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _QuantityButton(
                    icon: Icons.remove,
                    onTap: item.quantity == 1 ? null : onDecrease,
                  ),
                  const SizedBox(width: 10),
                  _QuantityButton(
                    icon: Icons.add,
                    onTap: onIncrease,
                    highlight: true,
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: onRemove,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Remove'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          formatPrice(item.medicine.price * item.quantity),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
      ],
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

Color _paymentAccent(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.gcash:
      return const Color(0xFF3E5B9A);
    case PaymentMethod.maya:
      return const Color(0xFF1C7A72);
    case PaymentMethod.card:
      return const Color(0xFF7A4D9E);
    case PaymentMethod.cod:
      return const Color(0xFFC56A1A);
  }
}

class _SelectedPaymentRow extends StatelessWidget {
  const _SelectedPaymentRow({
    required this.method,
    required this.onTap,
  });

  final PaymentMethod method;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: onTap == null
              ? const Color(0xFFF4F2F3)
              : const Color(0xFFF8F4F5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _paymentIcon(method),
                color: _paymentAccent(method),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected payment method',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    method.label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'Change',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodSheet extends StatelessWidget {
  const _PaymentMethodSheet({
    required this.selectedMethod,
    required this.onSelected,
  });

  final PaymentMethod selectedMethod;
  final ValueChanged<PaymentMethod> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6D8DB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose payment method',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: PaymentMethod.values.map((method) {
                      final isSelected = method == selectedMethod;
                      final accent = _paymentAccent(method);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => onSelected(method),
                          borderRadius: BorderRadius.circular(22),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? accent
                                  : const Color(0xFFF9F4F5),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: isSelected
                                    ? accent
                                    : const Color(0xFFEFE2E5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.22)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    _paymentIcon(method),
                                    color: isSelected ? Colors.white : accent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      const SizedBox(height: 2),
                                      Text(
                                        method.caption,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white.withValues(
                                                  alpha: 0.86,
                                                )
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
                                      : const Color(0xFFBFAFB4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PromoRow extends StatelessWidget {
  const _PromoRow({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Opacity(
        opacity: onTap == null ? 0.72 : 1,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_offer_outlined,
                color: Color(0xFF15803D),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
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
      fontSize: emphasize ? 18 : 13.5,
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
