import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/core/ids.dart';
import 'package:midgard_outpost/hub/game_controller.dart';
import 'package:midgard_outpost/hub/shop_screen.dart';
import 'package:midgard_outpost/save/cloud_save_port.dart';
import 'package:midgard_outpost/save/local_save_repository.dart';
import 'package:midgard_outpost/save/save_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('debug level button grants +10 base and job levels', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = GameController(
      save: SaveService(
        local: LocalSaveRepository(),
        cloud: NoopCloudSavePort(),
      ),
    );
    await controller.bootstrap();
    await controller.createHero(HeroClassId.archer);
    expect(controller.hero!.baseLevel, 1);
    expect(controller.hero!.jobLevel, 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShopScreen(controller: controller, embedded: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Тест: +10 уровней'), findsOneWidget);
    await tester.tap(find.text('+10 / +10'));
    await tester.pumpAndSettle();

    expect(controller.hero!.baseLevel, 11);
    expect(controller.hero!.jobLevel, 11);
    expect(controller.hero!.unspentStatPoints, 10);
    expect(controller.hero!.unspentSkillPoints, 10);
    expect(find.textContaining('Тест: база 11'), findsOneWidget);
  });
}
