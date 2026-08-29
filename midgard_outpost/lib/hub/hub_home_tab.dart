import 'package:flutter/material.dart';

import '../content/classes.dart';
import 'game_controller.dart';
import 'hub_theme.dart';

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
        final theme = Theme.of(context).textTheme;

        return HubTabBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HubCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      className,
                      style: HubTheme.cardTitleStyle(theme).copyWith(
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _HomeRow(
                      label: 'Базовый уровень',
                      value: '${hero.baseLevel}',
                      theme: theme,
                    ),
                    _HomeRow(
                      label: 'Проф. уровень',
                      value: '${hero.jobLevel}',
                      theme: theme,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              HubCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HomeRow(
                      label: 'Золото',
                      value: '${hero.gold}',
                      theme: theme,
                    ),
                    const SizedBox(height: 4),
                    _HomeRow(
                      label: 'Кристаллы',
                      value: '${hero.crystals}',
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeRow extends StatelessWidget {
  const _HomeRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  final String label;
  final String value;
  final TextTheme theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: HubTheme.cardSubtitleStyle(theme)),
        ),
        Text(value, style: HubTheme.cardTitleStyle(theme)),
      ],
    );
  }
}
