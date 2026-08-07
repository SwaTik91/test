import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/core/ids.dart';
import 'package:midgard_outpost/hub/game_controller.dart';
import 'package:midgard_outpost/hub/run_summary_screen.dart';
import 'package:midgard_outpost/run/run_rewards.dart';
import 'package:midgard_outpost/save/cloud_save_port.dart';
import 'package:midgard_outpost/save/local_save_repository.dart';
import 'package:midgard_outpost/save/save_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<GameController> createController() async {
    SharedPreferences.setMockInitialValues({});
    final controller = GameController(
      save: SaveService(
        local: LocalSaveRepository(),
        cloud: NoopCloudSavePort(),
      ),
    );
    await controller.bootstrap();
    await controller.createHero(HeroClassId.archer);
    return controller;
  }

  Future<void> openSummary(
    WidgetTester tester,
    GameController controller,
    RunRewards rewards,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RunSummaryScreen(
                      rewards: rewards,
                      onContinue: () => controller.onRunFinished(rewards),
                    ),
                  ),
                );
              },
              child: const Text('Открыть'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();
  }

  testWidgets('system back applies rewards before leaving', (tester) async {
    final controller = await createController();
    const rewards = RunRewards(baseXp: 10, jobXp: 5, gold: 100);
    final initialGold = controller.hero!.gold;

    await openSummary(tester, controller, rewards);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Итоги забега'), findsNothing);
    expect(find.text('Открыть'), findsOneWidget);
    expect(controller.hero!.gold, initialGold + rewards.gold);
  });

  testWidgets('continue applies rewards once and returns to hub', (tester) async {
    final controller = await createController();
    const rewards = RunRewards(baseXp: 10, jobXp: 5, gold: 100);
    final initialGold = controller.hero!.gold;
    final initialBaseXp = controller.hero!.baseXp;

    await openSummary(tester, controller, rewards);

    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();

    expect(find.text('Итоги забега'), findsNothing);
    expect(find.text('Открыть'), findsOneWidget);
    expect(controller.hero!.gold, initialGold + rewards.gold);
    expect(controller.hero!.baseXp, initialBaseXp + rewards.baseXp);
  });

  testWidgets('app bar back applies rewards before leaving', (tester) async {
    final controller = await createController();
    const rewards = RunRewards(baseXp: 3, jobXp: 0, gold: 50);
    final initialGold = controller.hero!.gold;

    await openSummary(tester, controller, rewards);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Итоги забега'), findsNothing);
    expect(controller.hero!.gold, initialGold + rewards.gold);
  });

  testWidgets('double continue does not apply rewards twice', (tester) async {
    final controller = await createController();
    const rewards = RunRewards(baseXp: 10, jobXp: 0, gold: 100);
    final initialGold = controller.hero!.gold;
    var applyCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RunSummaryScreen(
                      rewards: rewards,
                      onContinue: () async {
                        applyCount++;
                        await controller.onRunFinished(rewards);
                      },
                    ),
                  ),
                );
              },
              child: const Text('Открыть'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();

    final continueButton = find.text('Продолжить');
    await tester.tap(continueButton);
    await tester.tap(continueButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(applyCount, 1);
    expect(controller.hero!.gold, initialGold + rewards.gold);
  });
}
