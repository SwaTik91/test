import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/core/ids.dart';
import 'package:midgard_outpost/progress/hero_progress.dart';
import 'package:midgard_outpost/progress/progress_service.dart';
import 'package:midgard_outpost/run/run_rewards.dart';

void main() {
  test('xpToNextBase follows curve', () {
    expect(ProgressService.xpToNextBase(1), 27);
    expect(ProgressService.xpToNextBase(5), 75);
  });

  test('xpToNextJob follows curve', () {
    expect(ProgressService.xpToNextJob(1), 22);
    expect(ProgressService.xpToNextJob(5), 62);
  });

  test('run rewards can grant multiple base levels at once', () {
    var hero = HeroProgress.createNew(HeroClassId.archer);
    final level1 = ProgressService.xpToNextBase(1);
    final level2 = ProgressService.xpToNextBase(2);
    hero = ProgressService.applyRunRewards(
      hero,
      RunRewards(baseXp: level1 + level2, jobXp: 0, gold: 0),
    );
    expect(hero.baseLevel, 3);
    expect(hero.unspentStatPoints, 2);
  });

  test('job xp levels job and grants skill points', () {
    var hero = HeroProgress.createNew(HeroClassId.mage);
    final need = ProgressService.xpToNextJob(hero.jobLevel);
    hero = ProgressService.applyRunRewards(
      hero,
      RunRewards(baseXp: 0, jobXp: need, gold: 0),
    );
    expect(hero.jobLevel, 2);
    expect(hero.unspentSkillPoints, 1);
  });

  test('active base/job xp boost multiplies applied run rewards', () {
    final hero = HeroProgress.createNew(HeroClassId.mage).copyWith(
      activeBoosts: {
        'boost_base_job_xp': DateTime(2099).millisecondsSinceEpoch,
      },
    );

    final updated = ProgressService.applyRunRewards(
      hero,
      const RunRewards(baseXp: 10, jobXp: 10, gold: 5),
    );

    expect(updated.baseXp, 15);
    expect(updated.jobXp, 15);
    expect(updated.gold, 5);
  });

  test('expired base/job xp boost does not affect applied run rewards', () {
    final hero = HeroProgress.createNew(HeroClassId.mage).copyWith(
      activeBoosts: {
        'boost_base_job_xp': DateTime(2000).millisecondsSinceEpoch,
      },
    );

    final updated = ProgressService.applyRunRewards(
      hero,
      const RunRewards(baseXp: 10, jobXp: 10, gold: 5),
    );

    expect(updated.baseXp, 10);
    expect(updated.jobXp, 10);
  });

  test('grantDebugLevels adds 10 base and 10 job levels with points', () {
    final hero = HeroProgress.createNew(HeroClassId.archer);
    final updated = ProgressService.grantDebugLevels(hero);
    expect(updated.baseLevel, 11);
    expect(updated.jobLevel, 11);
    expect(updated.unspentStatPoints, 10);
    expect(updated.unspentSkillPoints, 10);
  });

  test('toJson roundtrips through fromJson', () {
    final original = HeroProgress.createNew(HeroClassId.paladin).copyWith(
      gold: 100,
      crystals: 5,
      unspentStatPoints: 2,
      activeBoosts: const {'boost_drop': 1_700_000_000_000},
    );
    final restored = HeroProgress.fromJson(original.toJson());
    expect(restored.classId, original.classId);
    expect(restored.baseLevel, original.baseLevel);
    expect(restored.gold, original.gold);
    expect(restored.crystals, original.crystals);
    expect(restored.unspentStatPoints, original.unspentStatPoints);
    expect(restored.activeBoosts, original.activeBoosts);
  });
}
