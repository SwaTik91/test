import 'dart:math';

import '../content/balance.dart';
import '../content/run_upgrades.dart';
import '../core/ids.dart';
import 'run_state.dart';

class UpgradeOfferService {
  UpgradeOfferService._();

  static const _rareGeneralIds = {'totem_of_power', 'boss_mark'};

  static int _weight(RunUpgradeDef upgrade) {
    if (upgrade.kind == RunUpgradeKind.skill) return 8;
    if (_rareGeneralIds.contains(upgrade.id)) return 3;
    return 10;
  }

  static List<RunUpgradeDef> rollOffer({
    required HeroClassId classId,
    required Set<String> owned,
    required Random rng,
  }) {
    final available = RunUpgradesCatalog.forClass(classId)
        .where((u) => !owned.contains(u.id))
        .toList();

    final count = Balance.upgradeOfferCount;
    if (available.length <= count) return available;

    final pool = List<RunUpgradeDef>.from(available);
    final picked = <RunUpgradeDef>[];

    while (picked.length < count && pool.isNotEmpty) {
      final choice = _weightedPick(pool, rng);
      picked.add(choice);
      pool.remove(choice);
    }

    return picked;
  }

  static RunUpgradeDef _weightedPick(List<RunUpgradeDef> pool, Random rng) {
    final totalWeight = pool.fold<int>(0, (sum, u) => sum + _weight(u));
    var roll = rng.nextInt(totalWeight);
    for (final upgrade in pool) {
      roll -= _weight(upgrade);
      if (roll < 0) return upgrade;
    }
    return pool.last;
  }

  static bool shouldDropFromMonster(Random rng) =>
      rng.nextDouble() < Balance.monsterUpgradeDropChance;

  static ({RunState state, bool offerReady}) addTempXp(
    RunState state,
    int amount,
  ) {
    var tempXp = state.tempXp + amount;
    var offerReady = false;

    while (tempXp >= Balance.tempXpPerUpgrade) {
      tempXp -= Balance.tempXpPerUpgrade;
      offerReady = true;
      break;
    }

    return (
      state: state.copyWith(tempXp: tempXp),
      offerReady: offerReady,
    );
  }
}
