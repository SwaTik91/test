import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/run/sprite_fit.dart';

void main() {
  group('SpriteFit', () {
    test('containHeight preserves aspect ratio', () {
      final size = SpriteFit.containHeight(
        srcSize: Vector2(75, 96),
        targetHeight: 216,
      );
      expect(size.y, 216);
      expect(size.x, closeTo(216 * (75 / 96), 0.01));
    });

    test('containSquare fits inside target extent', () {
      final size = SpriteFit.containSquare(
        srcSize: Vector2(64, 28),
        targetExtent: 24,
      );
      expect(size.x, lessThanOrEqualTo(24));
      expect(size.y, lessThanOrEqualTo(24));
      expect(size.x / size.y, closeTo(64 / 28, 0.01));
    });
  });
}
