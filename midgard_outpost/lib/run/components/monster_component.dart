import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../art/art_atlas.dart';
import '../../content/monsters.dart';
import '../../art/monster_anim_state.dart';
import '../sprite_fit.dart';
import 'player_component.dart';

typedef MonsterRangedAttack = void Function(MonsterComponent monster);

class MonsterComponent extends SpriteAnimationGroupComponent<MonsterAnimName> {
  MonsterComponent._({
    required this.kind,
    required this.target,
    required Vector2 position,
    required this.maxHp,
    required this.touchDamage,
    required this.baseXp,
    required this.jobXp,
    required this.gold,
    required this.tempXp,
    required this.upgradeDropChance,
    required this.isBoss,
    required this.moveSpeed,
    required this.attackRange,
    required this.attackInterval,
    required this.onRangedAttack,
    required double hurtDuration,
    required Map<MonsterAnimName, SpriteAnimation> animations,
    Vector2? footprintSize,
    Sprite? sourceSprite,
  }) : currentHp = maxHp,
       _hurtDuration = hurtDuration,
       _footprintSize = (footprintSize ?? Vector2(151, 151)).clone(),
       _sourceSprite = sourceSprite,
       super(
         animations: animations,
         current: MonsterAnimName.walk,
         position: position,
         size: (footprintSize ?? Vector2(151, 151)).clone(),
         anchor: Anchor.bottomCenter,
       ) {
    paint.color = Colors.white;
    ArtAtlas.applyNearestNeighbor(this);
    _baseGroundY = position.y;
    _attackCooldown = attackInterval * 0.35;
    _syncFrameAspectSize();
  }

  static const double _damageFlashDuration = 0.16;
  static const double _deathFlashDuration = 0.2;
  static const double _staticHurtDuration = 0.16;
  static const double _windupDuration = 0.28;
  static const double _walkBobAmplitude = 4;

  static Future<MonsterComponent> create({
    required MonsterKind kind,
    required bool isBoss,
    required PlayerComponent target,
    required Vector2 position,
    required int maxHp,
    required int touchDamage,
    required int baseXp,
    required int jobXp,
    required int gold,
    required int tempXp,
    required double upgradeDropChance,
    double moveSpeed = 58,
    double attackRange = 0,
    double attackInterval = 0,
    MonsterRangedAttack? onRangedAttack,
    Vector2? size,
  }) async {
    final sprite = await ArtAtlas.loadSprite(kind.spritePath);
    return MonsterComponent.forTest(
      kind: kind,
      target: target,
      position: position,
      sprite: sprite,
      maxHp: maxHp,
      touchDamage: touchDamage,
      baseXp: baseXp,
      jobXp: jobXp,
      gold: gold,
      tempXp: tempXp,
      upgradeDropChance: upgradeDropChance,
      isBoss: isBoss,
      moveSpeed: moveSpeed,
      attackRange: attackRange,
      attackInterval: attackInterval,
      onRangedAttack: onRangedAttack,
      size: size,
    );
  }

  @visibleForTesting
  factory MonsterComponent.forTest({
    required MonsterKind kind,
    required PlayerComponent target,
    required Vector2 position,
    required Sprite sprite,
    required int maxHp,
    required int touchDamage,
    required int baseXp,
    required int jobXp,
    required int gold,
    required int tempXp,
    required double upgradeDropChance,
    bool isBoss = false,
    double moveSpeed = 58,
    double attackRange = 0,
    double attackInterval = 0,
    MonsterRangedAttack? onRangedAttack,
    Vector2? size,
  }) {
    final staticAnim = SpriteAnimation.spriteList(
      [sprite],
      stepTime: 1.0,
      loop: true,
    );
    final animations = {
      MonsterAnimName.walk: staticAnim,
      MonsterAnimName.hurt: staticAnim,
    };
    return MonsterComponent._(
      kind: kind,
      target: target,
      position: position,
      maxHp: maxHp,
      touchDamage: touchDamage,
      baseXp: baseXp,
      jobXp: jobXp,
      gold: gold,
      tempXp: tempXp,
      upgradeDropChance: upgradeDropChance,
      isBoss: isBoss,
      moveSpeed: moveSpeed,
      attackRange: attackRange,
      attackInterval: attackInterval,
      onRangedAttack: onRangedAttack,
      hurtDuration: _staticHurtDuration,
      animations: animations,
      footprintSize: size,
      sourceSprite: sprite,
    );
  }

