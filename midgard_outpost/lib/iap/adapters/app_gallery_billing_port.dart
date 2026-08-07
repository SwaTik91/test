import '../store_billing_port.dart';

class AppGalleryBillingPort implements StoreBillingPort {
  @override
  Future<bool> buy(String productId) {
    throw UnimplementedError(
      'Huawei App Gallery IAP is not configured yet',
    );
  }
}
