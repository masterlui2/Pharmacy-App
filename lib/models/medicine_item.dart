class MedicineItem {
  const MedicineItem({
    required this.name,
    required this.genericName,
    required this.description,
    required this.price,
    required this.requiresPrescription,
    required this.imageAsset,
  });

  final String name;
  final String genericName;
  final String description;
  final double price;
  final bool requiresPrescription;
  final String imageAsset;
}
