import 'dart:ui';

import 'package:flame/components.dart';

import '../systems/terrain_system.dart';

/// Solid rock or crate sitting on the contact line. Jump over or land on top.
class ObstacleComponent extends PositionComponent {
  ObstacleComponent({
    required this.kind,
    required double groundY,
    required TerrainFeature feature,
  }) : super(
         position: Vector2(feature.centerX, groundY),
         size: Vector2(feature.width, feature.height),
         anchor: Anchor.bottomCenter,
         priority: 1,
       );

  final TerrainKind kind;

  @override
  void render(Canvas canvas) {
    if (kind == TerrainKind.crate) {
      _renderCrate(canvas);
    } else {
      _renderRock(canvas);
    }
  }

  void _renderRock(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final path = Path()
      ..moveTo(w * 0.12, h * 0.78)
      ..lineTo(w * 0.08, h * 0.42)
      ..lineTo(w * 0.32, h * 0.08)
      ..lineTo(w * 0.68, h * 0.06)
      ..lineTo(w * 0.94, h * 0.40)
      ..lineTo(w * 0.88, h * 0.86)
      ..lineTo(w * 0.55, h)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF6B5A4A));
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF3D342C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    canvas.drawOval(
      Rect.fromLTWH(w * 0.28, h * 0.18, w * 0.28, h * 0.16),
      Paint()..color = const Color(0xFF8A7866),
    );
  }

  void _renderCrate(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, w - 2, h - 2),
      const Radius.circular(3),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFF8A5A2B));
    canvas.drawRRect(
      body,
      Paint()
        ..color = const Color(0xFF3D2410)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final plank = Paint()..color = const Color(0xFF6E431C);
    canvas.drawRect(Rect.fromLTWH(3, h * 0.28, w - 6, 3), plank);
    canvas.drawRect(Rect.fromLTWH(3, h * 0.58, w - 6, 3), plank);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.46, 4, 4, h - 8),
      Paint()..color = const Color(0xFF2C1A0C),
    );
  }
}
