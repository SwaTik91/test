import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class PlayerComponent extends RectangleComponent {
  PlayerComponent({
    required this.maxHp,
    required this.maxSp,
    required this.moveSpeed,
    required this.groundY,
  }) : currentHp = maxHp,
       currentSp = maxSp,
       super(
         position: Vector2(120, groundY - 56),
         size: Vector2(36, 56),
         paint: Paint()..color = Colors.lightBlueAccent,
       );

  static const double _gravity = 1200;
  static const double _jumpVelocity = -520;

  final int maxHp;
  final int maxSp;
  final double moveSpeed;
  final double groundY;

  int currentHp;
  int currentSp;

  double _horizontal = 0;
  double _verticalVelocity = 0;
  double _damageFlashSeconds = 0;

  bool get isDead => currentHp <= 0;

  bool get isGrounded => position.y >= groundY - size.y - 0.5;

  Rect get bounds => Rect.fromLTWH(position.x, position.y, size.x, size.y);

  void setHorizontal(double axis) {
    _horizontal = axis.clamp(-1, 1).toDouble();
  }

  void jump() {
    if (isGrounded) {
      _verticalVelocity = _jumpVelocity;
    }
  }

  void takeDamage(int amount) {
    if (amount <= 0 || isDead) {
      return;
    }
    currentHp = (currentHp - amount).clamp(0, maxHp).toInt();
    _damageFlashSeconds = 0.16;
    paint.color = Colors.redAccent;
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
    final floorY = groundY - size.y;
    if (position.y > floorY) {
      position.y = floorY;
      _verticalVelocity = 0;
    }

    if (_damageFlashSeconds > 0) {
      _damageFlashSeconds -= dt;
      if (_damageFlashSeconds <= 0) {
        paint.color = Colors.lightBlueAccent;
      }
    }
  }
}
