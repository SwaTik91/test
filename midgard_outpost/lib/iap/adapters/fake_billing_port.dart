import '../store_billing_port.dart';

class FakeBillingPort implements StoreBillingPort {
  @override
  Future<bool> buy(String productId) async => true;
}
