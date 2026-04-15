class CategoryItem {
  const CategoryItem({
    required this.label,
    required this.imageAsset,
  });

  final String label;
  final String imageAsset;
}

const categoryCatalog = <CategoryItem>[
  CategoryItem(
    label: 'Medicines',
    imageAsset: 'assets/images/category/medical.png',
  ),
  CategoryItem(
    label: 'Supplements',
    imageAsset: 'assets/images/category/supplements.png',
  ),
  CategoryItem(
    label: 'Remedies',
    imageAsset: 'assets/images/category/remedies.png',
  ),
  CategoryItem(
    label: 'Beauty Care',
    imageAsset: 'assets/images/category/beauty.png',
  ),
];