  final MonsterKind kind;
  final PlayerComponent target;
  final int maxHp;
  final int touchDamage;
  final int baseXp;
  final int jobXp;
  final int gold;
  final int tempXp;
  final double upgradeDropChance;
  final bool isBoss;
  final double moveSpeed;
  final double attackRange;
  final double attackInterval;
  final MonsterRangedAttack? onRangedAttack;

  final double _hurtDuration;
  final Vector2 _footprintSize;
  final Sprite? _sourceSprite;

  int currentHp;
  double _damageFlashSeconds = 0;
  double _deathFlashSeconds = 0;
  double _hurtTimer = 0;
  double _attackCooldown = 0;
  double _windupSeconds = 0;
  double _walkPhase = 0;
  double _baseGroundY = 0;

  bool get isAlive => currentHp > 0;

  bool get isRanged => attackRange > 0;

  bool get isTelegraphing => _windupSeconds > 0;

  bool get canCollect => !isAlive && _deathFlashSeconds <= 0;

  Rect get bounds => Rect.fromLTWH(
    position.x - _footprintSize.x * anchor.x,
    position.y - _footprintSize.y * anchor.y,
    _footprintSize.x,
    _footprintSize.y,
  );

  void takeDamage(int amount) {
    if (amount <= 0 || !isAlive) {
      return;
    }
    currentHp = (currentHp - amount).clamp(0, maxHp).toInt();
    _windupSeconds = 0;
    if (currentHp > 0) {
      _damageFlashSeconds = _damageFlashDuration;
      paint.color = Colors.orangeAccent;
      _playHurtAnimation();
      return;
    }

    _hurtTimer = 0;
    _damageFlashSeconds = 0;
    _deathFlashSeconds = _deathFlashDuration;
    paint.color = Colors.grey;
  }

  void _playHurtAnimation() {
    _hurtTimer = _hurtDuration;
    if (current == MonsterAnimName.hurt) {
      animationTicker?.reset();
      return;
    }
    current = MonsterAnimName.hurt;
  }

  void _syncFrameAspectSize() {
    final frame = animationTicker?.getSprite() ?? _sourceSprite;
    if (frame == null) {
      size.setFrom(_footprintSize);
      return;
    }
    size.setFrom(
      SpriteFit.containHeight(
        srcSize: frame.srcSize,
        targetHeight: _footprintSize.y,
      ),
    );
  }

  @override
  void onMount() {
    super.onMount();
    _baseGroundY = position.y;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_hurtTimer > 0) {
      _hurtTimer -= dt;
      if (_hurtTimer <= 0 && isAlive) {
        current = MonsterAnimName.walk;
      }
    }

    if (_damageFlashSeconds > 0) {
      _damageFlashSeconds -= dt;
      if (_damageFlashSeconds <= 0 && isAlive && !isTelegraphing) {
        paint.color = Colors.white;
      }
    }

    if (_deathFlashSeconds > 0) {
      _deathFlashSeconds -= dt;
    }

    if (!isAlive) {
      return;
    }

    final distanceToTarget = target.position.x - position.x;
    final absDistance = distanceToTarget.abs();

    if (distanceToTarget != 0) {
      scale.x = distanceToTarget.sign.toDouble();
    }

    if (_windupSeconds > 0) {
      _windupSeconds -= dt;
      if (_windupSeconds <= 0) {
        onRangedAttack?.call(this);
        paint.color = Colors.white;
      }
      return;
    }

    if (_attackCooldown > 0) {
      _attackCooldown -= dt;
    }

    final stopDistance = isRanged ? attackRange * 0.72 : 42;
    final isMoving = absDistance < 900 && absDistance > stopDistance;

    if (isRanged &&
        absDistance <= attackRange &&
        absDistance > stopDistance * 0.6 &&
        _attackCooldown <= 0) {
      _windupSeconds = _windupDuration;
      _attackCooldown = attackInterval;
      paint.color = Colors.amberAccent;
      return;
    }

    if (isMoving) {
      position.x += distanceToTarget.sign * moveSpeed * dt;
      _walkPhase += dt * 8;
      position.y = _baseGroundY + math.sin(_walkPhase) * _walkBobAmplitude;
    } else {
      position.y = _baseGroundY;
    }
  }
}
