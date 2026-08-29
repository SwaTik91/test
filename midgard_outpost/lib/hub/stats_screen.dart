import 'package:flutter/material.dart';

import '../core/ids.dart';
import 'game_controller.dart';
import 'hub_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({
    super.key,
    required this.controller,
    this.embedded = false,
  });

  final GameController controller;
  final bool embedded;

  static const _statLabels = {
    StatId.str: 'STR',
    StatId.agi: 'AGI',
    StatId.vit: 'VIT',
    StatId.intStat: 'INT',
    StatId.dex: 'DEX',
    StatId.luk: 'LUK',
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final hero = controller.hero!;
        final canAllocate = hero.unspentStatPoints > 0;
        final theme = Theme.of(context).textTheme;

        final body = HubTabBody(
          child: ListView(
            children: [
              if (canAllocate)
                HubPointsHeader(
                  label: 'Очков статов: ${hero.unspentStatPoints}',
                ),
              for (final stat in StatId.values) ...[
                HubCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _statLabels[stat]!,
                          style: HubTheme.cardTitleStyle(theme),
                        ),
                      ),
                      Text(
                        '${hero.stats[stat] ?? 1}',
                        style: HubTheme.cardTitleStyle(theme),
                      ),
                      if (canAllocate) ...[
                        const SizedBox(width: 8),
                        HubIncrementButton(
                          onPressed: () => controller.allocateStat(stat),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        );

        if (embedded) {
          return body;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Статы'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: body,
        );
      },
    );
  }
}
