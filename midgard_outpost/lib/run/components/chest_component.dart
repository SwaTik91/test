import 'dart:ui';

import 'package:flame/components.dart';

class ChestComponent extends SpriteComponent {
  ChestComponent({required Sprite sprite, required Vector2 position})
    : super(
        sprite: sprite,
        position: position,
        size: Vector2(42, 34),
      );

  bool isCollected = false;

  Rect get bounds => Rect.fromLTWH(position.x, position.y, size.x, size.y);

  void collect() {
    if (isCollected) {
      return;
    }
    isCollected = true;
    removeFromParent();
  }
}
