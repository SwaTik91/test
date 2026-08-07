import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/content/classes.dart';
import 'package:midgard_outpost/content/skills.dart';
import 'package:midgard_outpost/content/run_upgrades.dart';
import 'package:midgard_outpost/core/ids.dart';

void main() {
  test('each class has exactly 5 skills including one ultimate', () {
    for (final c in HeroClassId.values) {
      final skills = SkillsCatalog.forClass(c);
      expect(skills, hasLength(5));
      expect(skills.where((s) => s.kind == SkillKind.ultimate), hasLength(1));
    }
  });

  test('each skill has exactly 3 run upgrades', () {
    for (final skill in SkillsCatalog.all) {
      final ups = RunUpgradesCatalog.forSkill(skill.id);
      expect(ups, hasLength(3), reason: skill.id);
    }
  });

  test('general run upgrades pool has 18 entries', () {
    expect(
      RunUpgradesCatalog.all.where((u) => u.kind == RunUpgradeKind.general),
      hasLength(18),
    );
  });

  test('forClass returns only general + that class skill upgrades', () {
    final archerPool = RunUpgradesCatalog.forClass(HeroClassId.archer);
    expect(
      archerPool.every(
        (u) =>
            u.kind == RunUpgradeKind.general ||
            (u.skillId != null &&
                SkillsCatalog.byId(u.skillId!).classId == HeroClassId.archer),
      ),
      isTrue,
    );
    expect(archerPool.where((u) => u.kind == RunUpgradeKind.skill), hasLength(15));
  });
}
