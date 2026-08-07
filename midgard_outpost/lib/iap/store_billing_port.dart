enum StoreTarget { appGallery, ruStore, fake }

abstract class StoreBillingPort {
  Future<bool> buy(String productId);
}

/// Selects store billing target from `--dart-define=STORE_TARGET=...`.
///
/// Values: `fake` (default), `appGallery`, `ruStore`.
StoreTarget resolveStoreTarget() {
  const env = String.fromEnvironment('STORE_TARGET', defaultValue: 'fake');
  return switch (env) {
    'appGallery' => StoreTarget.appGallery,
    'ruStore' => StoreTarget.ruStore,
    _ => StoreTarget.fake,
  };
}
