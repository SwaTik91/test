enum StoreTarget { appGallery, ruStore, fake }

abstract class StoreBillingPort {
  Future<bool> buy(String productId);
}
