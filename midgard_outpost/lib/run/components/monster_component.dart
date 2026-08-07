import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'player_component.dart';

class MonsterComponent extends RectangleComponent {
  MonsterComponent({
    required this.target,
    required Vector2 position,
    required this.maxHp,
    required this.touchDamage,
    required this.baseXp,
    required this.jobXp,
    required this.gold,
    this.moveSpeed = 58,
  }) : currentHp = maxHp,
       super(
         position: position,
         size: Vector2(40, 44),
         paint: Paint()..color = Colors.deepOrangeAccent,
       );

  final PlayerComponent target;
  final int maxHp;
  final int touchDamage;
  final int baseXp;
  final int jobXp;
  final int gold;
  final double moveSpeed;

  int currentHp;

  bool get isAlive => currentHp > 0;

  Rect get bounds => Rect.fromLTWH(position.x, position.y, size.x, size.y);

  void takeDamage(int amount) {
    if (amount <= 0 || !isAlive) {
      return;
    }
    currentHp = (currentHp - amount).clamp(0, maxHp).toInt();
    paint.color = currentHp > 0 ? Colors.orangeAccent : Colors.grey;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isAlive) {
      return;
    }

    final distanceToTarget = target.position.x - position.x;
    if (distanceToTarget.abs() < 900 && distanceToTarget.abs() > 42) {
      position.x += distanceToTarget.sign * moveSpeed * dt;
    }
  }
}
