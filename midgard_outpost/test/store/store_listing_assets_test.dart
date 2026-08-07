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
}
