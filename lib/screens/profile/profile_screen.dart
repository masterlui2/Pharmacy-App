import 'package:flutter/material.dart';
import 'package:pharmacy_marketplace_app/core/config/maps_config.dart';
import 'package:pharmacy_marketplace_app/core/constants/app_colors.dart';
import 'package:pharmacy_marketplace_app/models/delivery_address.dart';

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
          const SizedBox(height: 6),
          const Text(
            'Account preferences, saved delivery setup, and payment settings.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 18),
          _ProfileCard(
            title: 'Delivery Setup',
            icon: Icons.location_on_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address.shortAddress,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isDeliveryAvailable
                      ? 'Covered for Davao delivery'
                      : 'Outside the configured Davao delivery radius',
                  style: TextStyle(
                    color: isDeliveryAvailable
                        ? AppColors.success
                        : AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Current delivery fee: PHP ${deliveryFee.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ProfileCard(
            title: 'Maps Setup',
            icon: Icons.key_outlined,
            child: Text(
              MapsConfig.isConfigured
                  ? 'Google Maps API key is loaded from lib/core/config/app_api_keys.dart.'
                  : 'No Google Maps API key detected. Paste it into lib/core/config/app_api_keys.dart.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _ProfileCard(
            title: 'PayMongo',
            icon: Icons.account_balance_wallet_outlined,
            child: Text(
              'Preferred payment: ${paymentMethod.label} (${paymentMethod.caption})',
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.secondary,
                child: Icon(icon, size: 18, color: AppColors.primaryDark),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
