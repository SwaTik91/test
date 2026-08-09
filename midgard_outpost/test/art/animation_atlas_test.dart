import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/art/animation_atlas.dart';
import 'package:midgard_outpost/art/hero_anim_state.dart';
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
        hasLength(4),
      );
      expect(
        AnimationAtlas.heroFrames(HeroClassId.archer, HeroAnimName.cast),
        hasLength(6),
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

  group('prop frames', () {
    test('chest open has 3 frames', () {
      expect(AnimationAtlas.chestOpenFrames, hasLength(3));
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

    test('archer cast uses faster step for 6-frame draw cycle', () {
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
    expect(AnimationAtlas.allFramePaths, hasLength(56));
    expect(AnimationAtlas.allFramePaths.toSet(), hasLength(56));

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
  });
}
