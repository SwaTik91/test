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
          child: ListView(
            children: [
              Text(
                className,
                style: HubTheme.pointsHeaderStyle(theme),
              ),
              const SizedBox(height: 8),
              HubCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    _HomeRow(
                      label: 'Базовый уровень',
                      value: '${hero.baseLevel}',
                      theme: theme,
                    ),
                    const SizedBox(height: 4),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    _HomeRow(
                      label: 'Золото',
                      value: '${hero.gold}',
                      theme: theme,
                      valueColor: HubTheme.gold,
                    ),
                    const SizedBox(height: 4),
                    _HomeRow(
                      label: 'Кристаллы',
                      value: '${hero.crystals}',
                      theme: theme,
                      valueColor: HubTheme.crystal,
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
    this.valueColor,
  });

  final String label;
  final String value;
  final TextTheme theme;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: HubTheme.cardSubtitleStyle(theme)),
        ),
        Text(
          value,
          style: HubTheme.cardTitleStyle(theme).copyWith(color: valueColor),
        ),
      ],
    );
  }
}
