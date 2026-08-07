import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ChestComponent extends RectangleComponent {
  ChestComponent({required Vector2 position})
    : super(
        position: position,
        size: Vector2(42, 34),
        paint: Paint()..color = const Color(0xFFD8A431),
      );

  bool isCollected = false;

  Rect get bounds => Rect.fromLTWH(position.x, position.y, size.x, size.y);

  void collect() {
    if (isCollected) {
      return;
    }
    isCollected = true;
    paint.color = Colors.grey;
    removeFromParent();
  }
}
