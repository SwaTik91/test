import 'iap_product.dart';
import 'iap_service.dart';

class FakeIapService implements IapService {
  @override
  Future<List<IapProduct>> listProducts() async => const [
        IapProduct(
          id: 'crystals_100',
          title: '100 кристаллов',
          crystals: 100,
          priceLabel: '99 ₽',
        ),
        IapProduct(
          id: 'xp_boost',
          title: 'Буст опыта',
          crystals: 0,
          priceLabel: '149 ₽',
        ),
      ];

  @override
  Future<bool> purchase(String productId) async => true;
}
