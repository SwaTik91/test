import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/art/hero_anim_state.dart';

void main() {
  group('selectHeroAnim', () {
    test('returns jump when not grounded', () {
      expect(
        selectHeroAnim(grounded: false, vx: 0, casting: false),
        HeroAnimName.jump,
      );
      expect(
        selectHeroAnim(grounded: false, vx: 200, casting: false),
        HeroAnimName.jump,
      );
    });

    test('returns cast when casting takes priority over movement', () {
      expect(
        selectHeroAnim(grounded: true, vx: 200, casting: true),
        HeroAnimName.cast,
      );
      expect(
        selectHeroAnim(grounded: false, vx: 0, casting: true),
        HeroAnimName.cast,
      );
    });

    test('returns run when grounded and moving horizontally', () {
      expect(
        selectHeroAnim(grounded: true, vx: 150, casting: false),
        HeroAnimName.run,
      );
      expect(
        selectHeroAnim(grounded: true, vx: -80, casting: false),
        HeroAnimName.run,
      );
    });

    test('returns idle when grounded with no horizontal movement', () {
      expect(
        selectHeroAnim(grounded: true, vx: 0, casting: false),
        HeroAnimName.idle,
      );
    });
  });
}
