import 'package:flame/components.dart';

class ProjectileComponent extends SpriteComponent {
  ProjectileComponent({
    required Sprite sprite,
    required Vector2 start,
    required Vector2 end,
    required this.duration,
    this.radiusSize = 6,
  }) : _start = start.clone(),
       _end = end.clone(),
       _elapsed = 0,
       super(
         sprite: sprite,
         position: start,
         size: Vector2.all(radiusSize * 2),
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
