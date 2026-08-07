import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'player_component.dart';

class MonsterComponent extends SpriteComponent {
  MonsterComponent({
    required Sprite sprite,
    required this.target,
    required Vector2 position,
    required this.maxHp,
    required this.touchDamage,
    required this.baseXp,
    required this.jobXp,
    required this.gold,
    required this.tempXp,
    required this.upgradeDropChance,
    this.isBoss = false,
    this.moveSpeed = 58,
    Vector2? size,
  }) : currentHp = maxHp,
       super(
         sprite: sprite,
         position: position,
         size: size ?? Vector2(40, 44),
       ) {
    paint.color = Colors.white;
  }

  static const double _damageFlashDuration = 0.16;
  static const double _deathFlashDuration = 0.2;

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

  int currentHp;
  double _damageFlashSeconds = 0;
  double _deathFlashSeconds = 0;

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
      return;
    }

    _damageFlashSeconds = 0;
    _deathFlashSeconds = _deathFlashDuration;
    paint.color = Colors.grey;
  }

  @override
  void update(double dt) {
    super.update(dt);

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
