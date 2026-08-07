enum IapProductKind { crystals, boost }

class IapProduct {
  const IapProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.crystals,
    required this.priceLabel,
    required this.kind,
  });

  final String id;
  final String title;
  final String description;
  final int crystals;
  final String priceLabel;
  final IapProductKind kind;
}
