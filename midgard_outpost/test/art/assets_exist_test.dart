import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/art/art_atlas.dart';

void main() {
  test('all atlas images load from assets', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final path in ArtAtlas.allPaths) {
      final data = await rootBundle.load('${ArtAtlas.assetRoot}$path');
      expect(data.lengthInBytes, greaterThan(0), reason: path);
    }
  });

  test('jump button corners are transparent, not a gray plate', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final data = await rootBundle.load(ArtAtlas.flutterAsset(ArtAtlas.btnJump));
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    expect(bytes, isNotNull);

    final width = image.width;
    int alphaAt(int x, int y) => bytes!.getUint8((y * width + x) * 4 + 3);

    var cornerTransparent = 0;
    for (var y = 0; y < 16; y++) {
      for (var x = 0; x < 16; x++) {
        if (alphaAt(x, y) < 16) {
          cornerTransparent++;
        }
      }
    }
    expect(
      cornerTransparent,
      greaterThan(200),
      reason: 'top-left 16x16 should be cut out, not an opaque gray square',
    );
  });
}
