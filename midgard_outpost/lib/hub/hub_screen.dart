import 'package:flutter/material.dart';

import '../content/classes.dart';
import 'game_controller.dart';
import 'run_screen.dart';
import 'shop_screen.dart';
import 'skills_screen.dart';
import 'stats_screen.dart';

class HubScreen extends StatelessWidget {
  const HubScreen({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final hero = controller.hero!;
    final className = ClassesCatalog.byId(hero.classId).name;

    return Scaffold(
      appBar: AppBar(title: const Text('Мидгард: Аванпост')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(className, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Базовый уровень: ${hero.baseLevel}'),
            Text('Проф. уровень: ${hero.jobLevel}'),
            Text('Золото: ${hero.gold}'),
            Text('Кристаллы: ${hero.crystals}'),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: () =>
                      _open(context, StatsScreen(controller: controller)),
                  child: const Text('Статы'),
                ),
                FilledButton(
                  onPressed: () =>
                      _open(context, SkillsScreen(controller: controller)),
                  child: const Text('Умения'),
                ),
                FilledButton(
                  onPressed: () =>
                      _open(context, ShopScreen(controller: controller)),
                  child: const Text('Магазин'),
                ),
                FilledButton(
                  onPressed: () =>
                      _open(context, RunScreen(controller: controller)),
                  child: const Text('В поля'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}
