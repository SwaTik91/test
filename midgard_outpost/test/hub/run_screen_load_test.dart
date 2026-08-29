
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/app.dart';
import 'package:midgard_outpost/core/ids.dart';
import 'package:midgard_outpost/hub/game_controller.dart';
import 'package:midgard_outpost/hub/run_screen.dart';
import 'package:midgard_outpost/run/components/hud_overlay.dart';
import 'package:midgard_outpost/run/midgard_run_game.dart';
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
}
