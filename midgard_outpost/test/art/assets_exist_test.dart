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
}
