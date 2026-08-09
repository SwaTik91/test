import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:midgard_outpost/art/animation_atlas.dart';
import 'package:midgard_outpost/run/components/chest_component.dart';

void main() {
  test('chest open animation loads five frames from atlas', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final openAnim = await AnimationAtlas.load(
      AnimationAtlas.chestOpenFrames,
      AnimationAtlas.chestOpenStepTime,
      loop: false,
    );
    expect(openAnim.frames, hasLength(5));
  });

  test('chest create loads five-frame open animation', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final chest = await ChestComponent.create(
      position: Vector2(100, 200),
      size: Vector2(64, 64),
    );

    final openAnim = chest.animations![ChestAnimName.open]!;
    expect(openAnim.frames, hasLength(5));
    expect(chest.animations![ChestAnimName.closed]!.frames, hasLength(1));
  });
}
