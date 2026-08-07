import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
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

  test('temp xp reaches threshold and flags offer', () {
    var state = RunState.initial();
    var ready = false;
    while (!ready) {
      final result = UpgradeOfferService.addTempXp(state, 40);
      state = result.state;
      ready = result.offerReady;
    }
    expect(state.tempXp, lessThan(Balance.tempXpPerUpgrade));
    expect(ready, isTrue);
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
