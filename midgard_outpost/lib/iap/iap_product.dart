class IapProduct {
  const IapProduct({
    required this.id,
    required this.title,
    required this.crystals,
    required this.priceLabel,
  });

  final String id;
  final String title;
  final int crystals;
  final String priceLabel;
}
