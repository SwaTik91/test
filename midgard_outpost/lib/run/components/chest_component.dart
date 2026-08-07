import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../art/animation_atlas.dart';
import '../../art/art_atlas.dart';

enum ChestAnimName {
  closed,
  open,
}

class ChestComponent extends SpriteAnimationGroupComponent<ChestAnimName> {
  ChestComponent._({
    required Vector2 position,
    required Map<ChestAnimName, SpriteAnimation> animations,
    required double openDuration,
  }) : _openDuration = openDuration,
       super(
         animations: animations,
         current: ChestAnimName.closed,
         position: position,
         size: Vector2(42, 34),
       );

  static Future<ChestComponent> create({required Vector2 position}) async {
    try {
      final animations = await _loadAnimations();
      final openDuration =
          AnimationAtlas.chestOpenFrames.length *
          AnimationAtlas.chestOpenStepTime;
      return ChestComponent._(
        position: position,
        animations: animations,
        openDuration: openDuration,
      );
    } catch (_) {
      final sprite = await ArtAtlas.loadSprite(ArtAtlas.chest);
      return ChestComponent.forTest(position: position, sprite: sprite);
    }
  }

  static Future<Map<ChestAnimName, SpriteAnimation>> _loadAnimations() async {
    final closedSprite = await ArtAtlas.loadSprite(ArtAtlas.chest);
    final closedAnim = SpriteAnimation.spriteList(
      [closedSprite],
      stepTime: 1.0,
      loop: true,
    );
    final openAnim = await AnimationAtlas.load(
      AnimationAtlas.chestOpenFrames,
      AnimationAtlas.chestOpenStepTime,
      loop: false,
    );
    return {ChestAnimName.closed: closedAnim, ChestAnimName.open: openAnim};
  }

  @visibleForTesting
  factory ChestComponent.forTest({
    required Vector2 position,
    required Sprite sprite,
  }) {
    final staticAnim = SpriteAnimation.spriteList(
      [sprite],
      stepTime: 1.0,
      loop: true,
    );
    final animations = {
      ChestAnimName.closed: staticAnim,
      ChestAnimName.open: staticAnim,
    };
    return ChestComponent._(
      position: position,
      animations: animations,
      openDuration: 0.30,
    );
  }

  final double _openDuration;

  bool isCollected = false;
  double _openTimer = 0;

  Rect get bounds => Rect.fromLTWH(position.x, position.y, size.x, size.y);

  void collect() {
    if (isCollected) {
      return;
    }
    isCollected = true;
    current = ChestAnimName.open;
    _openTimer = _openDuration;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_openTimer <= 0) {
      return;
    }

    _openTimer -= dt;
    if (_openTimer <= 0) {
      removeFromParent();
    }
  }
}
