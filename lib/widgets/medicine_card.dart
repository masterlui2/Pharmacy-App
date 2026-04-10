import 'package:flutter/material.dart';
import 'package:pharmacy_marketplace_app/core/constants/app_colors.dart';

class MedicineCard extends StatelessWidget {
  const MedicineCard({
    super.key,
    required this.name,
    required this.genericName,
    required this.description,
    required this.imageAsset,
    required this.price,
    this.requiresPrescription = false,
    this.onAdd,
  });

  final String name;
  final String genericName;
  final String description;
  final String imageAsset;
  final double price;
  final bool requiresPrescription;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(name, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 3),
            Text(genericName, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (requiresPrescription)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Rx',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Material(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: onAdd,
                    borderRadius: BorderRadius.circular(14),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.add_shopping_cart_rounded,
                        color: AppColors.primaryDark,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
