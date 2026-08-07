import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/art/animation_atlas.dart';
import 'package:midgard_outpost/art/hero_anim_state.dart';
import 'package:midgard_outpost/core/ids.dart';

void main() {
  group('heroFrames', () {
    test('archer run has 4 frames with correct paths', () {
      final frames = AnimationAtlas.heroFrames(HeroClassId.archer, HeroAnimName.run);
      expect(frames, hasLength(4));
      expect(frames, [
        'heroes/archer/run_0.png',
        'heroes/archer/run_1.png',
        'heroes/archer/run_2.png',
        'heroes/archer/run_3.png',
      ]);
    });

    test('each hero class has expected frame counts per animation', () {
      for (final classId in HeroClassId.values) {
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

  group('enemy and prop frames', () {
    test('goblin walk and hurt frame counts', () {
      expect(AnimationAtlas.goblinWalkFrames, hasLength(3));
      expect(AnimationAtlas.goblinHurtFrames, hasLength(2));
    });

    test('ogre walk and hurt frame counts', () {
      expect(AnimationAtlas.ogreWalkFrames, hasLength(3));
      expect(AnimationAtlas.ogreHurtFrames, hasLength(2));
    });

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
      expect(AnimationAtlas.heroStepTime(HeroAnimName.idle), 0.35);
      expect(AnimationAtlas.heroStepTime(HeroAnimName.run), 0.10);
      expect(AnimationAtlas.heroStepTime(HeroAnimName.jump), 0.12);
      expect(AnimationAtlas.heroStepTime(HeroAnimName.cast), 0.08);
    });

    test('enemy, chest, and vfx stepTimes match design spec', () {
      expect(AnimationAtlas.goblinWalkStepTime, 0.12);
      expect(AnimationAtlas.goblinHurtStepTime, 0.08);
      expect(AnimationAtlas.ogreWalkStepTime, 0.14);
      expect(AnimationAtlas.ogreHurtStepTime, 0.08);
      expect(AnimationAtlas.chestOpenStepTime, 0.10);
      expect(AnimationAtlas.vfxStepTime, 0.08);
    });
  });

  test('allFramePaths lists every wave-2 frame without duplicates', () {
    expect(AnimationAtlas.allFramePaths, hasLength(55));
    expect(AnimationAtlas.allFramePaths.toSet(), hasLength(55));

    for (final classId in HeroClassId.values) {
      for (final anim in HeroAnimName.values) {
        for (final path in AnimationAtlas.heroFrames(classId, anim)) {
          expect(AnimationAtlas.allFramePaths, contains(path));
        }
      }
    }

    for (final path in [
      ...AnimationAtlas.goblinWalkFrames,
      ...AnimationAtlas.goblinHurtFrames,
      ...AnimationAtlas.ogreWalkFrames,
      ...AnimationAtlas.ogreHurtFrames,
      ...AnimationAtlas.chestOpenFrames,
      ...AnimationAtlas.vfxSlashFrames,
      ...AnimationAtlas.vfxFlameFrames,
      ...AnimationAtlas.vfxHolyFrames,
    ]) {
      expect(AnimationAtlas.allFramePaths, contains(path));
    }
  });
}
