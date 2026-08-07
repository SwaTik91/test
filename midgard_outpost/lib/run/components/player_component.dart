import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../art/art_atlas.dart';
import '../../core/ids.dart';

class PlayerComponent extends SpriteComponent {
  PlayerComponent._({
    required this.maxHp,
    required this.maxSp,
    required this.moveSpeed,
    required this.groundY,
    required Sprite sprite,
  }) : currentHp = maxHp,
       currentSp = maxSp,
       super(
         sprite: sprite,
         position: Vector2(120, groundY),
         size: Vector2(48, 64),
         anchor: Anchor.bottomCenter,
       ) {
    paint.color = Colors.white;
  }

  static Future<PlayerComponent> create({
    required HeroClassId classId,
    required int maxHp,
    required int maxSp,
    required double moveSpeed,
    required double groundY,
  }) async {
    final sprite = await ArtAtlas.loadSprite(ArtAtlas.heroPath(classId));
    return PlayerComponent._(
      maxHp: maxHp,
      maxSp: maxSp,
      moveSpeed: moveSpeed,
      groundY: groundY,
      sprite: sprite,
    );
  }

  static const double _gravity = 1200;
  static const double _jumpVelocity = -520;

  int maxHp;
  int maxSp;
  double moveSpeed;
  final double groundY;

  int currentHp;
  int currentSp;

  double _horizontal = 0;
  double _verticalVelocity = 0;
  double _damageFlashSeconds = 0;

  bool get isDead => currentHp <= 0;

  bool get isGrounded => position.y >= groundY - size.y - 0.5;

  Rect get bounds => Rect.fromLTWH(
    position.x - size.x * anchor.x,
    position.y - size.y * anchor.y,
    size.x,
    size.y,
  );

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

    if (_damageFlashSeconds > 0) {
      _damageFlashSeconds -= dt;
      if (_damageFlashSeconds <= 0) {
        paint.color = Colors.white;
      }
    }
  }
}
