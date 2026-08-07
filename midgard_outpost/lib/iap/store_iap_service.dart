import 'adapters/app_gallery_billing_port.dart';
import 'adapters/fake_billing_port.dart';
import 'adapters/rustore_billing_port.dart';
import 'iap_catalog.dart';
import 'iap_product.dart';
import 'iap_service.dart';
import 'store_billing_port.dart';

class StoreIapService implements IapService {
  StoreIapService({
    StoreTarget target = StoreTarget.fake,
    StoreBillingPort? billing,
  }) : _billing = billing ?? _billingFor(target);

  final StoreBillingPort _billing;

  static StoreBillingPort _billingFor(StoreTarget target) {
    return switch (target) {
      StoreTarget.fake => FakeBillingPort(),
      StoreTarget.appGallery => AppGalleryBillingPort(),
      StoreTarget.ruStore => RuStoreBillingPort(),
    };
  }

  @override
  Future<List<IapProduct>> listProducts() async => IapCatalog.products;

  @override
  Future<bool> purchase(String productId) {
    if (IapCatalog.find(productId) == null) {
      return Future.value(false);
    }
    return _billing.buy(productId);
  }
}
