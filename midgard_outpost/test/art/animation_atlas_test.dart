import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/art/animation_atlas.dart';
import 'package:midgard_outpost/art/hero_anim_state.dart';
import 'package:midgard_outpost/content/monsters.dart';
import 'package:midgard_outpost/core/ids.dart';

void main() {
  group('heroFrames', () {
    test('archer run has 8 frames with correct paths', () {
      final frames = AnimationAtlas.heroFrames(HeroClassId.archer, HeroAnimName.run);
      expect(frames, hasLength(8));
      expect(frames, [
        'heroes/archer/run_0.png',
        'heroes/archer/run_1.png',
        'heroes/archer/run_2.png',
        'heroes/archer/run_3.png',
        'heroes/archer/run_4.png',
        'heroes/archer/run_5.png',
        'heroes/archer/run_6.png',
        'heroes/archer/run_7.png',
      ]);
    });

    test('archer has expanded frame counts', () {
      expect(
        AnimationAtlas.heroFrames(HeroClassId.archer, HeroAnimName.idle),
        hasLength(4),
      );
      expect(
        AnimationAtlas.heroFrames(HeroClassId.archer, HeroAnimName.run),
        hasLength(8),
      );
      expect(
        AnimationAtlas.heroFrames(HeroClassId.archer, HeroAnimName.jump),
        hasLength(6),
      );
      expect(
        AnimationAtlas.heroFrames(HeroClassId.archer, HeroAnimName.cast),
        hasLength(8),
      );
    });

    test('mage and paladin keep legacy frame counts', () {
      for (final classId in [HeroClassId.mage, HeroClassId.paladin]) {
        expect(
          AnimationAtlas.heroFrames(classId, HeroAnimName.idle),
          hasLength(2),
        );
        expect(
          AnimationAtlas.heroFrames(classId, HeroAnimName.run),
          hasLength(4),
        );
        expect(
          AnimationAtlas.heroFrames(classId, HeroAnimName.jump),
          hasLength(2),
        );
        expect(
          AnimationAtlas.heroFrames(classId, HeroAnimName.cast),
          hasLength(3),
        );
      }
    });
  });

  group('monster walk frames', () {
    test('slime walk has 6 frames with correct paths', () {
      final frames = AnimationAtlas.monsterWalkFrames(MonsterKind.slime);
      expect(frames, hasLength(6));
      expect(frames, [
        'enemies/slime/walk_0.png',
        'enemies/slime/walk_1.png',
        'enemies/slime/walk_2.png',
        'enemies/slime/walk_3.png',
        'enemies/slime/walk_4.png',
        'enemies/slime/walk_5.png',
      ]);
      expect(AnimationAtlas.monsterHasWalkFrames(MonsterKind.slime), isTrue);
    });

    test('all monster kinds have 6 walk frames', () {
      for (final kind in MonsterKind.values) {
        final frames = AnimationAtlas.monsterWalkFrames(kind);
        expect(frames, hasLength(6), reason: '$kind walk frame count');
        expect(AnimationAtlas.monsterHasWalkFrames(kind), isTrue);
        for (var i = 0; i < 6; i++) {
          expect(frames[i], endsWith('/walk_$i.png'));
        }
      }
    });
  });

  group('prop frames', () {
    test('chest open has 5 frames', () {
      expect(AnimationAtlas.chestOpenFrames, hasLength(5));
      expect(AnimationAtlas.chestOpenFrames, [
        'props/chest/open_0.png',
        'props/chest/open_1.png',
        'props/chest/open_2.png',
        'props/chest/open_3.png',
        'props/chest/open_4.png',
      ]);
    });
  });

  group('vfx frames', () {
    test('each vfx animation has 3 frames', () {
      expect(AnimationAtlas.vfxSlashFrames, hasLength(3));
      expect(AnimationAtlas.vfxFlameFrames, hasLength(3));
      expect(AnimationAtlas.vfxHolyFrames, hasLength(3));
    });
  });

  group('stepTime', () {
    test('hero stepTimes match design spec', () {
      expect(
        AnimationAtlas.heroStepTime(HeroClassId.mage, HeroAnimName.idle),
        0.35,
      );
      expect(
        AnimationAtlas.heroStepTime(HeroClassId.mage, HeroAnimName.run),
        0.10,
      );
      expect(
        AnimationAtlas.heroStepTime(HeroClassId.mage, HeroAnimName.jump),
        0.12,
      );
      expect(
        AnimationAtlas.heroStepTime(HeroClassId.mage, HeroAnimName.cast),
        0.08,
      );
    });

    test('archer cast uses faster step for 8-frame draw cycle', () {
      expect(
        AnimationAtlas.heroStepTime(HeroClassId.archer, HeroAnimName.cast),
        0.05,
      );
    });

    test('chest and vfx stepTimes match design spec', () {
      expect(AnimationAtlas.chestOpenStepTime, 0.10);
      expect(AnimationAtlas.vfxStepTime, 0.08);
    });
  });

  test('allFramePaths lists every animation frame without duplicates', () {
    expect(AnimationAtlas.allFramePaths, hasLength(134));
    expect(AnimationAtlas.allFramePaths.toSet(), hasLength(134));

    for (final classId in HeroClassId.values) {
      for (final anim in HeroAnimName.values) {
        for (final path in AnimationAtlas.heroFrames(classId, anim)) {
          expect(AnimationAtlas.allFramePaths, contains(path));
        }
      }
    }

    for (final path in [
      ...AnimationAtlas.chestOpenFrames,
      ...AnimationAtlas.vfxSlashFrames,
      ...AnimationAtlas.vfxFlameFrames,
      ...AnimationAtlas.vfxHolyFrames,
    ]) {
      expect(AnimationAtlas.allFramePaths, contains(path));
    }

    for (final kind in MonsterKind.values) {
      for (final path in AnimationAtlas.monsterWalkFrames(kind)) {
        expect(AnimationAtlas.allFramePaths, contains(path));
      }
    }
  });
}
