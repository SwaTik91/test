import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/art/animation_atlas.dart';

void main() {
  test('all animation frame assets load from bundle', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final path in AnimationAtlas.allFramePaths) {
      final data = await rootBundle.load('${AnimationAtlas.assetRoot}$path');
      expect(data.lengthInBytes, greaterThan(0), reason: path);
    }
  });
}
