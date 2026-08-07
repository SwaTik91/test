import 'iap_product.dart';

class IapCatalog {
  static const boostDurationMs = 24 * 60 * 60 * 1000;

  static const productIds = [
    'crystals_100',
    'crystals_550',
    'boost_base_job_xp',
    'boost_drop',
    'boost_run_start',
  ];

  static const products = [
    IapProduct(
      id: 'crystals_100',
      title: '100 кристаллов',
      description: 'Пакет кристаллов для магазина',
      crystals: 100,
      priceLabel: '99 ₽',
      kind: IapProductKind.crystals,
    ),
    IapProduct(
      id: 'crystals_550',
      title: '550 кристаллов',
      description: 'Большой пакет кристаллов',
      crystals: 550,
      priceLabel: '449 ₽',
      kind: IapProductKind.crystals,
    ),
    IapProduct(
      id: 'boost_base_job_xp',
      title: 'Буст опыта базы и профессии',
      description: '×2 опыт базы и профессии на 24 часа',
      crystals: 0,
      priceLabel: '149 ₽',
      kind: IapProductKind.boost,
    ),
    IapProduct(
      id: 'boost_drop',
      title: 'Буст дропа',
      description: 'Повышенный шанс дропа на 24 часа',
      crystals: 0,
      priceLabel: '149 ₽',
      kind: IapProductKind.boost,
    ),
    IapProduct(
      id: 'boost_run_start',
      title: 'Буст старта забега',
      description: 'Бонус при старте забега на 24 часа',
      crystals: 0,
      priceLabel: '99 ₽',
      kind: IapProductKind.boost,
    ),
  ];

  static IapProduct? find(String productId) {
    for (final product in products) {
      if (product.id == productId) {
        return product;
      }
    }
    return null;
  }
}
