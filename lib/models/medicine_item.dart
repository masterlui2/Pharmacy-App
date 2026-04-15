class MedicineItem {
  const MedicineItem({
    required this.name,
    required this.manufacturer,
    required this.description,
    required this.price,
    required this.requiresPrescription,
    required this.imageAsset,
    required this.packageSize,
    required this.categoryLabel,
    this.ratingLabel = '4.8 (2.2k)',
  });

  final String name;
  final String manufacturer;
  final String description;
  final double price;
  final bool requiresPrescription;
  final String imageAsset;
  final String packageSize;
  final String categoryLabel;
  final String ratingLabel;
}
