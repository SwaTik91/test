import 'package:flame/components.dart';

import '../sprite_fit.dart';

class ProjectileComponent extends SpriteComponent {
  ProjectileComponent({
    required Sprite sprite,
    required Vector2 start,
    required Vector2 end,
    required this.duration,
    double visualHeight = 24,
  }) : _start = start.clone(),
       _end = end.clone(),
       _elapsed = 0,
       super(
         sprite: sprite,
         position: start,
         size: SpriteFit.containHeight(
           srcSize: sprite.srcSize,
           targetHeight: visualHeight,
         ),
         anchor: Anchor.center,
       );

  static const double basicVisualHeight = 24;
  static const double skillVisualHeight = 28;
  static const double ultimateVisualHeight = 34;

  final Vector2 _start;
  final Vector2 _end;
  final double duration;
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
