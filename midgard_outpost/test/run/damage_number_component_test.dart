import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/run/components/damage_number_component.dart';

void main() {
  testWithFlameGame('damage number floats upward over its lifetime', (game) async {
    final number = DamageNumberComponent(
      amount: 42,
      position: Vector2(100, 200),
    );
    await game.ensureAdd(number);

    final startY = number.position.y;
    game.update(0.25);
    expect(number.position.y, lessThan(startY));
    expect(number.isMounted, isTrue);

    // Lifetime is 0.7s — after that the component schedules removal.
    game.update(0.6);
    expect(number.position.y, lessThan(startY - 20));
  });
}
