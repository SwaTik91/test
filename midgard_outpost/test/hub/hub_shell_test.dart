import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/app.dart';
import 'package:midgard_outpost/hub/game_controller.dart';
import 'package:midgard_outpost/hub/hub_shell.dart';
import 'package:midgard_outpost/hub/hub_theme.dart';
import 'package:midgard_outpost/hub/run_screen.dart';
import 'package:midgard_outpost/save/cloud_save_port.dart';
import 'package:midgard_outpost/save/local_save_repository.dart';
import 'package:midgard_outpost/save/save_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('hub shell living stage + dark side dock', (tester) async {
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

    // Rail labels + primary CTA
    expect(find.text('Главная'), findsOneWidget);
    expect(find.text('Статы'), findsOneWidget);
    expect(find.text('Умения'), findsOneWidget);
    expect(find.text('Магазин'), findsOneWidget);
    expect(find.text('В поля'), findsOneWidget);

    // Stage resource chips (gold + crystals)
    expect(find.byType(HubResourceChip), findsNWidgets(2));

    // Living stage / dock split is locked at 58:42
    final hubRow = tester.widget<Row>(
      find.descendant(
        of: find.byType(HubShell),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Row &&
              widget.children.length == 2 &&
              widget.children.every((child) => child is Expanded),
        ),
      ),
    );
    final stagePane = hubRow.children[0] as Expanded;
    final dockPane = hubRow.children[1] as Expanded;
    expect(stagePane.flex, 58);
    expect(dockPane.flex, 42);

    // Rail width uses locked token (72dp)
    final railSizer = tester.widget<SizedBox>(
      find.descendant(
        of: find.byType(HubShell),
        matching: find.byWidgetPredicate(
          (widget) => widget is SizedBox && widget.width == HubTheme.railWidth,
        ),
      ),
    );
    expect(railSizer.width, HubTheme.railWidth);
    expect(HubTheme.railWidth, 72);

    // Stage subtree must not host a full-bleed content overlay
    final stageSubtree = find.descendant(
      of: find.byType(HubShell),
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

    // Tab body lives in dock — skills content not duplicated on stage overlay
    await tester.tap(find.text('Умения'));
    await tester.pumpAndSettle();
    expect(find.text('Двойная стрела'), findsOneWidget);

    // CTA uses accent fill at 56dp
    final cta = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'В поля'));
    final ctaStyle = cta.style!;
    expect(ctaStyle.backgroundColor?.resolve({}), HubTheme.accent);
    expect(ctaStyle.minimumSize?.resolve({})?.height, HubTheme.ctaHeight);

    // No cream content panel covering the stage
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

    await tester.tap(find.text('В поля'));
    await tester.pumpAndSettle();

    expect(find.byType(RunScreen), findsOneWidget);
  });

  testWidgets('hub rail keeps all labels visible on short landscape', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = GameController(
      save: SaveService(
        local: LocalSaveRepository(),
        cloud: NoopCloudSavePort(),
      ),
    );
    await controller.bootstrap();

    await tester.binding.setSurfaceSize(const Size(1280, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MidgardApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Лучник'));
    await tester.tap(find.text('Создать героя'));
    await tester.pumpAndSettle();

    const railLabels = ['Главная', 'Статы', 'Умения', 'Магазин'];
    const tabLabels = ['Главная', 'Статы', 'Умения', 'Магазин'];

    for (final tab in tabLabels) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final label in railLabels) {
        expect(find.text(label), findsOneWidget);
      }
    }
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
