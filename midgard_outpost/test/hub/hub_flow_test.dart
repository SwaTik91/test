import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/app.dart';
import 'package:midgard_outpost/hub/game_controller.dart';
import 'package:midgard_outpost/save/cloud_save_port.dart';
import 'package:midgard_outpost/save/local_save_repository.dart';
import 'package:midgard_outpost/save/save_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
}
