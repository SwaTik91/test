import 'package:flame/components.dart';

import '../core/ids.dart';
import 'hero_anim_state.dart';

/// Wave 2 animation frame paths relative to [assetRoot] (`assets/images/`).
class AnimationAtlas {
  AnimationAtlas._();

  static const assetRoot = 'assets/images/';

  static const chestOpenStepTime = 0.10;
  static const vfxStepTime = 0.08;

  static List<String> get chestOpenFrames =>
      _frames('props/chest', 'open', 3);

  static List<String> get vfxSlashFrames => _frames('vfx', 'slash', 3);

  static List<String> get vfxFlameFrames => _frames('vfx', 'flame', 3);

  static List<String> get vfxHolyFrames => _frames('vfx', 'holy', 3);

  static List<String> heroFrames(HeroClassId classId, HeroAnimName anim) {
    final folder = _heroFolder(classId);
    final count = _heroFrameCount(classId, anim);
    return _frames('heroes/$folder', anim.name, count);
  }

  static int heroFrameCount(HeroClassId classId, HeroAnimName anim) =>
      _heroFrameCount(classId, anim);

  static double heroStepTime(HeroClassId classId, HeroAnimName anim) {
    if (classId == HeroClassId.archer && anim == HeroAnimName.cast) {
      // 8-frame draw cycle; faster step keeps cast pose ~0.40s (damage is instant).
      return 0.05;
    }
    return switch (anim) {
      HeroAnimName.idle => 0.35,
      HeroAnimName.run => 0.10,
      HeroAnimName.jump => 0.12,
      HeroAnimName.cast => 0.08,
    };
  }

  /// Every wave-2 animation frame path for asset-existence tests.
  static List<String> get allFramePaths => [
        for (final classId in HeroClassId.values)
          for (final anim in HeroAnimName.values)
            ...heroFrames(classId, anim),
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
    // Flame Images already prefixes `assets/images/` — do not prepend [assetRoot].
    final sprites = await Future.wait(
      frames.map(Sprite.load),
    );
    return SpriteAnimation.spriteList(
      sprites,
      stepTime: stepTime,
      loop: loop,
    );
  }

  static int _heroFrameCount(HeroClassId classId, HeroAnimName anim) {
    if (classId == HeroClassId.archer) {
      return switch (anim) {
        HeroAnimName.idle => 4,
        HeroAnimName.run => 8,
        HeroAnimName.jump => 6,
        HeroAnimName.cast => 8,
      };
    }
    return switch (anim) {
      HeroAnimName.idle => 2,
      HeroAnimName.run => 4,
      HeroAnimName.jump => 2,
      HeroAnimName.cast => 3,
    };
  }

  static String _heroFolder(HeroClassId id) => switch (id) {
        HeroClassId.archer => 'archer',
        HeroClassId.mage => 'mage',
        HeroClassId.paladin => 'paladin',
      };

  static List<String> _frames(String folder, String prefix, int count) =>
      List.generate(count, (i) => '$folder/${prefix}_$i.png');
}
