import 'package:flutter/material.dart';

import '../content/classes.dart';
import 'game_controller.dart';

class HubHomeTab extends StatelessWidget {
  const HubHomeTab({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final hero = controller.hero!;
        final className = ClassesCatalog.byId(hero.classId).name;
        final theme = Theme.of(context);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.white),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  className,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Базовый уровень: ${hero.baseLevel}'),
                Text('Проф. уровень: ${hero.jobLevel}'),
                Text('Золото: ${hero.gold}'),
                Text('Кристаллы: ${hero.crystals}'),
              ],
            ),
          ),
        );
      },
    );
  }
}
