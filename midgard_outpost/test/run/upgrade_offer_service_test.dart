import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/content/run_upgrades.dart';
import 'package:midgard_outpost/core/ids.dart';
import 'package:midgard_outpost/run/upgrade_offer_service.dart';
import 'package:midgard_outpost/run/run_state.dart';
import 'package:midgard_outpost/content/balance.dart';

void main() {
  test('rollOffer returns 3 unique upgrades not already owned', () {
    final owned = {'sharp_tips'};
    final offer = UpgradeOfferService.rollOffer(
      classId: HeroClassId.archer,
      owned: owned,
      rng: Random(1),
    );
    expect(offer, hasLength(3));
    expect(offer.map((e) => e.id).toSet(), hasLength(3));
    expect(offer.any((e) => e.id == 'sharp_tips'), isFalse);
  });

  test('temp xp reaches threshold without consuming it', () {
    var state = RunState.initial();
    var thresholdReached = false;
    while (!thresholdReached) {
      final result = UpgradeOfferService.addTempXp(state, 40);
      state = result.state;
      thresholdReached = result.thresholdReached;
    }
    expect(state.tempXp, greaterThanOrEqualTo(Balance.tempXpPerUpgrade));
    final consumed = UpgradeOfferService.consumeTempXpThreshold(state);
    expect(consumed.tempXp, lessThan(Balance.tempXpPerUpgrade));
    expect(thresholdReached, isTrue);
  });

  test('boss kills always trigger upgrade offer', () {
    expect(
      UpgradeOfferService.shouldTriggerOfferFromKill(
        isBoss: true,
        tempXpThresholdReached: false,
        rng: Random(99),
      ),
      isTrue,
    );
  });

  test('monster drop ignores rng when boss', () {
    expect(
      UpgradeOfferService.shouldTriggerOfferFromKill(
        isBoss: true,
        tempXpThresholdReached: false,
        rng: _FakeChanceRng(false),
      ),
      isTrue,
    );
  });

  test('empty offer pool returns no upgrades', () {
    final allIds = RunUpgradesCatalog.forClass(HeroClassId.archer)
        .map((upgrade) => upgrade.id)
        .toSet();
    final offer = UpgradeOfferService.rollOffer(
      classId: HeroClassId.archer,
      owned: allIds,
      rng: Random(1),
    );
    expect(offer, isEmpty);
  });

  test('monster drop uses configured chance', () {
    final rng = _FakeChanceRng(true);
    expect(UpgradeOfferService.shouldDropFromMonster(rng), isTrue);
  });
}

class _FakeChanceRng implements Random {
  _FakeChanceRng(this.value);
  final bool value;

  @override
  double nextDouble() => value ? 0.0 : 0.99;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => value;
}
