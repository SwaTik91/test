import '../progress/hero_progress.dart';
import 'iap_catalog.dart';
import 'iap_product.dart';

class IapPurchaseApplier {
  static HeroProgress apply(HeroProgress hero, String productId, {int? nowMs}) {
    final product = IapCatalog.find(productId);
    if (product == null) {
      return hero;
    }

    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    return switch (product.kind) {
      IapProductKind.crystals => hero.copyWith(
          crystals: hero.crystals + product.crystals,
        ),
      IapProductKind.boost => hero.copyWith(
          activeBoosts: {
            ...hero.activeBoosts,
            product.id: now + IapCatalog.boostDurationMs,
          },
        ),
    };
  }
}
