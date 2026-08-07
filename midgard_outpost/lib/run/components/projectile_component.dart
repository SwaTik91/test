import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ProjectileComponent extends CircleComponent {
  ProjectileComponent({
    required Vector2 start,
    required Vector2 end,
    required this.duration,
    required Color color,
    this.radiusSize = 6,
  }) : _start = start.clone(),
       _end = end.clone(),
       _elapsed = 0,
       super(
         position: start,
         radius: radiusSize,
         paint: Paint()..color = color,
         anchor: Anchor.center,
       );

  final Vector2 _start;
  final Vector2 _end;
  final double duration;
  final double radiusSize;
  double _elapsed;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    final t = (_elapsed / duration).clamp(0, 1).toDouble();
    position
      ..x = _start.x + ((_end.x - _start.x) * t)
      ..y = _start.y + ((_end.y - _start.y) * t);

    if (_elapsed >= duration) {
      removeFromParent();
    }
  }
}
