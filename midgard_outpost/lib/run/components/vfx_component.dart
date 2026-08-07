import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../art/animation_atlas.dart';
import '../../core/ids.dart';

enum VfxKind {
  slash,
  flame,
  holy,
}

class VfxComponent extends SpriteAnimationComponent {
  VfxComponent._({
    required SpriteAnimation animation,
    required Vector2 position,
    required Vector2 size,
    required double duration,
  }) : _duration = duration,
       super(
         animation: animation,
         position: position,
         size: size,
         anchor: Anchor.center,
       );

  static Future<VfxComponent?> create({
    required VfxKind kind,
    required Vector2 position,
    Vector2? size,
  }) async {
    try {
      final frames = _framesFor(kind);
      final animation = await AnimationAtlas.load(
        frames,
        AnimationAtlas.vfxStepTime,
        loop: false,
      );
      final duration = frames.length * AnimationAtlas.vfxStepTime;
      return VfxComponent._(
        animation: animation,
        position: position,
        size: size ?? Vector2.all(64),
        duration: duration,
      );
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'VfxComponent',
          context: ErrorDescription('while loading VFX for $kind'),
        ),
      );
      return null;
    }
  }

  static VfxKind forClass(HeroClassId classId) => switch (classId) {
        HeroClassId.archer => VfxKind.slash,
        HeroClassId.mage => VfxKind.flame,
        HeroClassId.paladin => VfxKind.holy,
      };

  static List<String> _framesFor(VfxKind kind) => switch (kind) {
        VfxKind.slash => AnimationAtlas.vfxSlashFrames,
        VfxKind.flame => AnimationAtlas.vfxFlameFrames,
        VfxKind.holy => AnimationAtlas.vfxHolyFrames,
      };

  @visibleForTesting
  factory VfxComponent.forTest({
    required SpriteAnimation animation,
    required Vector2 position,
    double duration = 0.24,
    Vector2? size,
  }) {
    return VfxComponent._(
      animation: animation,
      position: position,
      size: size ?? Vector2.all(64),
      duration: duration,
    );
  }

  final double _duration;
  double _elapsed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= _duration) {
      removeFromParent();
    }
  }
}
