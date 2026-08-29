import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/content/skills.dart';
import 'package:midgard_outpost/core/ids.dart';
import 'package:midgard_outpost/hub/game_controller.dart';
import 'package:midgard_outpost/hub/hub_theme.dart';
import 'package:midgard_outpost/hub/skills_screen.dart';
import 'package:midgard_outpost/save/cloud_save_port.dart';
import 'package:midgard_outpost/save/local_save_repository.dart';
import 'package:midgard_outpost/save/save_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('long-press on skill icon shows name and description', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = GameController(
      save: SaveService(
        local: LocalSaveRepository(),
        cloud: NoopCloudSavePort(),
      ),
    );
    await controller.bootstrap();
    await controller.createHero(HeroClassId.archer);

    await tester.pumpWidget(
      MaterialApp(
        home: SkillsScreen(controller: controller, embedded: true),
      ),
    );
    await tester.pumpAndSettle();

    final concentrate = SkillsCatalog.byId('concentrate');
    expect(find.text(concentrate.name), findsOneWidget);
    expect(find.text(concentrate.description), findsNothing);

    final concentrateRow = find.ancestor(
      of: find.text(concentrate.name),
      matching: find.byType(HubCard),
    );
    await tester.longPress(
      find.descendant(
        of: concentrateRow,
        matching: find.byType(Image),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(concentrate.description), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Ур. 0 / 10'),
      ),
      findsOneWidget,
    );
    expect(find.text('Закрыть'), findsOneWidget);
  });
}
