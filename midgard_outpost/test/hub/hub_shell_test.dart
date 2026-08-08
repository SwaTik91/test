import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/app.dart';
import 'package:midgard_outpost/hub/game_controller.dart';
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
}
