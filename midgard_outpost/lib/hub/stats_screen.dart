import 'package:flutter/material.dart';

import '../core/ids.dart';
import 'game_controller.dart';

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

        final body = ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (canAllocate) Text('Очков статов: ${hero.unspentStatPoints}'),
            ...StatId.values.map((stat) {
              final value = hero.stats[stat] ?? 1;
              return ListTile(
                title: Text(_statLabels[stat]!),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$value'),
                    if (canAllocate)
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => controller.allocateStat(stat),
                      ),
                  ],
                ),
              );
            }),
          ],
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
