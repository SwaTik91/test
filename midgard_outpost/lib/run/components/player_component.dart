import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../art/animation_atlas.dart';
import '../../art/art_atlas.dart';
import '../../art/hero_anim_state.dart';
import '../../core/ids.dart';
import '../sprite_fit.dart';

class PlayerComponent extends SpriteAnimationGroupComponent<HeroAnimName> {
  /// Default spawn X — keep in sync with run ground strip layout.
  static const double startX = 120;

  PlayerComponent._({
    required this.maxHp,
    required this.maxSp,
    required this.moveSpeed,
    required this.groundY,
    required Vector2 footprintSize,
    required Map<HeroAnimName, SpriteAnimation> animations,
    required double castDuration,
  }) : currentHp = maxHp,
       currentSp = maxSp,
       _footprintSize = footprintSize.clone(),
       _castDuration = castDuration,
       super(
         animations: animations,
         current: HeroAnimName.idle,
         position: Vector2(startX, groundY),
         size: footprintSize.clone(),
         anchor: Anchor.bottomCenter,
         autoResize: false,
       ) {
    paint.color = Colors.white;
    paint.filterQuality = FilterQuality.low;
    _rebuildAnimRenderSizes(animations);
    _syncFrameAspectSize();
  }

  static const double _gravity = 1200;
  static const double _jumpVelocity = -520;

  static double castDurationFor(HeroClassId classId) =>
      AnimationAtlas.heroFrameCount(classId, HeroAnimName.cast) *
      AnimationAtlas.heroStepTime(classId, HeroAnimName.cast);

  static Future<PlayerComponent> create({
    required HeroClassId classId,
    required int maxHp,
    required int maxSp,
    required double moveSpeed,
    required double groundY,
    required Vector2 size,
  }) async {
    final animations = await _loadAnimations(classId);
    return PlayerComponent._(
      maxHp: maxHp,
      maxSp: maxSp,
      moveSpeed: moveSpeed,
      groundY: groundY,
      footprintSize: size,
      animations: animations,
      castDuration: castDurationFor(classId),
    );
  }

  static Future<Map<HeroAnimName, SpriteAnimation>> _loadAnimations(
    HeroClassId classId,
  ) async {
    try {
      final animations = <HeroAnimName, SpriteAnimation>{};
      for (final anim in HeroAnimName.values) {
        animations[anim] = await AnimationAtlas.load(
          AnimationAtlas.heroFrames(classId, anim),
          AnimationAtlas.heroStepTime(classId, anim),
          loop: anim != HeroAnimName.cast,
        );
      }
      return animations;
    } catch (_) {
      return _staticFallbackAnimations(classId);
    }
  }

  static Future<Map<HeroAnimName, SpriteAnimation>> _staticFallbackAnimations(
    HeroClassId classId,
  ) async {
    final sprite = await ArtAtlas.loadSprite(ArtAtlas.heroPath(classId));
    return _singleSpriteAnimations(sprite);
  }

  static Map<HeroAnimName, SpriteAnimation> _singleSpriteAnimations(
    Sprite sprite,
  ) {
    final staticAnim = SpriteAnimation.spriteList(
      [sprite],
      stepTime: 1.0,
      loop: true,
    );
    return {for (final anim in HeroAnimName.values) anim: staticAnim};
  }

  @visibleForTesting
  PlayerComponent.forTest({
    required this.groundY,
    required Sprite sprite,
    Vector2? position,
    Vector2? size,
    int maxHp = 100,
    int maxSp = 50,
    double moveSpeed = 200,
  }) : maxHp = maxHp,
       maxSp = maxSp,
       moveSpeed = moveSpeed,
       currentHp = maxHp,
       currentSp = maxSp,
       _footprintSize = (size ?? Vector2(216, 216)).clone(),
       _castDuration = 0.24,
       super(
         animations: _singleSpriteAnimations(sprite),
         current: HeroAnimName.idle,
         position: position ?? Vector2(startX, groundY),
         size: (size ?? Vector2(216, 216)).clone(),
         anchor: Anchor.bottomCenter,
         autoResize: false,
       ) {
    paint.color = Colors.white;
    paint.filterQuality = FilterQuality.low;
    _rebuildAnimRenderSizes(_singleSpriteAnimations(sprite));
    _syncFrameAspectSize();
  }

  @visibleForTesting
  PlayerComponent.forTestWithAnimations({
    required this.groundY,
    required Map<HeroAnimName, SpriteAnimation> animations,
    Vector2? position,
    Vector2? size,
    int maxHp = 100,
    int maxSp = 50,
    double moveSpeed = 200,
    HeroAnimName current = HeroAnimName.idle,
  }) : maxHp = maxHp,
       maxSp = maxSp,
       moveSpeed = moveSpeed,
       currentHp = maxHp,
       currentSp = maxSp,
       _footprintSize = (size ?? Vector2(216, 216)).clone(),
       _castDuration = 0.24,
       super(
         animations: animations,
         current: current,
         position: position ?? Vector2(startX, groundY),
         size: (size ?? Vector2(216, 216)).clone(),
         anchor: Anchor.bottomCenter,
         autoResize: false,
       ) {
    paint.color = Colors.white;
    paint.filterQuality = FilterQuality.low;
    _rebuildAnimRenderSizes(animations);
    _syncFrameAspectSize();
  }

