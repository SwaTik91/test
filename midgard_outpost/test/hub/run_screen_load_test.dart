
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/app.dart';
import 'package:midgard_outpost/content/monsters.dart';
import 'package:midgard_outpost/core/ids.dart';
import 'package:midgard_outpost/hub/game_controller.dart';
import 'package:midgard_outpost/hub/run_screen.dart';
import 'package:midgard_outpost/run/components/hud_overlay.dart';
import 'package:midgard_outpost/run/components/monster_component.dart';
import 'package:midgard_outpost/run/components/projectile_component.dart';
import 'package:midgard_outpost/run/midgard_run_game.dart';
import 'package:midgard_outpost/run/run_layout.dart';
import 'package:midgard_outpost/save/cloud_save_port.dart';
import 'package:midgard_outpost/save/local_save_repository.dart';
import 'package:midgard_outpost/save/save_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'entering fields does not throw and shows HUD after load',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final controller = GameController(
        save: SaveService(
          local: LocalSaveRepository(),
          cloud: NoopCloudSavePort(),
        ),
      );
      await controller.bootstrap();

      await tester.binding.setSurfaceSize(const Size(1280, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(MidgardApp(controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Лучник'));
      await tester.tap(find.text('Создать героя'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('В поля'));
      await tester.pump();

      // Real async needed for Flame image decode inside GameWidget.onLoad.
      await tester.runAsync(() async {
        for (var i = 0; i < 100; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          final ex = tester.takeException();
          expect(ex, isNull, reason: 'exception during load: $ex');
          final games = tester.widgetList<GameWidget<MidgardRunGame>>(
            find.byType(GameWidget<MidgardRunGame>),
          );
          if (games.isEmpty) continue;
        }
      });

      // Pump frames interleaved with real async waits until HUD ready.
      Object? seen;
      for (var i = 0; i < 80; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        seen ??= tester.takeException();
        if (find.textContaining('HP ').evaluate().isNotEmpty) break;
      }

      expect(seen, isNull, reason: '$seen');
      expect(find.byType(HudOverlay), findsOneWidget);
      expect(find.textContaining('HP '), findsOneWidget);
    },
  );

  testWidgets('GameWidget reaches isRunReady', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = GameController(
      save: SaveService(
        local: LocalSaveRepository(),
        cloud: NoopCloudSavePort(),
      ),
    );
    await controller.bootstrap();
    await controller.createHero(HeroClassId.archer);

    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final game = MidgardRunGame(
      hero: controller.hero!,
      onDeath: (_) {},
      initialRunState: controller.runState,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GameWidget<MidgardRunGame>(
          game: game,
          overlayBuilderMap: {
            MidgardRunGame.hudOverlayKey: (context, g) => HudOverlay(game: g),
          },
        ),
      ),
    );

    await tester.runAsync(() async {
      for (var i = 0; i < 200 && !game.isRunReady; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(
      game.isRunReady,
      isTrue,
      reason: 'stage=${game.loadStage} err=${game.loadError}',
    );
    expect(game.loadError, isNull);
    expect(find.textContaining('HP '), findsOneWidget);
  });

  testWidgets('run level anchors camera and ground at layout groundY', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = GameController(
      save: SaveService(
        local: LocalSaveRepository(),
        cloud: NoopCloudSavePort(),
      ),
    );
    await controller.bootstrap();
    await controller.createHero(HeroClassId.archer);

    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final game = MidgardRunGame(
      hero: controller.hero!,
      onDeath: (_) {},
      initialRunState: controller.runState,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GameWidget<MidgardRunGame>(
          game: game,
          overlayBuilderMap: {
            MidgardRunGame.hudOverlayKey: (context, g) => HudOverlay(game: g),
          },
        ),
      ),
    );

    await tester.runAsync(() async {
      for (var i = 0; i < 200 && !game.isRunReady; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    await tester.pump();

    final layout = RunLayout(game.camera.viewport.virtualSize.y);
    expect(game.camera.viewfinder.anchor.y, RunLayout.groundTopFraction);
    expect(game.player.groundY, closeTo(layout.groundY, 0.01));
    expect(game.groundTilesForTest, isNotEmpty);
    for (final tile in game.groundTilesForTest) {
      expect(tile.position.y, closeTo(layout.groundY, 0.01));
    }
  });

  testWidgets('archer auto attack spawns projectile in world', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = GameController(
      save: SaveService(
        local: LocalSaveRepository(),
        cloud: NoopCloudSavePort(),
      ),
    );
    await controller.bootstrap();
    await controller.createHero(HeroClassId.archer);

    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final game = MidgardRunGame(
      hero: controller.hero!,
      onDeath: (_) {},
      initialRunState: controller.runState,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GameWidget<MidgardRunGame>(
          game: game,
          overlayBuilderMap: {
            MidgardRunGame.hudOverlayKey: (context, g) => HudOverlay(game: g),
          },
        ),
      ),
    );

    await tester.runAsync(() async {
      for (var i = 0; i < 200 && !game.isRunReady; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    await tester.pump();

    final layout = RunLayout(game.camera.viewport.virtualSize.y);
    final target = MonsterComponent.forTest(
      kind: MonsterKind.slime,
      target: game.player,
      position: Vector2(game.player.position.x + 180, layout.groundY),
      sprite: Sprite(await _onePixelImage()),
      maxHp: 999,
      touchDamage: 1,
      baseXp: 1,
      jobXp: 1,
      gold: 1,
      tempXp: 1,
      upgradeDropChance: 0,
      size: layout.mobSize(),
    );
    game.world.add(target);
    game.registerMonsterForTest(target);

    await tester.runAsync(() async {
      for (var i = 0; i < 120; i++) {
        game.update(1 / 60);
        await Future<void>.delayed(const Duration(milliseconds: 16));
        if (game.world.children.whereType<ProjectileComponent>().isNotEmpty) {
          break;
        }
      }
    });

    expect(
      game.world.children.whereType<ProjectileComponent>().length,
      greaterThan(0),
    );
  });
}

Future<ui.Image> _onePixelImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 1, 1),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  final picture = recorder.endRecording();
  return picture.toImage(1, 1);
}
