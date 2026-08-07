import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/content/balance.dart';
import 'package:midgard_outpost/content/monsters.dart';
import 'package:midgard_outpost/core/ids.dart';
import 'package:midgard_outpost/progress/hero_progress.dart';
import 'package:midgard_outpost/progress/progress_service.dart';
import 'package:midgard_outpost/run/combat_math.dart';
import 'package:midgard_outpost/run/run_rewards.dart';
import 'package:midgard_outpost/run/systems/spawn_system.dart';

void main() {
  group('Balance Pass 1 — medium difficulty sanity targets', () {
    test('L1 paladin maxHp in medium band', () {
      final hero = HeroProgress.createNew(HeroClassId.paladin);
      expect(CombatMath.maxHp(hero), inInclusiveRange(140, 200));
    });

    test('L1 archer maxHp in medium band', () {
      final hero = HeroProgress.createNew(HeroClassId.archer);
      expect(CombatMath.maxHp(hero), inInclusiveRange(140, 200));
    });

    test('L1 hits-to-kill early mob between 2 and 5 player swings', () {
      final hero = HeroProgress.createNew(HeroClassId.paladin);
      final mob = MonstersCatalog.forDistance(
        distancePx: 0,
        biome: Biome.fields,
        isBoss: false,
      );
      final playerDamage = CombatMath.basicAttackDamage(hero);
      final hits = _hitsToKill(mob.maxHp, playerDamage);

      expect(hits, inInclusiveRange(2, 5));
    });

    test('L1 survives 5–10 hits from early mob before death', () {
      final hero = HeroProgress.createNew(HeroClassId.paladin);
      final mob = MonstersCatalog.forDistance(
        distancePx: 0,
        biome: Biome.fields,
        isBoss: false,
      );
      final playerHp = CombatMath.maxHp(hero);
      final hits = _hitsToKill(playerHp, mob.touchDamage);

      expect(hits, inInclusiveRange(5, 10));
    });

    test('early mob touch damage is 12–20% of L1 maxHp per hit', () {
      final hero = HeroProgress.createNew(HeroClassId.paladin);
      final mob = MonstersCatalog.forDistance(
        distancePx: 0,
        biome: Biome.fields,
        isBoss: false,
      );
      final ratio = mob.touchDamage / CombatMath.maxHp(hero);

      expect(ratio, inInclusiveRange(0.12, 0.20));
    });

    test('L1 mage basic damage within 20% of paladin', () {
      final paladin = HeroProgress.createNew(HeroClassId.paladin);
      final mage = HeroProgress.createNew(HeroClassId.mage);
      final paladinDamage = CombatMath.basicAttackDamage(paladin);
      final mageDamage = CombatMath.basicAttackDamage(mage);
      final ratio = mageDamage / paladinDamage;

      expect(ratio, inInclusiveRange(0.8, 1.2));
    });

    test('Balance drop and intervals match design targets', () {
      expect(Balance.monsterUpgradeDropChance, closeTo(0.11, 1e-9));
      expect(Balance.tempXpPerUpgrade, 90);
      expect(Balance.chestEveryDistancePx, 1000);
      expect(Balance.bossEveryDistancePx, 4000);
    });

    test('XP curves match softer early progression targets', () {
      expect(ProgressService.xpToNextBase(1), 27);
      expect(ProgressService.xpToNextBase(5), 75);
      expect(ProgressService.xpToNextJob(1), 22);
      expect(ProgressService.xpToNextJob(5), 62);
    });

    test('simulated ~3 min kill package yields 1–2 base and job levels', () {
      final hero = HeroProgress.createNew(HeroClassId.paladin);
      final rewards = _simulateThreeMinuteRun();
      final updated = ProgressService.applyRunRewards(hero, rewards);

      expect(updated.baseLevel - hero.baseLevel, inInclusiveRange(1, 2));
      expect(updated.jobLevel - hero.jobLevel, inInclusiveRange(1, 2));
    });

    test('simulated ~3 min kill package gold in 30–80 corridor', () {
      final rewards = _simulateThreeMinuteRun();
      expect(rewards.gold, inInclusiveRange(30, 80));
    });
  });
}

int _hitsToKill(int targetHp, int damagePerHit) {
  return (targetHp / max(1, damagePerHit)).ceil();
}

/// Roughly models kills accumulated before the first boss (~4000 px, ~2–3 min).
RunRewards _simulateThreeMinuteRun() {
  const spawnIntervalPx = 430;
  const firstSpawnPx = 520;
  const deathBeforeBossPx = 3800;

  var totalBaseXp = 0;
  var totalJobXp = 0;
  var totalGold = 0;

  for (
    var spawnPx = firstSpawnPx;
    spawnPx <= deathBeforeBossPx;
    spawnPx += spawnIntervalPx
  ) {
    final spec = MonstersCatalog.forDistance(
      distancePx: spawnPx.toDouble(),
      biome: SpawnSystem.biomeAt(spawnPx),
      isBoss: false,
    );
    totalBaseXp += spec.baseXp;
    totalJobXp += spec.jobXp;
    totalGold += spec.gold;
  }

  return RunRewards(
    baseXp: totalBaseXp,
    jobXp: totalJobXp,
    gold: totalGold,
  );
}
