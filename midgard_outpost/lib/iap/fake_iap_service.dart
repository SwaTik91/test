import 'iap_catalog.dart';
import 'iap_product.dart';
import 'iap_service.dart';

class FakeIapService implements IapService {
  @override
  Future<List<IapProduct>> listProducts() async => IapCatalog.products;

  @override
  Future<bool> purchase(String productId) async {
    return IapCatalog.find(productId) != null;
  }
}
