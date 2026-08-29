import 'dart:ui';

import 'package:flame/components.dart';

/// Dark hole cut into the dirt strip. Sits above ground tiles, under actors.
class PitComponent extends PositionComponent {
  PitComponent({
    required double startX,
    required double groundY,
    required double width,
    required double depth,
  }) : super(
         position: Vector2(startX, groundY),
         size: Vector2(width, depth),
         anchor: Anchor.topLeft,
         priority: -1,
       );

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final hole = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(6),
    );
    canvas.drawRRect(hole, Paint()..color = const Color(0xFF140E0A));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6, 8, w - 12, h - 10),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF070504),
    );

    final lip = Paint()..color = const Color(0xFF4A311C);
    canvas.drawRect(Rect.fromLTWH(0, 0, 7, h), lip);
    canvas.drawRect(Rect.fromLTWH(w - 7, 0, 7, h), lip);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, 5),
      Paint()..color = const Color(0xFF3D6B28),
    );
  }
}
