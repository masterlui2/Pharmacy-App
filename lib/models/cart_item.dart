import 'package:pharmacy_marketplace_app/models/medicine_item.dart';

class CartItem {
  const CartItem({
    required this.medicine,
    required this.quantity,
  });

  final MedicineItem medicine;
  final int quantity;

  CartItem copyWith({
    MedicineItem? medicine,
    int? quantity,
  }) {
    return CartItem(
      medicine: medicine ?? this.medicine,
      quantity: quantity ?? this.quantity,
    );
  }
}
