import 'iap_product.dart';

abstract class IapService {
  Future<List<IapProduct>> listProducts();
  Future<bool> purchase(String productId);
}
