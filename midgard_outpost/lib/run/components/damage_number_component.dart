import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Ragnarok-style floating damage digits.
class DamageNumberComponent extends PositionComponent {
  DamageNumberComponent({
    required int amount,
    required Vector2 position,
    this.isCrit = false,
  }) : _amount = amount,
       _life = isCrit ? 0.85 : 0.7,
       super(
         position: position.clone(),
         size: Vector2(96, 40),
         anchor: Anchor.center,
         priority: 1000,
       );

  final int _amount;
  final bool isCrit;
  final double _life;
  double _elapsed = 0;
  late final double _driftX;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _driftX = (hashCode % 17 - 8).toDouble();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    position
      ..x += _driftX * dt * 8
      ..y -= (isCrit ? 70 : 55) * dt;
    if (_elapsed >= _life) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_elapsed / _life).clamp(0.0, 1.0);
    final opacity = t < 0.55 ? 1.0 : (1 - ((t - 0.55) / 0.45)).clamp(0.0, 1.0);
    final color = (isCrit ? const Color(0xFFFF3B30) : const Color(0xFFFFE566))
        .withValues(alpha: opacity);
    final painter = TextPainter(
      text: TextSpan(
        text: '$_amount',
        style: TextStyle(
          color: color,
          fontSize: isCrit ? 28 : 22,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
          shadows: [
            Shadow(
              color: const Color(0xFF000000).withValues(alpha: opacity),
              offset: const Offset(1.5, 1.5),
            ),
            Shadow(
              color: const Color(0xFF000000).withValues(alpha: opacity),
              offset: const Offset(-1, 0),
            ),
            Shadow(
              color: const Color(0xFF000000).withValues(alpha: opacity),
              offset: const Offset(1, 0),
            ),
            Shadow(
              color: const Color(0xFF000000).withValues(alpha: opacity),
              offset: const Offset(0, -1),
            ),
            Shadow(
              color: const Color(0xFF000000).withValues(alpha: opacity),
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
  }
}
