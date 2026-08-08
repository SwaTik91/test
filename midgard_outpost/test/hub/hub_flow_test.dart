import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/app.dart';
import 'package:midgard_outpost/core/ids.dart';
import 'package:midgard_outpost/hub/create_hero_screen.dart';
import 'package:midgard_outpost/hub/game_controller.dart';
import 'package:midgard_outpost/hub/hub_theme.dart';
import 'package:midgard_outpost/progress/progress_service.dart';
import 'package:midgard_outpost/run/run_rewards.dart';
import 'package:midgard_outpost/save/cloud_save_port.dart';
import 'package:midgard_outpost/save/local_save_repository.dart';
import 'package:midgard_outpost/save/save_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('create hero uses living stage + dark dock layout', (tester) async {
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

    expect(find.text('Выберите класс'), findsOneWidget);
    expect(find.text('Мидгард: Аванпост'), findsOneWidget);

    // Stage / dock split locked at 58:42
    final createRow = tester.widget<Row>(
      find.descendant(
        of: find.byType(CreateHeroScreen),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Row &&
              widget.children.length == 2 &&
              widget.children.every((child) => child is Expanded),
        ),
      ),
    );
    final stagePane = createRow.children[0] as Expanded;
    final dockPane = createRow.children[1] as Expanded;
    expect(stagePane.flex, 58);
    expect(dockPane.flex, 42);

    // Stage must not host a full-bleed content overlay
    final stageSubtree = find.descendant(
      of: find.byType(CreateHeroScreen),
      matching: find.byWidgetPredicate(
        (widget) => widget is Expanded && widget.flex == 58,
      ),
    );
    final fillOverlays = tester
        .widgetList<Positioned>(
          find.descendant(of: stageSubtree, matching: find.byType(Positioned)),
        )
        .where(_isPositionedFillStyle)
        .toList();
    expect(fillOverlays, isEmpty);

    // CTA uses accent fill
    final cta = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Создать героя'),
    );
    expect(cta.style!.backgroundColor?.resolve({}), HubTheme.accent);

    // No cream panels
    final creamDecorations = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .where((box) {
          final decoration = box.decoration;
          if (decoration is BoxDecoration && decoration.color != null) {
            return decoration.color == const Color(0xFFFFF8E7) ||
                decoration.color == const Color(0xFFF5E6C8);
          }
          return false;
        });
    expect(creamDecorations, isEmpty);
  });

  testWidgets('create archer and see hub actions', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = GameController(
      save: SaveService(
        local: LocalSaveRepository(),
        cloud: NoopCloudSavePort(),
      ),
    );
    await controller.bootstrap();
    await tester.pumpWidget(MidgardApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Выберите класс'), findsOneWidget);
    await tester.tap(find.text('Лучник'));
    await tester.tap(find.text('Создать героя'));
    await tester.pumpAndSettle();

    expect(find.text('В поля'), findsOneWidget);
    expect(find.text('Статы'), findsOneWidget);
    expect(find.text('Умения'), findsOneWidget);
    expect(find.text('Магазин'), findsOneWidget);
  });

  testWidgets('stats screen updates after allocating stat point', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = GameController(
      save: SaveService(
        local: LocalSaveRepository(),
        cloud: NoopCloudSavePort(),
      ),
    );
    await controller.bootstrap();
    await tester.pumpWidget(MidgardApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Лучник'));
    await tester.tap(find.text('Создать героя'));
    await tester.pumpAndSettle();

    await controller.onRunFinished(
      RunRewards(
        baseXp: ProgressService.xpToNextBase(1),
        jobXp: 0,
        gold: 0,
      ),
    );
    await tester.pumpAndSettle();

    expect(controller.hero!.unspentStatPoints, 1);

    await tester.tap(find.text('Статы'));
    await tester.pumpAndSettle();

    expect(find.text('Очков статов: 1'), findsOneWidget);
    expect(find.text('STR'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();

    expect(find.text('Очков статов: 1'), findsNothing);
    expect(find.byIcon(Icons.add), findsNothing);
    expect(controller.hero!.unspentStatPoints, 0);
    expect(controller.hero!.stats[StatId.str], 2);
  });
}

bool _isPositionedFillStyle(Positioned positioned) {
  return positioned.left == 0.0 &&
      positioned.top == 0.0 &&
      positioned.right == 0.0 &&
      positioned.bottom == 0.0 &&
      positioned.width == null &&
      positioned.height == null;
}
