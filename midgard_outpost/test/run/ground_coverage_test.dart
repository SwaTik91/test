import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/core/ids.dart';
import 'package:midgard_outpost/progress/hero_progress.dart';
import 'package:midgard_outpost/run/midgard_run_game.dart';
import 'package:midgard_outpost/run/run_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in [
    (width: 1280.0, height: 500.0),
    (width: 1280.0, height: 800.0),
    (width: 414.0, height: 800.0),
  ]) {
    testWithGame(
      'ground covers visible span at ${size.width.toInt()}x${size.height.toInt()}',
      _createGame,
      (game) => _expectInitialGroundCoverage(game, size.width, size.height),
    );

    testWithGame(
      'ground stays contiguous after scroll at ${size.width.toInt()}x${size.height.toInt()}',
      _createGame,
      (game) => _expectGroundCoverageAfterScroll(game, size.width, size.height),
    );
  }
}

MidgardRunGame _createGame() {
  final game = MidgardRunGame(
    hero: HeroProgress.createNew(HeroClassId.archer),
    onDeath: (_) {},
    initialRunState: RunState.initial(),
  );
  game.overlays.addEntry(
    MidgardRunGame.hudOverlayKey,
    (_, _) => const SizedBox.shrink(),
  );
  game.overlays.addEntry(
    MidgardRunGame.upgradePickerOverlayKey,
    (_, _) => const SizedBox.shrink(),
  );
  return game;
}

Future<void> _expectInitialGroundCoverage(
  MidgardRunGame game,
  double width,
  double height,
) async {
  game.onGameResize(Vector2(width, height));
  game.update(0);

  expect(game.isRunReady, isTrue, reason: 'stage=${game.loadStage}');
  expect(game.groundTilesForTest, isNotEmpty);
  expect(game.leftEdgeCoveredAtStart(viewportWidth: width, viewportHeight: height), isTrue);
  expect(game.groundCoversVisibleSpan(viewportWidth: width), isTrue);
  expect(game.groundTilesAreContiguous(), isTrue);

  final tiles = game.groundTilesForTest;
  final minX = tiles.map((tile) => tile.position.x).reduce((a, b) => a < b ? a : b);
  expect(minX, lessThan(0), reason: 'left edge should extend past world origin');
}

Future<void> _expectGroundCoverageAfterScroll(
  MidgardRunGame game,
  double width,
  double height,
) async {
  game.onGameResize(Vector2(width, height));
  game.update(0);

  expect(game.isRunReady, isTrue);

  game.player.position.x += 2400;
  for (var i = 0; i < 30; i++) {
    game.update(1 / 60);
  }

  expect(game.groundCoversVisibleSpan(viewportWidth: width), isTrue);
  expect(game.groundTilesAreContiguous(), isTrue);
}
