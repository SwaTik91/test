import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Directory _repoRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 6; i++) {
    final store = Directory('${dir.path}/store');
    if (store.existsSync()) return dir;
    dir = dir.parent;
  }
  return Directory.current.parent; // midgard_outpost/ → repo root
}

void main() {
  final root = _repoRoot();

  test('store listing markdown files exist', () {
    for (final rel in [
      'store/README.md',
      'store/listing.ru.md',
      'store/checklist-appgallery.md',
      'store/checklist-rustore.md',
    ]) {
      final f = File('${root.path}/$rel');
      expect(f.existsSync(), isTrue, reason: rel);
      expect(f.readAsStringSync().trim().isNotEmpty, isTrue, reason: rel);
    }
  });

  test('store icon master is 512x512 PNG', () async {
    final f = File('${root.path}/store/icons/ic_launcher_512.png');
    expect(f.existsSync(), isTrue);
    final bytes = f.readAsBytesSync();
    expect(bytes.length, greaterThan(1000));
    // PNG IHDR width/height at bytes 16..23 big-endian
    expect(bytes[0], 0x89);
    final w = (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
    final h = (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
    expect(w, 512);
    expect(h, 512);
  });

  test('android mipmap launchers exist', () {
    for (final dens in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
      final f = File(
        '${root.path}/midgard_outpost/android/app/src/main/res/mipmap-$dens/ic_launcher.png',
      );
      expect(f.existsSync(), isTrue, reason: dens);
    }
  });

  test('store screenshots are 1920x1080 and at least four', () {
    final dir = Directory('${root.path}/store/screenshots');
    expect(dir.existsSync(), isTrue);
    final pngs = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.png'))
        .toList();
    expect(pngs.length, greaterThanOrEqualTo(4));
    for (final f in pngs) {
      final bytes = f.readAsBytesSync();
      final w = (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
      final h = (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
      expect(w, 1920, reason: f.path);
      expect(h, 1080, reason: f.path);
    }
  });
}
