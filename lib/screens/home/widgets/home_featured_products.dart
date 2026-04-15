import 'package:flutter/material.dart';
import 'package:pharmacy_marketplace_app/core/constants/app_colors.dart';
import 'package:pharmacy_marketplace_app/models/medicine_item.dart';

class HomeFeaturedProducts extends StatelessWidget {
  const HomeFeaturedProducts({
    super.key,
    required this.medicines,
    required this.onAddToCart,
    required this.wishlist,
    required this.onToggleWishlist,
  });

  final List<MedicineItem> medicines;
  final void Function(MedicineItem medicine) onAddToCart;
  final Set<String> wishlist;
  final void Function(MedicineItem medicine) onToggleWishlist;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 254,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final medicine = medicines[index];
          return _FeaturedProductCard(
            medicine: medicine,
            onAddToCart: onAddToCart,
            isWishlisted: wishlist.contains(medicine.name),
            onToggleWishlist: onToggleWishlist,
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemCount: medicines.length,
      ),
    );
  }
}

class _FeaturedProductCard extends StatelessWidget {
  const _FeaturedProductCard({
    required this.medicine,
    required this.onAddToCart,
    required this.isWishlisted,
    required this.onToggleWishlist,
  });

  final MedicineItem medicine;
  final void Function(MedicineItem medicine) onAddToCart;
  final bool isWishlisted;
  final void Function(MedicineItem medicine) onToggleWishlist;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 104,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(medicine.imageAsset, fit: BoxFit.contain),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: () => onToggleWishlist(medicine),
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        isWishlisted
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 18,
                        color: isWishlisted
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            medicine.name,
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
            medicine.categoryLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFF5B944), size: 16),
              const SizedBox(width: 4),
              Text(
                medicine.ratingLabel,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '\$${medicine.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              const Spacer(),
              Material(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => onAddToCart(medicine),
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(9),
                    child: Icon(
                      Icons.add_shopping_cart_rounded,
                      color: AppColors.primaryDark,
                      size: 17,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
