import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/core/ids.dart';
import 'package:midgard_outpost/hub/game_controller.dart';
import 'package:midgard_outpost/iap/fake_iap_service.dart';
import 'package:midgard_outpost/iap/iap_catalog.dart';
import 'package:midgard_outpost/iap/store_iap_service.dart';
import 'package:midgard_outpost/progress/hero_progress.dart';
import 'package:midgard_outpost/save/cloud_save_port.dart';
import 'package:midgard_outpost/save/local_save_repository.dart';
import 'package:midgard_outpost/save/save_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<GameController> bootController() async {
    SharedPreferences.setMockInitialValues({});
    final controller = GameController(
      save: SaveService(
        local: LocalSaveRepository(),
        cloud: NoopCloudSavePort(),
      ),
      iap: FakeIapService(),
    );
    await controller.bootstrap();
    return controller;
  }

  test('FakeIapService lists all catalog products', () async {
    final products = await FakeIapService().listProducts();
    expect(products.map((p) => p.id).toList(), IapCatalog.productIds);
  });

  test('buying crystals increases balance', () async {
    final controller = await bootController();
    await controller.createHero(HeroClassId.archer);
    final ok = await controller.purchaseProduct('crystals_100');
    expect(ok, isTrue);
    expect(controller.hero!.crystals, 100);
  });

  test('buying crystal pack stacks on existing balance', () async {
    final controller = await bootController();
    await controller.createHero(HeroClassId.mage);
    await controller.purchaseProduct('crystals_100');
    final ok = await controller.purchaseProduct('crystals_550');
    expect(ok, isTrue);
    expect(controller.hero!.crystals, 650);
  });

  test('buying boost sets timed activeBoosts entry', () async {
    final controller = await bootController();
    await controller.createHero(HeroClassId.paladin);
    final before = DateTime.now().millisecondsSinceEpoch;
    final ok = await controller.purchaseProduct('boost_drop');
    final after = DateTime.now().millisecondsSinceEpoch;
    expect(ok, isTrue);
    final expires = controller.hero!.activeBoosts['boost_drop'];
    expect(expires, isNotNull);
    expect(expires!, greaterThanOrEqualTo(before + IapCatalog.boostDurationMs));
    expect(expires, lessThanOrEqualTo(after + IapCatalog.boostDurationMs));
  });

  test('activeBoosts roundtrips through hero JSON', () {
    final hero = HeroProgress.createNew(
      HeroClassId.archer,
    ).copyWith(activeBoosts: const {'boost_run_start': 1_700_000_000_000});
    final restored = HeroProgress.fromJson(hero.toJson());
    expect(restored.activeBoosts, hero.activeBoosts);
  });

  test('StoreIapService defaults to fake billing', () async {
    final service = StoreIapService();
    final products = await service.listProducts();
    expect(products.length, IapCatalog.productIds.length);
    expect(await service.purchase('crystals_100'), isTrue);
  });

  test('StoreIapService rejects unknown product ids before billing', () async {
    final service = StoreIapService();

    expect(await service.purchase('unknown_product'), isFalse);
  });
}
