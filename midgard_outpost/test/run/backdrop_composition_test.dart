import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/core/ids.dart';
import 'package:midgard_outpost/progress/hero_progress.dart';
import 'package:midgard_outpost/run/midgard_run_game.dart';
import 'package:midgard_outpost/run/run_layout.dart';
import 'package:midgard_outpost/run/run_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWithGame(
    'backdrop fills viewport at 500px height',
    _createGame,
    (game) => _expectComposition(game, 1280, 500),
  );

  testWithGame(
    'backdrop fills viewport at 800px height',
    _createGame,
    (game) => _expectComposition(game, 1280, 800),
  );

  testWithGame(
    'backdrop fills viewport on narrow landscape at 800px height',
    _createGame,
    (game) => _expectComposition(game, 414, 800),
  );

  testWithGame(
    'left edge covered at 500px height',
    _createGame,
    (game) => _expectLeftEdgeCoverage(game, 1280, 500),
  );

  testWithGame(
    'left edge covered at 800px height',
    _createGame,
    (game) => _expectLeftEdgeCoverage(game, 1280, 800),
  );

  testWithGame(
    'ground reaches viewport bottom at 500px landscape height',
    _createGame,
    (game) => _expectGroundBottomCoverage(game, 1280, 500),
  );

  testWithGame(
    'ground reaches viewport bottom at 800px landscape height',
    _createGame,
    (game) => _expectGroundBottomCoverage(game, 1280, 800),
  );
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

Future<void> _expectComposition(
  MidgardRunGame game,
  double width,
  double height,
) async {
  game.onGameResize(Vector2(width, height));
  game.update(0);

  expect(game.isRunReady, isTrue, reason: 'stage=${game.loadStage}');

  final layout = RunLayout(height);
  final backdrop = game.biomeBackgroundForTest;
  expect(backdrop, isNotNull);

  final groundViewport = game.camera.viewfinder.globalToLocal(
    Vector2(game.player.position.x, layout.groundY),
  );

  expect(backdrop!.anchor, Anchor.bottomLeft);
  expect(backdrop.position.x, closeTo(-RunLayout.backdropBleedPx, 0.01));
  expect(backdrop.position.y, closeTo(height, 0.01));
  expect(backdrop.size.y, greaterThanOrEqualTo(height));
  expect(backdrop.position.y - backdrop.size.y, lessThanOrEqualTo(0));
  expect(game.backdropCoversViewport(viewportWidth: width, viewportHeight: height), isTrue);
  expect(groundViewport.y, closeTo(layout.groundY, 0.5));
}

Future<void> _expectLeftEdgeCoverage(
  MidgardRunGame game,
  double width,
  double height,
) async {
  game.onGameResize(Vector2(width, height));
  game.update(0);

  expect(game.isRunReady, isTrue, reason: 'stage=${game.loadStage}');
  expect(game.leftEdgeCoveredAtStart(viewportWidth: width, viewportHeight: height), isTrue);

  final visible = game.camera.visibleWorldRect;
  final minX = game.groundTilesForTest
      .map((tile) => tile.position.x)
      .reduce((a, b) => a < b ? a : b);
  expect(minX, lessThanOrEqualTo(visible.left));

  game.player.position.x -= 180;
  for (var i = 0; i < 10; i++) {
    game.update(1 / 60);
  }
  expect(game.groundCoversVisibleSpan(viewportWidth: width), isTrue);
  expect(game.backdropCoversViewport(viewportWidth: width, viewportHeight: height), isTrue);
}

Future<void> _expectGroundBottomCoverage(
  MidgardRunGame game,
  double width,
  double height,
) async {
  game.onGameResize(Vector2(width, height));
  game.update(0);

  expect(game.isRunReady, isTrue, reason: 'stage=${game.loadStage}');
  expect(game.groundTilesForTest, isNotEmpty);
  expect(
    game.groundCoversViewportBottom(viewportHeight: height),
    isTrue,
    reason: 'ground strip must cover contact line to viewport bottom',
  );

  final layout = RunLayout(height);
  final maxBottom = game.groundTilesForTest
      .map((tile) => tile.position.y + tile.size.y)
      .reduce((a, b) => a > b ? a : b);
  expect(maxBottom, greaterThanOrEqualTo(layout.groundY + layout.groundStripHeight));
  expect(
    maxBottom,
    greaterThanOrEqualTo(game.camera.visibleWorldRect.bottom - 0.5),
  );
}
