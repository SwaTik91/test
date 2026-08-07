import '../store_billing_port.dart';

class RuStoreBillingPort implements StoreBillingPort {
  @override
  Future<bool> buy(String productId) {
    throw UnimplementedError('RuStore billing is not configured yet');
  }
}
