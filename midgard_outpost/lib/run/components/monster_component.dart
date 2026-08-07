import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../art/animation_atlas.dart';
import '../../art/art_atlas.dart';
import '../../art/monster_anim_state.dart';
import 'player_component.dart';

class MonsterComponent extends SpriteAnimationGroupComponent<MonsterAnimName> {
  MonsterComponent._({
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
    required double hurtDuration,
    required Map<MonsterAnimName, SpriteAnimation> animations,
    Vector2? size,
  }) : currentHp = maxHp,
       _hurtDuration = hurtDuration,
       super(
         animations: animations,
         current: MonsterAnimName.walk,
         position: position,
         size: size ?? Vector2(40, 44),
       ) {
    paint.color = Colors.white;
  }

  static const double _damageFlashDuration = 0.16;
  static const double _deathFlashDuration = 0.2;

  static Future<MonsterComponent> create({
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
    Vector2? size,
  }) async {
    try {
      final animations = await _loadAnimations(isBoss);
      final hurtDuration = _hurtDurationFor(isBoss);
      return MonsterComponent._(
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
        hurtDuration: hurtDuration,
        animations: animations,
        size: size,
      );
    } catch (_) {
      final sprite = await ArtAtlas.loadSprite(
        isBoss ? ArtAtlas.bossOgre : ArtAtlas.mobGoblin,
      );
      return MonsterComponent.forTest(
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
        size: size,
      );
    }
  }

  static Future<Map<MonsterAnimName, SpriteAnimation>> _loadAnimations(
    bool isBoss,
  ) async {
    final walkFrames = isBoss
        ? AnimationAtlas.ogreWalkFrames
        : AnimationAtlas.goblinWalkFrames;
    final hurtFrames = isBoss
        ? AnimationAtlas.ogreHurtFrames
        : AnimationAtlas.goblinHurtFrames;
    final walkStepTime = isBoss
        ? AnimationAtlas.ogreWalkStepTime
        : AnimationAtlas.goblinWalkStepTime;
    final hurtStepTime = isBoss
        ? AnimationAtlas.ogreHurtStepTime
        : AnimationAtlas.goblinHurtStepTime;

    return {
      MonsterAnimName.walk: await AnimationAtlas.load(
        walkFrames,
        walkStepTime,
      ),
      MonsterAnimName.hurt: await AnimationAtlas.load(
        hurtFrames,
        hurtStepTime,
        loop: false,
      ),
    };
  }

  static double _hurtDurationFor(bool isBoss) {
    final frames = isBoss
        ? AnimationAtlas.ogreHurtFrames
        : AnimationAtlas.goblinHurtFrames;
    final stepTime = isBoss
        ? AnimationAtlas.ogreHurtStepTime
        : AnimationAtlas.goblinHurtStepTime;
    return frames.length * stepTime;
  }

  @visibleForTesting
  factory MonsterComponent.forTest({
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
      hurtDuration: 0.16,
      animations: animations,
      size: size,
    );
  }

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

  final double _hurtDuration;

  int currentHp;
  double _damageFlashSeconds = 0;
  double _deathFlashSeconds = 0;
  double _hurtTimer = 0;

  bool get isAlive => currentHp > 0;

  bool get canCollect => !isAlive && _deathFlashSeconds <= 0;

  Rect get bounds => Rect.fromLTWH(position.x, position.y, size.x, size.y);

  void takeDamage(int amount) {
    if (amount <= 0 || !isAlive) {
      return;
    }
    currentHp = (currentHp - amount).clamp(0, maxHp).toInt();
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
      if (_damageFlashSeconds <= 0 && isAlive) {
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
    if (distanceToTarget.abs() < 900 && distanceToTarget.abs() > 42) {
      position.x += distanceToTarget.sign * moveSpeed * dt;
    }
  }
}