  final Vector2 _footprintSize;
  final Map<HeroAnimName, Vector2> _animRenderSizes = {};
  final double _castDuration;

  int maxHp;
  int maxSp;
  double moveSpeed;
  double groundY;

  int currentHp;
  int currentSp;

  double _horizontal = 0;
  double _verticalVelocity = 0;
  double _damageFlashSeconds = 0;
  double _castTimer = 0;

  bool get isDead => currentHp <= 0;

  bool get isGrounded => position.y >= groundY - 0.5;

  Rect get bounds => Rect.fromLTWH(
    position.x - _footprintSize.x * anchor.x,
    position.y - _footprintSize.y * anchor.y,
    _footprintSize.x,
    _footprintSize.y,
  );

  Vector2 get footprintSize => _footprintSize;

  void setHorizontal(double axis) {
    _horizontal = axis.clamp(-1, 1).toDouble();
  }

  bool jump() {
    if (isGrounded) {
      _verticalVelocity = _jumpVelocity;
      return true;
    }
    return false;
  }

  void playCastAnimation() {
    _castTimer = _castDuration;
  }

  void takeDamage(int amount) {
    if (amount <= 0 || isDead) {
      return;
    }
    currentHp = (currentHp - amount).clamp(0, maxHp).toInt();
    _damageFlashSeconds = 0.16;
    paint.color = Colors.redAccent;
  }

  void heal(int amount) {
    if (amount <= 0 || isDead) {
      return;
    }
    currentHp = (currentHp + amount).clamp(0, maxHp).toInt();
  }

  void setSp(int amount) {
    currentSp = amount.clamp(0, maxSp).toInt();
  }

  void setMaxHp(int value) {
    final previousMaxHp = maxHp;
    maxHp = value;
    if (maxHp > previousMaxHp) {
      currentHp += maxHp - previousMaxHp;
    }
    currentHp = currentHp.clamp(0, maxHp).toInt();
  }

  void setMaxSp(int value) {
    final previousMaxSp = maxSp;
    maxSp = value;
    if (maxSp > previousMaxSp) {
      currentSp += maxSp - previousMaxSp;
    }
    currentSp = currentSp.clamp(0, maxSp).toInt();
  }

  void setMoveSpeed(double value) {
    moveSpeed = value;
  }

  void setGroundY(double value) {
    final wasGrounded = isGrounded;
    groundY = value;
    if (wasGrounded || position.y > groundY) {
      position.y = groundY;
    }
  }

  void setSize(Vector2 value) {
    _footprintSize.setFrom(value);
    final anims = animations;
    if (anims != null) {
      _rebuildAnimRenderSizes(anims);
    }
    _syncFrameAspectSize();
  }

  @override
  void onMount() {
    super.onMount();
    _syncFrameAspectSize();
  }

  void _rebuildAnimRenderSizes(Map<HeroAnimName, SpriteAnimation> anims) {
    _animRenderSizes.clear();
    for (final entry in anims.entries) {
      _animRenderSizes[entry.key] = SpriteFit.stableContainHeight(
        animation: entry.value,
        targetHeight: _footprintSize.y,
      );
    }
  }

  void _syncFrameAspectSize() {
    final renderSize = _animRenderSizes[current];
    if (renderSize != null) {
      size.setFrom(renderSize);
      return;
    }
    size.setFrom(_footprintSize);
  }

  static const double _runAnimSpeedThreshold = 12;

  @override
  void update(double dt) {
    super.update(dt);
    position.x += _horizontal * moveSpeed * dt;
    if (position.x < 0) {
      position.x = 0;
    }

    _verticalVelocity += _gravity * dt;
    position.y += _verticalVelocity * dt;
    final floorY = groundY;
    if (position.y > floorY) {
      position.y = floorY;
      _verticalVelocity = 0;
    }

    if (_castTimer > 0) {
      _castTimer = (_castTimer - dt).clamp(0, double.infinity).toDouble();
    }

    final anim = selectHeroAnim(
      grounded: isGrounded,
      vx: _horizontal * moveSpeed,
      casting: _castTimer > 0,
      runSpeedThreshold: _runAnimSpeedThreshold,
    );
    if (current != anim) {
      current = anim;
      _syncFrameAspectSize();
    }

    if (_damageFlashSeconds > 0) {
      _damageFlashSeconds -= dt;
      if (_damageFlashSeconds <= 0) {
        paint.color = Colors.white;
      }
    }
  }
}
