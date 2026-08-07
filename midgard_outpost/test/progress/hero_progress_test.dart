import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/core/ids.dart';
import 'package:midgard_outpost/progress/hero_progress.dart';
import 'package:midgard_outpost/progress/progress_service.dart';
import 'package:midgard_outpost/progress/stats.dart';
import 'package:midgard_outpost/run/run_rewards.dart';

void main() {
  test('new hero starts at base/job 1 with zero unspent points', () {
    final hero = HeroProgress.createNew(HeroClassId.archer);
    expect(hero.baseLevel, 1);
    expect(hero.jobLevel, 1);
    expect(hero.unspentStatPoints, 0);
    expect(hero.unspentSkillPoints, 0);
    expect(hero.stats[StatId.str], 1);
  });

  test('run rewards can level base and grant stat points', () {
    var hero = HeroProgress.createNew(HeroClassId.mage);
    final need = ProgressService.xpToNextBase(hero.baseLevel);
    hero = ProgressService.applyRunRewards(
      hero,
      RunRewards(baseXp: need, jobXp: 0, gold: 10),
    );
    expect(hero.baseLevel, 2);
    expect(hero.unspentStatPoints, 1);
    expect(hero.gold, 10);
  });

  test('allocateStat spends one point', () {
    var hero = HeroProgress.createNew(HeroClassId.paladin)
        .copyWith(unspentStatPoints: 1);
    hero = ProgressService.allocateStat(hero, StatId.vit);
    expect(hero.unspentStatPoints, 0);
    expect(hero.stats[StatId.vit], 2);
  });

  test('allocateSkill increases rank and spends job point', () {
    var hero = HeroProgress.createNew(HeroClassId.archer)
        .copyWith(unspentSkillPoints: 1);
    hero = ProgressService.allocateSkill(hero, 'double_strafe');
    expect(hero.unspentSkillPoints, 0);
    expect(hero.skillRanks['double_strafe'], 1);
  });

  test('temp run upgrades are not stored on HeroProgress', () {
    final hero = HeroProgress.createNew(HeroClassId.archer);
    // compile-time / API check: no field for run upgrades on meta hero
    expect(hero.toJson().containsKey('activeRunUpgrades'), isFalse);
  });
}
