import 'package:flame/components.dart';

import '../core/ids.dart';
import 'hero_anim_state.dart';

/// Wave 2 animation frame paths relative to [assetRoot] (`assets/images/`).
class AnimationAtlas {
  AnimationAtlas._();

  static const assetRoot = 'assets/images/';

  static const goblinWalkStepTime = 0.12;
  static const goblinHurtStepTime = 0.08;
  static const ogreWalkStepTime = 0.14;
  static const ogreHurtStepTime = 0.08;
  static const chestOpenStepTime = 0.10;
  static const vfxStepTime = 0.08;

  static List<String> get goblinWalkFrames =>
      _frames('enemies/goblin', 'walk', 3);

  static List<String> get goblinHurtFrames =>
      _frames('enemies/goblin', 'hurt', 2);

  static List<String> get ogreWalkFrames => _frames('enemies/ogre', 'walk', 3);

  static List<String> get ogreHurtFrames => _frames('enemies/ogre', 'hurt', 2);

  static List<String> get chestOpenFrames =>
      _frames('props/chest', 'open', 3);

  static List<String> get vfxSlashFrames => _frames('vfx', 'slash', 3);

  static List<String> get vfxFlameFrames => _frames('vfx', 'flame', 3);

  static List<String> get vfxHolyFrames => _frames('vfx', 'holy', 3);

  static List<String> heroFrames(HeroClassId classId, HeroAnimName anim) {
    final folder = _heroFolder(classId);
    return switch (anim) {
      HeroAnimName.idle => _frames('heroes/$folder', 'idle', 2),
      HeroAnimName.run => _frames('heroes/$folder', 'run', 4),
      HeroAnimName.jump => _frames('heroes/$folder', 'jump', 2),
      HeroAnimName.cast => _frames('heroes/$folder', 'cast', 3),
    };
  }

  static double heroStepTime(HeroAnimName anim) => switch (anim) {
        HeroAnimName.idle => 0.35,
        HeroAnimName.run => 0.10,
        HeroAnimName.jump => 0.12,
        HeroAnimName.cast => 0.08,
      };

  /// Every wave-2 animation frame path for asset-existence tests.
  static List<String> get allFramePaths => [
        for (final classId in HeroClassId.values)
          for (final anim in HeroAnimName.values)
            ...heroFrames(classId, anim),
        ...goblinWalkFrames,
        ...goblinHurtFrames,
        ...ogreWalkFrames,
        ...ogreHurtFrames,
        ...chestOpenFrames,
        ...vfxSlashFrames,
        ...vfxFlameFrames,
        ...vfxHolyFrames,
      ];

  static Future<SpriteAnimation> load(
    List<String> frames,
    double stepTime, {
    bool loop = true,
  }) async {
    final sprites = await Future.wait(
      frames.map((path) => Sprite.load('$assetRoot$path')),
    );
    return SpriteAnimation.spriteList(
      sprites,
      stepTime: stepTime,
      loop: loop,
    );
  }

  static String _heroFolder(HeroClassId id) => switch (id) {
        HeroClassId.archer => 'archer',
        HeroClassId.mage => 'mage',
        HeroClassId.paladin => 'paladin',
      };

  static List<String> _frames(String folder, String prefix, int count) =>
      List.generate(count, (i) => '$folder/${prefix}_$i.png');
}
